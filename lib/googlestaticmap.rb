# = googlestaticmap gem
#
# This gem is on Rubygems, simply type "gem install googlestaticmap" to install it.
#
# Available on github at http://github.com/brentsowers1/googlestaticmap
#
# Class for generating URLs for and downloading static maps from the Google Maps
# Static API service.  GoogleStaticMap is the main class to use, instantiate it,
# set the attributes to what you want, and call full_url on the instance to get
# the URL to download the map from.  You can also call get_map to actually
# download the map from Google, return the bytes, and optionally write the
# image to a file.
#
# Examples:
#
# Get a simple static map centered at Washington, DC, with the default size
# (500 x 350), zoomed to level 11
#   map = GoogleStaticMap.new(:zoom => 11, :center => MapLocation.new(:address => "Washington, DC"))
#   image = map.get_map
#
# Get the URL of the image described in the previous example, so you can insert
# this URL as the src of an img element on an HTML page
#   require 'googlestaticmap'
#  map = GoogleStaticMap.new(:zoom => 11, :center => MapLocation.new(:address => "Washington, DC"))
#  image_url = map.url(:auto)
#
# Get a map with blue markers at the White House and the Supreme Court, zoomed
# the closest that the map can be with both markers visible, at the default
# size.
#   map = GoogleStaticMap.new
#   map.markers << MapMarker.new(:color => "blue", :location => MapLocation.new(:address => "1600 Pennsylvania Ave., Washington, DC"))
#   map.markers << MapMarker.new(:color => "blue", :location => MapLocation.new(:address => "1 1st Street Northeast, Washington, DC"))
#   image = map.get_map
#
# Get a GIF satellite map, with a size of 640 x 480, with a
# semi transparent green box drawn around a set of 4 coordinates, with the box
# outline solid, centered at the middle of the box, written out to the file
# map.gif:
#   map = GoogleStaticMap.new(:maptype => "satellite", :format => "gif", :width => 640, :height => 480)
#   poly = MapPolygon.new(:color => "0x00FF00FF", :fillcolor => "0x00FF0060")
#   poly.points << MapLocation.new(:latitude => 38.8, :longitude => -77.5)
#   poly.points << MapLocation.new(:latitude => 38.8, :longitude => -76.9)
#   poly.points << MapLocation.new(:latitude => 39.2, :longitude => -76.9)
#   poly.points << MapLocation.new(:latitude => 39.2, :longitude => -77.5)
#   poly.points << MapLocation.new(:latitude => 38.8, :longitude => -77.5)
#   map.paths << poly
#   map.get_map("map.gif")
#
# If you're working behind a proxy, create the map object this way:
# map = GoogleStaticMap.new(:proxy_address=>'my.proxy.host', :proxy_port=>8080, :width => 640, :height => 480)
#
# Author:: Brent Sowers (mailto:brent@coordinatecommons.com)
# License:: You're free to do whatever you want with this
#
# To post comments about this gem, go to my blog posting at
# http://www.brentsowers.com/2010/08/gem-for-getting-google-static-maps.html

require 'cgi'
require 'net/http'
require 'net/https' if RUBY_VERSION < "1.9"
require File.dirname(__FILE__) +  '/googlestaticmap_helper'

MAP_SEPARATOR = CGI.escape("|")

