require File.dirname(__FILE__) + '/lib/googlestaticmap'

print "-----------------------------------------------------------------------------\n"
print "--------------  Test 1, grabbing a map of Washington, DC --------------------\n"
print "-----------------------------------------------------------------------------\n"
print "\n"
map = GoogleStaticMap.new(:zoom => 11, :center => MapLocation.new(:address => "Washington, DC"))
image = map.get_map
print "Got a map of size #{image.length}, should be roughly 100K\n"
image_url = map.url(:auto)
print "The URL for this map is '#{image_url}'\n"


print "\n\n\n"
print "-----------------------------------------------------------------------------\n"
print "- Test 2, Get a map with blue markers at the White House and the Supreme    -\n" 
print "- Court, zoomed the closest that the map can be with both markers visible,  -\n"
print "- at the default size.                                                      -\n"
print "-----------------------------------------------------------------------------\n"
print "\n"
map = GoogleStaticMap.new
map.markers << MapMarker.new(:color => "blue", :location => MapLocation.new(:address => "1600 Pennsylvania Ave., Washington, DC"))
map.markers << MapMarker.new(:color => "blue", :location => MapLocation.new(:address => "1 1st Street Northeast, Washington, DC"))
image = map.get_map

print "Got a map of size #{image.length}, should be roughly 50K\n"
image_url = map.url(:auto)
print "The URL for this map is '#{image_url}'\n"

print "\n\n\n"
print "-----------------------------------------------------------------------------\n"
print "- Test 3, Get a GIF satellite map, with a size of 640 x 480, with a semi    -\n"
print "- transparent green box drawn around a set of 4 coordinates, with the box   -\n"
print "- outline solid, centered at the middle of the box, written out to the file -\n"
print "- map.gif:                                                                  -\n"
print "-----------------------------------------------------------------------------\n"
print "\n"
map = GoogleStaticMap.new(:maptype => "satellite", :format => "gif", :width => 640, :height => 480)
poly = MapPolygon.new(:color => "0x00FF00FF", :fillcolor => "0x00FF0060")
poly.points << MapLocation.new(:latitude => 38.8, :longitude => -77.5)
poly.points << MapLocation.new(:latitude => 38.8, :longitude => -76.9)
poly.points << MapLocation.new(:latitude => 39.2, :longitude => -76.9)
poly.points << MapLocation.new(:latitude => 39.2, :longitude => -77.5)
poly.points << MapLocation.new(:latitude => 38.8, :longitude => -77.5)
map.paths << poly
map.get_map("map.gif")

print "There should now be a map.gif file in this directory.\n"


