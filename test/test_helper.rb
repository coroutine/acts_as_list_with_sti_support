require 'rubygems'
require 'active_support'
require 'active_support/test_case'


#----------------------------------------------------------
# Define global methods
#----------------------------------------------------------

class Test::Unit::TestCase
  
  # This method allows us to use a convenient notation for testing
  # model validations.
  def assert_not_valid(object, msg="Object is valid when it should be invalid")
    assert(!object.valid?, msg)
  end
  alias :assert_invalid :assert_not_valid

end