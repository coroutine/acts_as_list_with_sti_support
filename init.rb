require 'acts_as_list'

ActiveRecord::Base.class_eval do
  include Coroutine::Acts::List
end