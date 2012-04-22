= googlestaticmap gem

This gem is on Rubygems, simply type "gem install googlestaticmap" to install it.

Available on github at http://github.com/brentsowers1/googlestaticmap

Class for generating URLs for and downloading static maps from the Google Maps
Static API service.  GoogleStaticMap is the main class to use, instantiate it,
set the attributes to what you want, and call url on the instance to get the
URL to download the map from.  You can also call get_map to actually
download the map from Google, return the bytes, and optionally write the
image to a file.

== Examples:

Get a simple static map centered at Washington, DC, with the default size
(500 x 350), zoomed to level 11.  image will be the binary data of the map
  require 'googlestaticmap'
  map = GoogleStaticMap.new(:zoom => 11, :center => MapLocation.new(:address => "Washington, DC"))
  image = map.get_map

Get the URL of the image described in the previous example, so you can insert
this URL as the src of an img element on an HTML page
  require 'googlestaticmap'
  map = GoogleStaticMap.new(:zoom => 11, :center => MapLocation.new(:address => "Washington, DC"))
  image_url = map.url(:auto)

Get a map with blue markers at the White House and the Supreme Court, zoomed
the closest that the map can be with both markers visible, at the default
size.  image will be the binary data of the map
  require 'googlestaticmap'
  map = GoogleStaticMap.new
  map.markers << MapMarker.new(:color => "blue", :location => MapLocation.new(:address => "1600 Pennsylvania Ave., Washington, DC"))
  map.markers << MapMarker.new(:color => "blue", :location => MapLocation.new(:address => "1 1st Street Northeast, Washington, DC"))
  image = map.get_map

Get a GIF satellite map, with a size of 640 x 480, with a
semi transparent green box drawn around a set of 4 coordinates, with the box
outline solid, centered at the middle of the box, written out to the file
map.gif:
  require 'googlestaticmap'
  map = GoogleStaticMap.new(:maptype => "satellite", :format => "gif", :width => 640, :height => 480)
  poly = MapPolygon.new(:color => "0x00FF00FF", :fillcolor => "0x00FF0060")
  poly.points << MapLocation.new(:latitude => 38.8, :longitude => -77.5)
  poly.points << MapLocation.new(:latitude => 38.8, :longitude => -76.9)
  poly.points << MapLocation.new(:latitude => 39.2, :longitude => -76.9)
  poly.points << MapLocation.new(:latitude => 39.2, :longitude => -77.5)
  poly.points << MapLocation.new(:latitude => 38.8, :longitude => -77.5)
  map.paths << poly
  map.get_map("map.gif")

If you're working behind a proxy, create the map object this way:
  map = GoogleStaticMap.new(:proxy_address=>'my.proxy.host', :proxy_port=>8080, :width => 640, :height => 480)


Author:: Brent Sowers (mailto:brent@coordinatecommons.com)
License:: You're free to do whatever you want with this

To post comments about this gem, go to my blog posting at
http://www.brentsowers.com/2010/08/gem-for-getting-google-static-maps.html