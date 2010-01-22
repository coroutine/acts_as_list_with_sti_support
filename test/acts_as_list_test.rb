#---------------------------------------------------------
# Requirements
#---------------------------------------------------------

# require active record
require "rubygems"
gem     "activerecord", ">= 2.3.2"
require "active_record"


# require test stuff and plugin
require "test/test_helper"
require "test/unit"
require "#{File.dirname(__FILE__)}/../init"



#---------------------------------------------------------
# Database config
#---------------------------------------------------------

# establish db connection
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")


# define tables
def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :lists do |t|
      t.string  :label
      
      t.timestamps
    end
    
    create_table :list_items do |t|
      t.integer :list_id
      t.string  :label
      t.integer :pos
      
      t.timestamps
    end
  end
end


# drop all tables
def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end



#---------------------------------------------------------
# Model definitions
#---------------------------------------------------------

# Lists
class List < ActiveRecord::Base
end


# List Items
class ListItem < ActiveRecord::Base
  acts_as_list :column => "pos", :scope => :list
end


# Scoped By Text
class ListWithStringScopeMixin < ActiveRecord::Base
  acts_as_list :column => "pos", :scope => 'parent_id = #{parent_id}'

  def self.table_name() "mixins" end
end


# Scoped By Symbol (Subclass)
class ListMixinSub1 < ListMixin
end


# Scoped By Symbol (Subclass)
class ListMixinSub2 < ListMixin
end






#---------------------------------------------------------
# Standard Tests
#---------------------------------------------------------
















