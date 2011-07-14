# = googlestaticmap gem
#
# This gem is on Gemcutter, simply type "gem install googlestaticmap" to install it.
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
# Author:: Brent Sowers (mailto:brent@coordinatecommons.com)
# License:: You're free to do whatever you want with this

require 'uri'
require 'net/http'
require File.dirname(__FILE__) +  '/googlestaticmap_helper'

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

  # Takes an optional hash of attributes
  def initialize(attrs={})
    defaults = {:width => 500, :height => 350, :markers => [],
                :sensor => false, :maptype => "roadmap", :paths => []}
    attributes = defaults.merge(attrs)
    attributes.each {|k,v| self.send("#{k}=".to_sym,v)}
  end

  # Returns the full URL to retrieve this static map.  You can use this as the
  # src for an img to display an image directly on a web page
  # Example - "http://maps.google.com/maps/api/staticmap?params..."
  def url
    unless @center || @markers.length > 0 || @paths.length > 0
      raise Exception.new("Need to specify either a center, markers, or a path")
    end
    u = "http://maps.google.com/maps/api/staticmap?"
    attrs = GoogleStaticMapHelpers.safe_instance_variables(self, ["markers", "paths", "width", "height"], :uri_escape_values => true).to_a
    attrs << ["size", "#{@width}x#{@height}"] if @width && @height
    markers.each {|m| attrs << ["markers",m.to_s] }
    paths.each {|p| attrs << ["path",p.to_s] }
    u << attrs.collect {|attr| "#{attr[0]}=#{attr[1]}"}.join("&")
  end

  # Returns the URL to retrieve the map, relative to http://maps.google.com
  # Example - "/maps/api/staticmap?params..."
  def relative_url
    url.gsub(/http\:\/\/maps\.google\.com/, "")
  end

  # Connects to Google, retrieves the map, and returns the bytes for the image.
  # Optionally, pass it an output name and the contents will get written to
  # this file name
  def get_map(output_file=nil)
    http = Net::HTTP.new("maps.google.com", 80)
    resp, data = http.get2(relative_url)
    if resp && resp.is_a?(Net::HTTPSuccess)
      if output_file
        File.open(output_file, "wb") {|f| f << data }
      end
      data
    else
      if resp
        raise Exception.new("Error encountered while retrieving google map, code #{resp.code}, text #{resp.body}")
      else
        raise Exception.new("Error while retrieve google map, no response")
      end
    end
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
      "#{URI.escape(latitude.to_s)},#{URI.escape(longitude.to_s)}"
    elsif address
      URI.escape(address)
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
      val = (k[0] == "icon" ? k[1] : URI.escape(k[1].to_s))
      "#{k[0]}:#{val}"      
    end.join("|")
    s << "|#{@location.to_s}"
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
    s = attrs.to_a.collect {|k| "#{k[0]}:#{URI.escape(k[1].to_s)}"}.join("|")
    s << "|" << @points.join("|")
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