# Main class for creating a static map.  Create an instance, Set attributes
# that describe properties of the map.  Then call url to get a URL that you
# can use as the src of an img tag.  You can also call get_map to actually
# download the map from Google, and optionally write it to a file.
class GoogleStaticMap
  # Width of resulting image in pixels, defaults to 500, maximum 640
  attr_accessor :width

  # Height of resulting image in pixels, defaults to 350, maximum 640
  attr_accessor :height

  # An optional array of MapMarker instances
  attr_accessor :markers

  # An optional array of MapPath instances and/or MapPolygon instances to draw
  attr_accessor :paths

  # MapLocation for the center of the map. If this is not specified, the map
  # will zoom to the markers
  attr_accessor :center

  # 0 (the whole world) to 21 (individual buildings)
  attr_accessor :zoom

  # Applications that determine the user's location via a sensor must set this
  # to true, defaults to false
  attr_accessor :sensor

  # 1, 2, or 4 for Maps API Premier customers. Defaults to 1. Makes everything
  # in the image appear larger, useful for displaying on high res mobile
  # screens.  When setting this, the image's actual width and height in pixels
  # will be scale * width and scale * height
  attr_accessor :scale

  # format of the image:
  # * png8 - 8 bit PNG (default)
  # * png32 - 32 bit PNG
  # * gif
  # * jpg
  # * jpg-baseline - non-progressive JPEG
  attr_accessor :format

  # Type of map to create:
  # * roadmap (default)
  # * satellite
  # * terrain
  # * hybrid - satellite imagery with roads
  attr_accessor :maptype

  # If you need to use a proxy server to reach Google, set the name/address
  # of the proxy server here
  attr_accessor :proxy_address

  # If proxy_address is set, set this to the port of the proxy server
  attr_accessor :proxy_port

  # Key - see https://developers.google.com/maps/documentation/staticmaps/#api_key for details
  attr_accessor :key

  # ClientId/PrivateKey - see https://developers.google.com/maps/documentation/business/webservices/auth#generating_valid_signatures for details
  attr_accessor :client
  attr_accessor :private_key

  # Takes an optional hash of attributes
  def initialize(attrs={})
    defaults = {:width => 500, :height => 350, :markers => [],
                :sensor => false, :maptype => "roadmap", :paths => [],
                :proxy_port => nil, :proxy_address => nil}

    attributes = defaults.merge(attrs)
    attributes.each {|k,v| self.send("#{k}=".to_sym,v)}
  end

  # Returns the full URL to retrieve this static map.  You can use this as the
  # src for an img to display an image directly on a web page
  # Example - "http://maps.google.com/maps/api/staticmap?params..."
  # +protocol+ can be 'http', 'https' or :auto. Specifying :auto will not return
  #   a protocol in the URL ("//maps.google.com/..."), allowing the browser to
  #   select the appropriate protocol (if the page is loaded with https, it will
  #   use https). Defaults to http
  def url(protocol='http')
    unless @center || @markers.length > 0 || @paths.length > 0
      raise Exception.new("Need to specify either a center, markers, or a path")
    end
    protocol = 'http' unless protocol == 'http' || protocol == 'https' ||
                             protocol == :auto
    protocol = protocol == :auto ? '' : protocol + ":"
    u = "#{protocol}//maps.google.com"
    path = "/maps/api/staticmap?"
    attrs = GoogleStaticMapHelpers.safe_instance_variables(self,
              ["markers", "paths", "width", "height", "center",
               "proxy_address", "proxy_port", "key", "private_key"],
              :cgi_escape_values => true).to_a
    attrs << ["size", "#{@width}x#{@height}"] if @width && @height
    markers.each {|m| attrs << ["markers",m.to_s] }
    paths.each {|p| attrs << ["path",p.to_s] }
    attrs << ["center", center.to_s] if !center.nil?
    path << attrs.collect {|attr| "#{attr[0]}=#{attr[1]}"}.join("&")
    if key
      u << path << "&key=" << key
    elsif client && private_key
      u << path << "&signature=" << sign(path)
    else
      u << path
    end
  end

  # Returns the URL to retrieve the map, relative to http://maps.google.com
  # Example - "/maps/api/staticmap?params..."
  def relative_url(protocol='http')
    url(protocol).gsub(/[^\/]*\/\/maps\.google\.com/, "")
  end


  # Connects to Google, retrieves the map, and returns the bytes for the image.
  # Optionally, pass it an output name and the contents will get written to
  # this file name
  # +output_file+ - optionally give the name of a file to write the output to.
  #                 Pass nil to not write the output to a file
  # +protocol+ - specify http or https here for the protocol to retrieve the
  #              map with. Defaults to http
  # return value - the binary data for the map
  def get_map(output_file=nil, protocol='http')
    protocol = 'http' unless protocol == 'http' || protocol == 'https'
    port = protocol == 'https' ? 443 : 80
    http = Net::HTTP.Proxy(@proxy_address,@proxy_port).new("maps.google.com", port)
    http.use_ssl = protocol == 'https'

    resp = http.get2(relative_url(protocol))
    if resp && resp.is_a?(Net::HTTPSuccess)
      if output_file
        File.open(output_file, "wb") {|f| f << resp.body }
      end
      resp.body
    else
      if resp
        raise Exception.new("Error encountered while retrieving google map, code #{resp.code}, text #{resp.body}")
      else
        raise Exception.new("Error while retrieve google map, no response")
      end
    end
  end

  private

  # signing code is grabbed from https://github.com/alexreisner/geocoder
  def sign(path)
    raw_private_key = url_safe_base64_decode(private_key)
    digest = OpenSSL::Digest::Digest.new('sha1')
    raw_signature = OpenSSL::HMAC.digest(digest, raw_private_key, path)
    url_safe_base64_encode(raw_signature)
  end

  def url_safe_base64_decode(base64_string)
    Base64.decode64(base64_string.tr('-_', '+/'))
  end

  def url_safe_base64_encode(raw)
    Base64.encode64(raw).tr('+/', '-_').strip
  end