class ListTest < Test::Unit::TestCase

  def setup
    setup_db
    (1..4).each { |counter| ListMixin.create! :pos => counter, :parent_id => 5 }
  end

  def teardown
    teardown_db
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).move_lower
    assert_equal [1, 3, 2, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).move_higher
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(1).move_to_top
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(4).move_to_top
    assert_equal [4, 1, 3, 2], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  end

  def test_move_to_bottom_with_next_to_last_item
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
    ListMixin.find(3).move_to_bottom
    assert_equal [1, 2, 4, 3], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  end

  def test_next_prev
    assert_equal ListMixin.find(2), ListMixin.find(1).lower_item
    assert_nil ListMixin.find(1).higher_item
    assert_equal ListMixin.find(3), ListMixin.find(4).higher_item
    assert_nil ListMixin.find(4).lower_item
  end

  def test_injection
    item = ListMixin.new(:parent_id => 1)
    assert_equal "parent_id = 1", item.scope_condition
    assert_equal "pos", item.position_column
  end

  def test_insert
    new = ListMixin.create(:parent_id => 20)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?

    new = ListMixin.create(:parent_id => 20)
    assert_equal 2, new.pos
    assert !new.first?
    assert new.last?

    new = ListMixin.create(:parent_id => 20)
    assert_equal 3, new.pos
    assert !new.first?
    assert new.last?

    new = ListMixin.create(:parent_id => 0)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?
  end

  def test_insert_at
    new = ListMixin.create(:parent_id => 20)
    assert_equal 1, new.pos

    new = ListMixin.create(:parent_id => 20)
    assert_equal 2, new.pos

    new = ListMixin.create(:parent_id => 20)
    assert_equal 3, new.pos

    new4 = ListMixin.create(:parent_id => 20)
    assert_equal 4, new4.pos

    new4.insert_at(3)
    assert_equal 3, new4.pos

    new.reload
    assert_equal 4, new.pos

    new.insert_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 4, new4.pos

    new5 = ListMixin.create(:parent_id => 20)
    assert_equal 5, new5.pos

    new5.insert_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 5, new4.pos
  end

  def test_delete_middle
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).destroy

    assert_equal [1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(1).pos
    assert_equal 2, ListMixin.find(3).pos
    assert_equal 3, ListMixin.find(4).pos

    ListMixin.find(1).destroy

    assert_equal [3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(3).pos
    assert_equal 2, ListMixin.find(4).pos
  end

  def test_with_string_based_scope
    new = ListWithStringScopeMixin.create(:parent_id => 500)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?
  end

  def test_nil_scope
    new1, new2, new3 = ListMixin.create, ListMixin.create, ListMixin.create
    new2.move_higher
    assert_equal [new2, new1, new3], ListMixin.find(:all, :conditions => 'parent_id IS NULL', :order => 'pos')
  end
  
  
  def test_remove_from_list_should_then_fail_in_list? 
    assert_equal true, ListMixin.find(1).in_list?
    ListMixin.find(1).remove_from_list
    assert_equal false, ListMixin.find(1).in_list?
  end 
  
  def test_remove_from_list_should_set_position_to_nil 
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  
    ListMixin.find(2).remove_from_list 
  
    assert_equal [2, 1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  
    assert_equal 1,   ListMixin.find(1).pos
    assert_equal nil, ListMixin.find(2).pos
    assert_equal 2,   ListMixin.find(3).pos
    assert_equal 3,   ListMixin.find(4).pos
  end 
  
  def test_remove_before_destroy_does_not_shift_lower_items_twice 
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  
    ListMixin.find(2).remove_from_list 
    ListMixin.find(2).destroy 
  
    assert_equal [1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  
    assert_equal 1, ListMixin.find(1).pos
    assert_equal 2, ListMixin.find(3).pos
    assert_equal 3, ListMixin.find(4).pos
  end 
  
end

class ListSubTest < Test::Unit::TestCase

  def setup
    setup_db
    (1..4).each { |i| ((i % 2 == 1) ? ListMixinSub1 : ListMixinSub2).create! :pos => i, :parent_id => 5000 }
  end

  def teardown
    teardown_db
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(2).move_lower
    assert_equal [1, 3, 2, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(2).move_higher
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(1).move_to_top
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(4).move_to_top
    assert_equal [4, 1, 3, 2], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
  end

  def test_move_to_bottom_with_next_to_last_item
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
    ListMixin.find(3).move_to_bottom
    assert_equal [1, 2, 4, 3], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
  end

  def test_next_prev
    assert_equal ListMixin.find(2), ListMixin.find(1).lower_item
    assert_nil ListMixin.find(1).higher_item
    assert_equal ListMixin.find(3), ListMixin.find(4).higher_item
    assert_nil ListMixin.find(4).lower_item
  end

  def test_injection
    item = ListMixin.new("parent_id"=>1)
    assert_equal "parent_id = 1", item.scope_condition
    assert_equal "pos", item.position_column
  end

  def test_insert_at
    new = ListMixin.create("parent_id" => 20)
    assert_equal 1, new.pos

    new = ListMixinSub1.create("parent_id" => 20)
    assert_equal 2, new.pos

    new = ListMixinSub2.create("parent_id" => 20)
    assert_equal 3, new.pos

    new4 = ListMixin.create("parent_id" => 20)
    assert_equal 4, new4.pos

    new4.insert_at(3)
    assert_equal 3, new4.pos

    new.reload
    assert_equal 4, new.pos

    new.insert_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 4, new4.pos

    new5 = ListMixinSub1.create("parent_id" => 20)
    assert_equal 5, new5.pos

    new5.insert_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 5, new4.pos
  end

  def test_delete_middle
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(2).destroy

    assert_equal [1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(1).pos
    assert_equal 2, ListMixin.find(3).pos
    assert_equal 3, ListMixin.find(4).pos

    ListMixin.find(1).destroy

    assert_equal [3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(3).pos
    assert_equal 2, ListMixin.find(4).pos
  end

end




























#---------------------------------------------------------
# Tests
#---------------------------------------------------------

class ActsAsLabelTest < Test::Unit::TestCase

  #---------------------------------------------
  # setup and teardown delegations
  #---------------------------------------------
  
  def setup
    setup_db
  end
  def teardown
    teardown_db
  end



  #---------------------------------------------
  # test validations
  #---------------------------------------------
  
  def test_validations_with_standard_columns
    
    # get valid record
    record = Role.new({ :system_label => "CUSTOMER",  :label => "Client" })
    assert record.valid?
    
    # system label cannot be null
    record.system_label = nil               
    assert !record.valid?
    
    # system label cannot be blank
    record.system_label = ""               
    assert !record.valid?
    
    # system label cannot be longer than 255 characters
    record.system_label = ""                
    256.times { record.system_label << "x" }
    assert !record.valid?
    
    # system label cannot have illegal characters
    record.system_label = "SUPER-USER"
    assert !record.valid?
    
    # reset system label
    record.system_label = "CUSTOMER"
    assert record.valid?
    
    # label cannot be null
    record.label = nil               
    assert !record.valid?
     
    # label cannot be blank
    record.label = ""               
    assert !record.valid?
    
    # label cannot be longer than 255 characters
    record.label = ""                
    256.times { record.label << "x" }
    assert !record.valid?
    
  end
  
  
  def test_validations_with_custom_columns
    
    # get valid record
    record = Framework.new({ :system_name => "SPRING",  :name => "Spring" })
    assert record.valid?
    
    # system name cannot be null
    record.system_name = nil               
    assert !record.valid?
    
    # system name cannot be blank
    record.system_name = ""               
    assert !record.valid?
    
    # system name cannot be longer than 255 characters
    record.system_name = ""                
    256.times { record.system_name << "x" }
    assert !record.valid?
    
    # system name cannot have illegal characters
    record.system_name = "SPRING-JAVA"
    assert !record.valid?
    
    # reset system name
    record.system_name = "SPRING"
    assert record.valid?
    
    # name cannot be null
    record.name = nil               
    assert !record.valid?
     
    # name cannot be blank
    record.name = ""               
    assert !record.valid?
    
    # name cannot be longer than 255 characters
    record.name = ""                
    256.times { record.name << "x" }
    assert !record.valid?
    
  end
  
  
  #---------------------------------------------
  # test method missing
  #---------------------------------------------
  
  def test_method_missing_accessors
    
    # test lookup by system label
    assert_equal Role.find(:first, :conditions => ["system_label = ?", "SUPERUSER"]), Role.superuser
    
    # test default with implemented method
    assert_equal Role.find(:first, :conditions => ["system_label = ?", "GUEST"]), Role.default
    
    # test default with unspecified behavior
    assert_equal BillingFrequency.first, BillingFrequency.default
    
    # test default with specified system label
    assert_equal Framework.find(:first, :conditions => ["system_name = ?", "RUBY_ON_RAILS"]), Framework.default
    
  end
  
  
  def test_method_missing_finders
    
    # dynamic find on stand-alone model
    record = Framework.find_by_system_name("RUBY_ON_RAILS")
    assert !record.nil?
    
    #dynamic find on sti model
    record = Role.find_by_system_label("SUPERUSER")
    assert !record.nil?
    
  end
  
  
  
  #---------------------------------------------
  # test instance methods
  #---------------------------------------------
  
  def test_to_s
    role = Role.first
    assert_equal role.label, role.to_s
  end
  
  
  def test_upcase_system_label_value
    record = Role.create!({ :system_label => "Customer",  :label => "Client" })
    assert_equal record.system_label, "CUSTOMER"
  end
  
  
  
#   def test_reordering
#     assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
# 
#     ListMixin.find(2).move_lower
#     assert_equal [1, 3, 2, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
# 
#     ListMixin.find(2).move_higher
#     assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
# 
#     ListMixin.find(1).move_to_bottom
#     assert_equal [2, 3, 4, 1], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
# 
#     ListMixin.find(1).move_to_top
#     assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
# 
#     ListMixin.find(2).move_to_bottom
#     assert_equal [1, 3, 4, 2], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
# 
#     ListMixin.find(4).move_to_top
#     assert_equal [4, 1, 3, 2], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
#   end
# 
#   def test_move_to_bottom_with_next_to_last_item
#     assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
#     ListMixin.find(3).move_to_bottom
#     assert_equal [1, 2, 4, 3], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
#   end
# 
#   def test_next_prev
#     assert_equal ListMixin.find(2), ListMixin.find(1).lower_item
#     assert_nil ListMixin.find(1).higher_item
#     assert_equal ListMixin.find(3), ListMixin.find(4).higher_item
#     assert_nil ListMixin.find(4).lower_item
#   end
# 
#   def test_injection
#     item = ListMixin.new(:parent_id => 1)
#     assert_equal "parent_id = 1", item.scope_condition
#     assert_equal "pos", item.position_column
#   end
# 
#   def test_insert
#     new = ListMixin.create(:parent_id => 20)
#     assert_equal 1, new.pos
#     assert new.first?
#     assert new.last?
# 
#     new = ListMixin.create(:parent_id => 20)
#     assert_equal 2, new.pos
#     assert !new.first?
#     assert new.last?
# 
#     new = ListMixin.create(:parent_id => 20)
#     assert_equal 3, new.pos
#     assert !new.first?
#     assert new.last?
# 
#     new = ListMixin.create(:parent_id => 0)
#     assert_equal 1, new.pos
#     assert new.first?
#     assert new.last?
#   end
# 
#   def test_insert_at
#     new = ListMixin.create(:parent_id => 20)
#     assert_equal 1, new.pos
# 
#     new = ListMixin.create(:parent_id => 20)
#     assert_equal 2, new.pos
# 
#     new = ListMixin.create(:parent_id => 20)
#     assert_equal 3, new.pos
# 
#     new4 = ListMixin.create(:parent_id => 20)
#     assert_equal 4, new4.pos
# 
#     new4.insert_at(3)
#     assert_equal 3, new4.pos
# 
#     new.reload
#     assert_equal 4, new.pos
# 
#     new.insert_at(2)
#     assert_equal 2, new.pos
# 
#     new4.reload
#     assert_equal 4, new4.pos
# 
#     new5 = ListMixin.create(:parent_id => 20)
#     assert_equal 5, new5.pos
# 
#     new5.insert_at(1)
#     assert_equal 1, new5.pos
# 
#     new4.reload
#     assert_equal 5, new4.pos
#   end
# 
#   def test_delete_middle
#     assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
# 
#     ListMixin.find(2).destroy
# 
#     assert_equal [1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
# 
#     assert_equal 1, ListMixin.find(1).pos
#     assert_equal 2, ListMixin.find(3).pos
#     assert_equal 3, ListMixin.find(4).pos
# 
#     ListMixin.find(1).destroy
# 
#     assert_equal [3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
# 
#     assert_equal 1, ListMixin.find(3).pos
#     assert_equal 2, ListMixin.find(4).pos
#   end
# 
#   def test_with_string_based_scope
#     new = ListWithStringScopeMixin.create(:parent_id => 500)
#     assert_equal 1, new.pos
#     assert new.first?
#     assert new.last?
#   end
# 
#   def test_nil_scope
#     new1, new2, new3 = ListMixin.create, ListMixin.create, ListMixin.create
#     new2.move_higher
#     assert_equal [new2, new1, new3], ListMixin.find(:all, :conditions => 'parent_id IS NULL', :order => 'pos')
#   end
#   
#   
#   def test_remove_from_list_should_then_fail_in_list? 
#     assert_equal true, ListMixin.find(1).in_list?
#     ListMixin.find(1).remove_from_list
#     assert_equal false, ListMixin.find(1).in_list?
#   end 
#   
#   def test_remove_from_list_should_set_position_to_nil 
#     assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
#   
#     ListMixin.find(2).remove_from_list 
#   
#     assert_equal [2, 1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
#   
#     assert_equal 1,   ListMixin.find(1).pos
#     assert_equal nil, ListMixin.find(2).pos
#     assert_equal 2,   ListMixin.find(3).pos
#     assert_equal 3,   ListMixin.find(4).pos
#   end 
#   
#   def test_remove_before_destroy_does_not_shift_lower_items_twice 
#     assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
#   
#     ListMixin.find(2).remove_from_list 
#     ListMixin.find(2).destroy 
#   
#     assert_equal [1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
#   
#     assert_equal 1, ListMixin.find(1).pos
#     assert_equal 2, ListMixin.find(3).pos
#     assert_equal 3, ListMixin.find(4).pos
#   end 
#   
# end
# 
# class ListSubTest < Test::Unit::TestCase
# 
#   def setup
#     setup_db
#     (1..4).each { |i| ((i % 2 == 1) ? ListMixinSub1 : ListMixinSub2).create! :pos => i, :parent_id => 5000 }
#   end
# 
#   def teardown
#     teardown_db
#   end
# 
#   def test_reordering
#     assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
# 
#     ListMixin.find(2).move_lower
#     assert_equal [1, 3, 2, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
# 
#     ListMixin.find(2).move_higher
#     assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
# 
#     ListMixin.find(1).move_to_bottom
#     assert_equal [2, 3, 4, 1], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
# 
#     ListMixin.find(1).move_to_top
#     assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
# 
#     ListMixin.find(2).move_to_bottom
#     assert_equal [1, 3, 4, 2], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
# 
#     ListMixin.find(4).move_to_top
#     assert_equal [4, 1, 3, 2], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
#   end
# 
#   def test_move_to_bottom_with_next_to_last_item
#     assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
#     ListMixin.find(3).move_to_bottom
#     assert_equal [1, 2, 4, 3], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
#   end
# 
#   def test_next_prev
#     assert_equal ListMixin.find(2), ListMixin.find(1).lower_item
#     assert_nil ListMixin.find(1).higher_item
#     assert_equal ListMixin.find(3), ListMixin.find(4).higher_item
#     assert_nil ListMixin.find(4).lower_item
#   end
# 
#   def test_injection
#     item = ListMixin.new("parent_id"=>1)
#     assert_equal "parent_id = 1", item.scope_condition
#     assert_equal "pos", item.position_column
#   end
# 
#   def test_insert_at
#     new = ListMixin.create("parent_id" => 20)
#     assert_equal 1, new.pos
# 
#     new = ListMixinSub1.create("parent_id" => 20)
#     assert_equal 2, new.pos
# 
#     new = ListMixinSub2.create("parent_id" => 20)
#     assert_equal 3, new.pos
# 
#     new4 = ListMixin.create("parent_id" => 20)
#     assert_equal 4, new4.pos
# 
#     new4.insert_at(3)
#     assert_equal 3, new4.pos
# 
#     new.reload
#     assert_equal 4, new.pos
# 
#     new.insert_at(2)
#     assert_equal 2, new.pos
# 
#     new4.reload
#     assert_equal 4, new4.pos
# 
#     new5 = ListMixinSub1.create("parent_id" => 20)
#     assert_equal 5, new5.pos
# 
#     new5.insert_at(1)
#     assert_equal 1, new5.pos
# 
#     new4.reload
#     assert_equal 5, new4.pos
#   end
# 
#   def test_delete_middle
#     assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
# 
#     ListMixin.find(2).destroy
# 
#     assert_equal [1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
# 
#     assert_equal 1, ListMixin.find(1).pos
#     assert_equal 2, ListMixin.find(3).pos
#     assert_equal 3, ListMixin.find(4).pos
# 
#     ListMixin.find(1).destroy
# 
#     assert_equal [3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
# 
#     assert_equal 1, ListMixin.find(3).pos
#     assert_equal 2, ListMixin.find(4).pos
#   end

end
