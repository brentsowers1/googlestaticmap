require 'test/unit'
require 'uri'
require File.dirname(__FILE__) +  '/../lib/googlestaticmap_helper'

class GoogleStaticMapHelperTest < Test::Unit::TestCase #:nodoc: all

  IVS = {"@var1" => 1, "@var2" => 2, "@var3" => 3,
         "@url" => "http://maps.google.com"}

  class MockRuby18Object
    def self.instance_variables
      IVS.keys
    end
    def self.instance_variable_get(variable)
      IVS[variable]
    end
  end

  # Ruby 1.9 refers to instance variables as symbols, like :@var1.  The
  # helper class needs to handle both cases
  class MockRuby19Object
    def self.instance_variables
      IVS.keys.collect {|k| k.to_sym}
    end
    def self.instance_variable_get(variable)
      IVS[variable.to_s]
    end
  end


  def test_safe_instance_variables_no_params
    [MockRuby18Object, MockRuby19Object].each do |o|
      assert_equal ivs_no_at, GoogleStaticMapHelpers.safe_instance_variables(o)
    end
  end

  def test_safe_instance_variables_exclude
    [MockRuby18Object, MockRuby19Object].each do |o|
      sivs = GoogleStaticMapHelpers.safe_instance_variables(o, ["var2"])
      assert_equal IVS.length-1, sivs.length
      assert !sivs.has_key?("@var2")
    end
  end

  def test_safe_instance_variables_uri
    [MockRuby18Object, MockRuby19Object].each do |o|
      sivs = GoogleStaticMapHelpers.safe_instance_variables(o, [], :uri_escape_values => true)
      assert_equal IVS.length, sivs.length
      assert_equal URI.escape(IVS["@url"]), sivs["url"]
    end
  end

  private
  def ivs_no_at
    ivs = {}
    IVS.each do |k,v|
      ivs[k[1..-1]] = v
    end
    ivs
  end
end