end

# Container class for a location on the map.  Set either a latitude and
# longitude, or an address
class MapLocation
  # Decimal degrees, positive is north
  attr_accessor :latitude

  # Decimal degrees, positive is east
  attr_accessor :longitude

  # String address - can be a full address, city name, zip code, etc.  This is
  # ignored if latitude and longitude are set.
  attr_accessor :address

  def initialize(attrs={})
    attrs.each {|k,v| self.send("#{k}=".to_sym,v.to_s)}
  end

  def to_s
    if latitude && longitude
      "#{CGI.escape(latitude.to_s)},#{CGI.escape(longitude.to_s)}"
    elsif address
      CGI.escape(address)
    else
      raise Exception.new("Need to set either latitude and longitude, or address")
    end
  end
end

# A single marker to place on the map.  Initialize and pass
class MapMarker
  # A 24-bit color (example: 0xFFFFCC) or a predefined color from the set
  # {black, brown, green, purple, yellow, blue, gray, orange, red, white}
  attr_accessor :color

  # MapLocation for the position of this marker
  attr_accessor :location

  # (optional) The size of marker from the set {tiny, small, mid}. Defaults to
  # mid
  attr_accessor :size

  # (optional) A single uppercase alphanumeric character label from the set
  # {A-Z, 0-9}.  Not allowed for tiny and small sizes
  attr_accessor :label

  # a URL to use as the marker's custom icon. Images may be in PNG, JPEG or GIF
  # formats, though PNG is recommended
  attr_accessor :icon

  # true (default) indicates that the Static Maps service should construct an
  # appropriate shadow for the image. This shadow is based on the image's
  # visible region and its opacity/transparency.
  attr_accessor :shadow

  # Takes an optional hash of attributes
  def initialize(attrs={})
    attrs.each {|k,v| self.send("#{k}=".to_sym,v)}
  end

  def to_s
    raise Exception.new("Need a location for the marker") unless @location && @location.is_a?(MapLocation)
    attrs = GoogleStaticMapHelpers.safe_instance_variables(self, ["location"])
    s = attrs.to_a.collect do |k|
      # If the icon URL is URL encoded, it won't work
      val = (k[0] == "icon" ? k[1] : CGI.escape(k[1].to_s))
      "#{k[0]}:#{val}"
    end.join(MAP_SEPARATOR)
    s << MAP_SEPARATOR << @location.to_s
  end
end

# A path line to draw on the map.  Initialize and set attributes.
class MapPath
  # Thickness of the path line in pixels, defaults to 5
  attr_accessor :weight

  # Color of the path, either as a 24-bit (example: color=0xFFFFCC), a 32-bit
  # hexadecimal value (example: color=0xFFFFCCFF), or from the set
  # {black, brown, green, purple, yellow, blue, gray, orange, red, white}
  # When a 32-bit hex value is specified, the last two characters specify the
  # 8-bit alpha transparency value. This value varies between 00
  # (completely transparent) and FF (completely opaque).
  attr_accessor :color

  # MapPositions for each point on the line
  attr_accessor :points

  # Pass an optional hash of arguments
  def initialize(attrs={})
    @points = []
    attrs.each {|k,v| self.send("#{k}=".to_sym,v)}
  end

  def to_s
    raise Exception.new("Need more than one point for the path") unless @points && @points.length > 1
    attrs = GoogleStaticMapHelpers.safe_instance_variables(self, ["points"])
    s = attrs.to_a.collect {|k| "#{k[0]}:#{CGI.escape(k[1].to_s)}"}.join(MAP_SEPARATOR)
    s << MAP_SEPARATOR << @points.join(MAP_SEPARATOR)
  end
end

# A polygon to draw and fill on the map.  Has the same properties as a path
# with the addition of a fill color.  The points do not need to form a closed
# loop, the last point will automatically be joined the first point
class MapPolygon < MapPath
  # Color to fill in, either as a 24-bit (example: color=0xFFFFCC), a 32-bit
  # hexadecimal value (example: color=0xFFFFCCFF), or from the set
  # {black, brown, green, purple, yellow, blue, gray, orange, red, white}
  # When a 32-bit hex value is specified, the last two characters specify the
  # 8-bit alpha transparency value. This value varies between 00
  # (completely transparent) and FF (completely opaque).
  attr_accessor :fillcolor

  def initialize(attrs={})
    @points = []
    attrs.each {|k,v| self.send("#{k}=".to_sym,v)}
  end
end


