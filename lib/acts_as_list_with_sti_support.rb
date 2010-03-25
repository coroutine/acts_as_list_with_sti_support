# external gems
require "active_record"


# acts_as_label extension
require File.dirname(__FILE__) + "/acts_as_list_with_sti_support/base"


# add extensions to active record
::ActiveRecord::Base.send(:include, Coroutine::ActsAsList::Base)