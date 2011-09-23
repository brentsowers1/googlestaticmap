require 'rubygems'
require 'test/unit'
require 'cgi'
require 'net/http'
require 'mocha'
require File.dirname(__FILE__) +  '/../lib/googlestaticmap'

class MockSuccess < Net::HTTPSuccess #:nodoc: all
  def initialize
  end
end

class MockFailure < Net::HTTPServiceUnavailable #:nodoc: all
  def initialize
  end
  def code
    100
  end
  def body
    "epic fail"
  end
end

class MockHttp #:nodoc: all
  def initialize
  end
end

class GoogleStaticMapTest < Test::Unit::TestCase #:nodoc: all

  class MockFile #:nodoc: all
    @@file = nil
    def self.open(name, &block)
      @@file = {name => yield}
    end
  end

  def test_exception_no_items
    g = GoogleStaticMap.new
    assert_raise Exception do
      g.url
    end
  end

  def test_set_attributes
    g = nil
    assert_nothing_raised { g = default_map }
    assert_equal 600, g.width
    assert_equal "hybrid", g.maptype
    assert_equal 1, g.markers.length
  end

  def test_url
    g = default_map
    u = nil
    assert_nothing_raised { u = g.url }
    assert_equal 6, u.split("&").length
    assert u.include?("size=600x400"), "width and height did not get converted in to a size"
    assert u.include?("maptype=hybrid")
    assert u.include?("scale=2")
    assert u.include?("asdf")
    assert u.include?("http://maps.google.com")
    assert u.include?("color:0x00FF00FF|fillcolor:0x00FF0060|38.8,-77.5|38.8,-76.9|39.2,-76.9|39.2,-77.5|38.8,-77.5"), "Polygon not in URL"
    assert u.include?("Washington%2C+DC")

    f = nil
    assert_nothing_raised {f = g.relative_url}
    assert !f.include?("http://maps.google.com")
  end

  def test_get_map_success_no_file
    test_data = "asdf"
    MockHttp.any_instance.expects(:get2).returns([MockSuccess.new,test_data])
    Net::HTTP.expects(:new).returns(MockHttp.new)

    g = default_map
    r = nil
    assert_nothing_raised {r = g.get_map}
    assert_equal r, test_data
  end

  def test_get_map_success_write_file
    test_data = "asdf"
    MockHttp.any_instance.expects(:get2).returns([MockSuccess.new,test_data])
    Net::HTTP.expects(:new).returns(MockHttp.new)
    file_data = ""
    file_name = "testdata.png"
    # File.open should be called, with the name of the file and write binary
    # passed in.  The object passed to the yield should be a file object that
    # gets the test data appended to it.  If we sub out a string for the
    # file object we can later check the contents
    File.expects(:open).with(file_name, "wb").yields(file_data)
    g = default_map
    r = nil
    assert_nothing_raised {r = g.get_map(file_name)}
    assert_equal r, test_data
    assert_equal file_data, test_data
  end


  def test_get_map_failure
    MockHttp.any_instance.expects(:get2).returns([MockFailure.new,""])
    Net::HTTP.expects(:new).returns(MockHttp.new)
    g = default_map
    assert_raise Exception do
      g.get_map
    end
  end

  def test_get_map_nothing
    MockHttp.any_instance.expects(:get2).returns(nil)
    Net::HTTP.expects(:new).returns(MockHttp.new)
    g = default_map
    assert_raise Exception do
      g.get_map
    end
  end

  private
  def default_map
    poly = MapPolygon.new(:color => "0x00FF00FF", :fillcolor => "0x00FF0060")
    poly.points << MapLocation.new(:latitude => 38.8, :longitude => -77.5)
    poly.points << MapLocation.new(:latitude => 38.8, :longitude => -76.9)
    poly.points << MapLocation.new(:latitude => 39.2, :longitude => -76.9)
    poly.points << MapLocation.new(:latitude => 39.2, :longitude => -77.5)
    poly.points << MapLocation.new(:latitude => 38.8, :longitude => -77.5)

    GoogleStaticMap.new(:width => 600, :height => 400,
                        :markers => [MapMarker.new(:location => MapLocation.new(:address => "asdf"))],
                        :center => MapLocation.new(:address => "Washington, DC"),
                        :paths => [poly],
                        :scale => 2,
                        :maptype => "hybrid")
  end
end
