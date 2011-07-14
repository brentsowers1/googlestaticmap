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
  #   :uri_escape_values - set this to true to return all values as
  #   URI escaped strings
  def self.safe_instance_variables(object, ivs_to_exclude=[], options={})
    ivs = {}
    object.instance_variables.each do |i|
      # Don't include the @
      iv_name = i.to_s[1..-1]
      unless ivs_to_exclude.include?(iv_name)
        val = object.instance_variable_get(i)
        val = URI.escape(val.to_s) if options.has_key?(:uri_escape_values)
        ivs[iv_name] = val
      end
    end
    ivs
  end
end
