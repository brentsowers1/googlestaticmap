require 'test/unit'
require 'cgi'
require File.dirname(__FILE__) +  '/../lib/googlestaticmap_helper'

class GoogleStaticMapHelperTest < Test::Unit::TestCase #:nodoc: all

  IVS = {"@var1" => 1, "@var2" => 2, "@var3" => 3,
         "@url" => "http://maps.google.com", "@nilvar" => nil}

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
      sivs = GoogleStaticMapHelpers.safe_instance_variables(o)
      assert_equal ivs_no_at, sivs
      assert !sivs.has_key?("@nilvar")
    end
  end

  def test_safe_instance_variables_exclude
    [MockRuby18Object, MockRuby19Object].each do |o|
      sivs = GoogleStaticMapHelpers.safe_instance_variables(o, ["var2"])
      assert_equal IVS.length-2, sivs.length
      assert !sivs.has_key?("@var2")
    end
  end

  def test_safe_instance_variables_cgi
    [MockRuby18Object, MockRuby19Object].each do |o|
      sivs = GoogleStaticMapHelpers.safe_instance_variables(o, [], :cgi_escape_values => true)
      assert_equal IVS.length-1, sivs.length
      assert_equal CGI.escape(IVS["@url"]), sivs["url"]
    end
  end

  def test_signature
    # This comes from the google example at
    # https://developers.google.com/maps/documentation/business/webservices/auth
    private_key = "vNIXE0xscrmjlyV-12Nj_BvUPaw="
    url = "/maps/api/geocode/json?address=New+York&sensor=false&client=clientID"
    sig = GoogleStaticMapHelpers.sign(url, private_key)
    assert_equal sig, "KrU1TzVQM7Ur0i8i7K3huiw3MsA="
  end

  private
  def ivs_no_at
    ivs = {}
    IVS.each do |k,v|
      ivs[k[1..-1]] = v unless v.nil?
    end
    ivs
  end
end
