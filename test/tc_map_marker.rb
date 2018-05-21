require 'test/unit'
require 'cgi'
require File.dirname(__FILE__) +  '/../lib/googlestaticmap'

class MapMarkerTest < Test::Unit::TestCase #:nodoc: all
  def test_exception_no_location
    m = MapMarker.new
    assert_raise Exception do
      m.to_s
    end
  end

  def test_exception_invalid_location
    m = MapMarker.new
    m.location = 99
    assert_raise Exception do
      m.to_s
    end
  end

  def test_set_parameters
    m = nil
    assert_nothing_raised { m = default_marker }
    assert_equal "green", m.color
    assert_equal "Washington, DC", m.location.address
    assert_equal "tiny", m.size
    assert_equal "B", m.label
    assert_equal "http://www.google.com", m.icon
    assert_equal false, m.shadow
    assert_equal 'center', m.anchor
  end

  def test_get_string
    m = default_marker
    s = nil
    assert_nothing_raised {s = m.to_s}
    assert_equal 7, s.split(MAP_SEPARATOR).length
    assert s.include?(CGI.escape("Washington, DC"))
    assert s.include?("color:green")
    assert s.include?("icon:http://www.google.com")
    assert s.include?("anchor:center")
  end

  def test_string_is_a_valid_ruby_uri
    m = default_marker
    URI.parse(m.to_s)
  end

  private
  def default_marker
    MapMarker.new(:color => "green",
                  :location => MapLocation.new(:address => "Washington, DC"),
                  :size => "tiny",
                  :label => "B",
                  :icon => "http://www.google.com",
                  :anchor => 'center',
                  :shadow => false)
  end
end
