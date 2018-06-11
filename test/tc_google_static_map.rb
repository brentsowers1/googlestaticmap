require 'rubygems'
require 'test/unit'
require 'cgi'
require 'net/http'
require 'mocha/setup'
require File.dirname(__FILE__) +  '/../lib/googlestaticmap'

class MockSuccess < Net::HTTPSuccess #:nodoc: all
  def initialize(data)
    @data = data
  end

  def body
    @data
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
  def use_ssl=(value)
    true
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
    assert_equal 7, u.split("&").length, u
    assert u.include?("size=600x400"), "width and height did not get converted in to a size"
    assert u.include?("maptype=hybrid")
    assert u.include?("scale=2")
    assert u.include?("asdf")
    assert u.include?("http://maps.googleapis.com")
    assert u.include?("color:0x00FF00FF")
    assert u.include?("fillcolor:0x00FF0060")
    assert u.include?("38.8,-77.5#{MAP_SEPARATOR}38.8,-76.9#{MAP_SEPARATOR}39.2,-76.9#{MAP_SEPARATOR}39.2,-77.5#{MAP_SEPARATOR}38.8,-77.5"), "Polygon not in URL - #{u}"
    assert u.include?("Washington%2C+DC")
    assert !u.include?("key"), "API included when it shouldn't be"
    assert !u.include?("client"), "Client included when it shouldn't be"

    f = nil
    assert_nothing_raised {f = g.relative_url}
    assert !f.include?("http://maps.googleapis.com")
  end

  def test_channel
    g = default_map
    g.channel = "CHANNEL"
    assert g.url.include?("channel=CHANNEL")
  end

  def test_url_auto
    g = default_map
    u = nil
    assert_nothing_raised { u = g.url(:auto) }
    assert_equal 7, u.split("&").length, u
    assert u =~ /^\/\/maps.googleapis.com/, u
    f = nil
    assert_nothing_raised {f = g.relative_url}
    assert_no_match /^\/\/maps.googleapis.com/, f
  end

  # Language is the only nullable one that goes through the normal safe instance
  # variable pattern
  def test_url_with_langauge
    g = default_map
    g.language = "jp"
    assert g.url.include?("language=jp")
  end

  def test_url_https
    g = default_map
    u = nil
    assert_nothing_raised { u = g.url('https') }
    assert_equal 7, u.split("&").length, u
    assert u =~ /^https:\/\/maps.googleapis.com/
    f = nil
    assert_nothing_raised {f = g.relative_url}
    assert_no_match /^https:\/\/maps.googleapis.com/, f
  end

  def test_url_styles
    g = default_map
    g.styles = [
      { feature: 'road.local', element: 'geometry', color: '0x00ff00' },
      { feature: 'landscape', element: 'geometry.fill', color: '0x000000' },
      { element: 'labels', invert_lightness: true },
      { feature: 'road.arterial', element: 'labels', invert_lightness: false }
    ]
    u = nil

    assert_nothing_raised { u = g.url }
    assert_equal 11, u.split("&").length, u
    assert !u.include?("styles"), "styles have to be convered to array of 'style'"
    assert u.include?('style=feature:road.local%7Celement:geometry%7Ccolor:0x00ff00'), u
    assert u.include?('style=feature:landscape%7Celement:geometry.fill%7Ccolor:0x000000'), u
    assert u.include?('style=element:labels%7Cinvert_lightness:true&style=feature:road.arterial%7Celement:labels%7Cinvert_lightness:false'), u

    assert_nothing_raised {g.relative_url}
  end

  def test_url_plain_string
    g = default_map
    g.plain_string = "style=feature:road.local%7Celement:geometry%7Ccolor:0x00ff00&style=feature:landscape%7Celement:geometry.fill%7Ccolor:0x000000"
    u = nil

    assert_nothing_raised { u = g.url }
    assert_equal 9, u.split("&").length, u
    assert !u.include?("plain_string")
    assert u.include?('&style=feature:road.local%7Celement:geometry%7Ccolor:0x00ff00&style=feature:landscape%7Celement:geometry.fill%7Ccolor:0x000000')

    assert_nothing_raised {g.relative_url}
  end

  def test_url_api_key
    g = default_map
    g.api_key = "asdfapikey"
    u = nil
    assert_nothing_raised { u = g.url }
    assert_equal 8, u.split("&").length, u
    assert u.include?("key=asdfapikey"), u
    assert !u.include?("client"), u
    assert !u.include?("signature"), u
  end

  def test_url_api_key_with_private_key
    g = default_map
    g.api_key = "asdfapikey"
    g.private_key = "vNIXE0xscrmjlyV-12Nj_BvUPaw="
    u = nil
    assert_nothing_raised { u = g.url }
    assert_equal 9, u.split("&").length, u
    assert u.include?("key=asdfapikey"), u
    assert !u.include?("client"), u
    assert u.include?("signature="), u
  end

  def test_url_for_business
    g = default_map
    g.client_id = "asdfclientid"
    g.private_key = "vNIXE0xscrmjlyV-12Nj_BvUPaw="
    u = nil
    assert_nothing_raised { u = g.url }
    assert_equal 9, u.split("&").length, u
    assert u.include?("signature=Di7rQ4jUrDiF6vY2PkF1-BRwhAg="), u
    assert u.include?("client=asdfclientid"), u
    assert !u.include?("key="), u
  end

  def test_url_for_business_no_private_key
    g = default_map
    g.client_id = "asdfclientid"
    u = nil
    assert_raise { u = g.url }
  end

  def test_url_for_business_with_api_key
    g = default_map
    g.client_id = "asdfclientid"
    g.private_key = "vNIXE0xscrmjlyV-12Nj_BvUPaw="
    g.api_key = "asdfapikey"
    u = nil
    assert_raise { u = g.url }
  end

  def test_get_map_success_no_file_http
    test_data = "asdf"
    MockHttp.any_instance.expects(:get2).returns(MockSuccess.new(test_data))
    MockHttp.any_instance.expects(:"use_ssl=").with(false).returns(false)
    Net::HTTP.expects(:new).returns(MockHttp.new)

    g = default_map
    r = nil
    assert_nothing_raised {r = g.get_map}
    assert_equal r, test_data
  end

  def test_get_map_success_no_file_https
    test_data = "asdf"
    MockHttp.any_instance.expects(:get2).returns(MockSuccess.new(test_data))
    MockHttp.any_instance.expects(:"use_ssl=").with(true).returns(true)
    Net::HTTP.expects(:new).returns(MockHttp.new)

    g = default_map
    r = nil
    assert_nothing_raised {r = g.get_map(nil, 'https')}
    assert_equal r, test_data
  end

  def test_get_map_success_write_file
    test_data = "asdf"
    MockHttp.any_instance.expects(:get2).returns(MockSuccess.new(test_data))
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

  def test_get_map_success_check_url
    test_data = "asdf"
    MockHttp.any_instance.expects(:get2).returns(MockSuccess.new(test_data))
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
    MockHttp.any_instance.expects(:get2).returns(MockFailure.new)
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
