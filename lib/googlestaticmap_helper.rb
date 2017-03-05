require 'base64'
require 'openssl'

# Helper methods used in this code
module GoogleStaticMapHelpers #:nodoc: all
  # Returns a hash of instance variables for the passed in Object, where the
  # key is the instance variable name ("@instance_variable"), and the value is
  # the current instance variable value.  This is safe for Ruby 1.8 and 1.9.
  # Pass an optional array of instance variable name strings
  # (["instance_variable_1", "instance_variable_2"]) to not include in the
  # result.  Example result:
  # {"variable_1" => 123, "variable_2" => "2 value"}
  # All inputs and outputs do NOT have the @ in the instance variable name
  # options -
  #   :cgi_escape_values - set this to true to return all values as
  #   CGI escaped strings
  def self.safe_instance_variables(object, ivs_to_exclude=[], options={})
    ivs = {}
    object.instance_variables.each do |i|
      # Don't include the @
      iv_name = i.to_s[1..-1]
      unless ivs_to_exclude.include?(iv_name)
        val = object.instance_variable_get(i)
        if options.has_key?(:cgi_escape_values)
          val = case val
                when ::MapLocation, ::MapMarker, ::MapPath, ::MapPolygon
                  val.to_s
                else
                  CGI.escape(val.to_s)
                end
        end
        ivs[iv_name] = val
      end
    end
    ivs
  end

  # signing code is grabbed from https://github.com/alexreisner/geocoder
  def self.sign(path, key)
    raw_private_key = self.url_safe_base64_decode(key)
    digest = OpenSSL::Digest.new('sha1')
    raw_signature = OpenSSL::HMAC.digest(digest, raw_private_key, path)
    self.url_safe_base64_encode(raw_signature)
  end

  def self.url_safe_base64_decode(base64_string)
    Base64.decode64(base64_string.tr('-_', '+/'))
  end

  def self.url_safe_base64_encode(raw)
    Base64.encode64(raw).tr('+/', '-_').strip
  end

end
