require 'acts_as_list_with_sti_support'

ActiveRecord::Base.class_eval do
  include Coroutine::Acts::List
end