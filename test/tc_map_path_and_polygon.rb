require 'test/unit'
require 'cgi'
require File.dirname(__FILE__) +  '/../lib/googlestaticmap'

class MapPathAndPolygonTest < Test::Unit::TestCase #:nodoc: all
  def test_exception_no_points
    m = MapPath.new
    assert_raise Exception do
      m.to_s
    end
  end

  def test_exception_empty_points
    m = MapPath.new
    m.points = [MapLocation.new(:address => "asdf")]
    assert_raise Exception do
      m.to_s
    end
  end

  def test_set_parameters
    p = nil
    assert_nothing_raised { p = default_path }
    assert_equal 2, p.weight
    assert_equal "0xFF0000FF", p.color
    assert_equal 2, p.points.length
  end

  def test_get_string
    p = default_path
    s = nil
    assert_nothing_raised { s = p.to_s }
    assert_equal 4, s.split(MAP_SEPARATOR).length
    assert s.include?("color:0xFF0000FF")
    assert s.include?("loc1")
    assert s.include?("loc2")
  end

  def test_string_is_a_valid_ruby_uri
    m = default_path
    URI.parse(m.to_s)
  end

  def test_encoded_polylines
    p = default_path
    s = nil
    p.points = nil
    p.enc = "BigEncodedLineOfSymbols10"
    assert_nothing_raised { s = p.to_s }
    assert_equal 3, s.split(MAP_SEPARATOR).length
    assert s.end_with?("enc:BigEncodedLineOfSymbols10")
    assert !s.include?("points")
  end

  def test_polygon
    # Polygon inherits from MapPath and uses MapPath's to_s method, so only
    # limited testing needs to happen here
    p = nil
    assert_nothing_raised do
      p = MapPolygon.new(:fillcolor => "0xFFFF00FF",
                         :color => "0xFF0000FF",
                         :points => [MapLocation.new(:address => "loc1"),
                                     MapLocation.new(:address => "loc2")])
    end
    assert_equal "0xFFFF00FF", p.fillcolor
    assert_equal "0xFF0000FF", p.color
  end

  private
  def default_path
    MapPath.new(:weight => 2, :color => "0xFF0000FF",
                :points => [MapLocation.new(:address => "loc1"),
                            MapLocation.new(:address => "loc2")])
  end

end
