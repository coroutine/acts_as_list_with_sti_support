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
    create_table :contacts do |t|
      t.string  :name
      
      t.timestamps
    end
    
    create_table :emails do |t|
      t.integer :contact_id
      t.string  :address
      t.integer :pos
      
      t.timestamps
    end
    
    create_table :phones do |t|
      t.integer :contact_id
      t.string  :number
      t.integer :position
      
      t.timestamps
    end
    
    create_table :websites do |t|
      t.integer :contact_id
      t.string  :address
      t.integer :position
      
      t.timestamps
    end
    
    create_table :labels do |t|
      t.string  :type
      t.string  :label
      t.integer :position
      
      t.timestamps
    end
    
    Contact.create!({ :name => "John Dugan" })
    Contact.create!({ :name => "Tim Lowrimore" })
    
    Email.create!({ :contact_id => Contact.first.id, :address => "jdugan@coroutine.com" })
    Email.create!({ :contact_id => Contact.first.id, :address => "jdugan@example.com" })
    Email.create!({ :contact_id => Contact.last.id,  :address => "tlowrimore@coroutine.com" })
    Email.create!({ :contact_id => Contact.last.id,  :address => "tlowrimore@example.com" })
    
    Phone.create!({ :contact_id => Contact.first.id, :number => "901.555.1111" })
    Phone.create!({ :contact_id => Contact.first.id, :number => "901.555.2222" })
    Phone.create!({ :contact_id => Contact.first.id, :number => "901.555.3333" })
    Phone.create!({ :contact_id => Contact.first.id, :number => "901.555.4444" })
    Phone.create!({ :contact_id => Contact.last.id,  :number => "901.555.5555" })
    Phone.create!({ :contact_id => Contact.last.id,  :number => "901.555.6666" })
    
    Website.create!({ :contact_id => Contact.first.id, :address => "http://coroutine.com" })
    Website.create!({ :contact_id => Contact.first.id, :address => "http://johndugan.me" })
    Website.create!({ :contact_id => Contact.last.id,  :address => "http://coroutine.com" })
    Website.create!({ :contact_id => Contact.last.id,  :address => "http://timlowrimore.me" })
    
    BillingFrequency.create({ :label => "Weekly" })
    BillingFrequency.create({ :label => "Monthly" })
    BillingFrequency.create({ :label => "Quarterly" })
    BillingFrequency.create({ :label => "Yearly" })
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

# Contacts
class Contact < ActiveRecord::Base
  has_many :emails
  has_many :phones
  has_many :websites
  
  def email_ids
    self.emails(true).map(&:id)
  end
  def phone_ids
    self.phones(true).map(&:id)
  end
  def website_ids
    self.websites(true).map(&:id)
  end
end


# Emails
class Email < ActiveRecord::Base
  belongs_to :contact
  
  acts_as_list :column => :pos, :scope => :contact
end


# Phones
class Phone < ActiveRecord::Base
  belongs_to :contact
  
  acts_as_list :scope => :contact_id
end


# Websites
class Website < ActiveRecord::Base
  belongs_to :contact
  
  acts_as_list :scope => lambda { |instance| "contact_id = '#{instance.contact_id}'" }
end


# Labels (STI Base)
class Label < ActiveRecord::Base
  acts_as_list
end


# Billing Frequency (STI extension)
class BillingFrequency < Label
  def self.ids
    BillingFrequency.find(:all, :order => :position).map(&:id)
  end
end


# Tax Frequency (STI extension)
class TaxFrequency < Label
end


# Payment Frequency (STI extension)
class PaymentFrequency < Label
end



#---------------------------------------------------------
# Standard Tests
#---------------------------------------------------------

class ActsAsListTest < Test::Unit::TestCase

  
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
  
  def test_validations
    
    # get valid record
    record = BillingFrequency.first
    assert record.valid?
    
    # position can be null
    record.position = nil               
    assert record.valid?
    
    # position cannot be string
    record.position = "one"               
    assert !record.valid?
    
    # position cannot be decimal
    record.position = 2.25               
    assert !record.valid?
    
    # position cannot be less than 1
    record.position = -2              
    assert !record.valid?
    
  end
  
  
  #---------------------------------------------
  # test class references
  #---------------------------------------------
  
  def test_acts_as_list_class
    
    # standard class
    record = Email.first
    assert_equal record.acts_as_list_class, Email
    
    # sti class
    record = BillingFrequency.first
    assert_equal record.acts_as_list_class, BillingFrequency
    
  end
  
  
  #---------------------------------------------
  # test position columns
  #---------------------------------------------
  
  def test_position_columns
    
    # override name
    record = Email.first
    assert_equal record.position_column, :pos
    
    # standard name
    record = Phone.first
    assert_equal record.position_column, :position
    
    # standard name (sti)
    record = BillingFrequency.first
    assert_equal record.position_column, :position
    
  end
  
  
  #---------------------------------------------
  # test scope conditions
  #---------------------------------------------
  
  def test_scope_conditions
    
    # implicit _id
    record = Email.first
    assert_equal record.scope_condition, "contact_id = '#{record.contact_id}'"
    
    # explicit _id
    record = Phone.first
    assert_equal record.scope_condition, "contact_id = '#{record.contact_id}'"
    
    # explicit string
    record = Website.first
    assert_equal record.scope_condition, "contact_id = '#{record.contact_id}'"
    
    # sti
    record = BillingFrequency.first
    assert_equal record.scope_condition, "1 = 1"
    
  end
  
  
  
  #---------------------------------------------
  # test ordering methods
  #---------------------------------------------
  
  def test_reordering
    
    # standard model
    contact = Contact.first
    assert_equal [1, 2, 3, 4], contact.phone_ids

    Phone.find(2).move_lower
    assert_equal [1, 3, 2, 4], contact.phone_ids

    Phone.find(2).move_higher
    assert_equal [1, 2, 3, 4], contact.phone_ids

    Phone.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], contact.phone_ids

    Phone.find(1).move_to_top
    assert_equal [1, 2, 3, 4], contact.phone_ids

    Phone.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], contact.phone_ids

    Phone.find(4).move_to_top
    assert_equal [4, 1, 3, 2], contact.phone_ids
    
    
    # sti model
    assert_equal [1, 2, 3, 4], BillingFrequency.ids

    BillingFrequency.find(2).move_lower
    assert_equal [1, 3, 2, 4], BillingFrequency.ids

    BillingFrequency.find(2).move_higher
    assert_equal [1, 2, 3, 4], BillingFrequency.ids

    BillingFrequency.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], BillingFrequency.ids

    BillingFrequency.find(1).move_to_top
    assert_equal [1, 2, 3, 4], BillingFrequency.ids

    BillingFrequency.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], BillingFrequency.ids

    BillingFrequency.find(4).move_to_top
    assert_equal [4, 1, 3, 2], BillingFrequency.ids
  end


  def test_move_to_bottom_with_next_to_last_item

    # standard model
    contact = Contact.first
    assert_equal [1, 2, 3, 4], contact.phone_ids
    
    Phone.find(3).move_to_bottom
    assert_equal [1, 2, 4, 3], contact.phone_ids
    
    
    # sti model
    assert_equal [1, 2, 3, 4], BillingFrequency.ids
    
    BillingFrequency.find(3).move_to_bottom
    assert_equal [1, 2, 4, 3], BillingFrequency.ids
  end
  
  
  def test_next_prev
   
    # standard model
    assert_equal Phone.find(2), Phone.find(1).lower_item
    assert_nil Phone.find(1).higher_item
    assert_equal Phone.find(3), Phone.find(4).higher_item
    assert_nil Phone.find(4).lower_item
    
    # sti model
    assert_equal BillingFrequency.find(2), BillingFrequency.find(1).lower_item
    assert_nil BillingFrequency.find(1).higher_item
    assert_equal BillingFrequency.find(3), BillingFrequency.find(4).higher_item
    assert_nil BillingFrequency.find(4).lower_item
  end
 
 
  def test_insert
    
    # standard model
    new = Phone.create(:contact_id => 3, :number => "901.555.7777")
    assert_equal 1, new.position
    assert new.first?
    assert new.last?

    new = Phone.create(:contact_id => 3, :number => "901.555.8888")
    assert_equal 2, new.position
    assert !new.first?
    assert new.last?

    new = Phone.create(:contact_id => 3, :number => "901.555.9999")
    assert_equal 3, new.position
    assert !new.first?
    assert new.last?

    new = Phone.create(:contact_id => 4, :number => "901.555.0000")
    assert_equal 1, new.position
    assert new.first?
    assert new.last?
    
    
    # sti model
    new = TaxFrequency.create(:label => "Monthly")
    assert_equal 1, new.position
    assert new.first?
    assert new.last?

    new = TaxFrequency.create(:label => "Quarterly")
    assert_equal 2, new.position
    assert !new.first?
    assert new.last?

    new = TaxFrequency.create(:label => "Yearly")
    assert_equal 3, new.position
    assert !new.first?
    assert new.last?

    new = PaymentFrequency.create(:label => "Monthly")
    assert_equal 1, new.position
    assert new.first?
    assert new.last?
  end
  
  
  def test_insert_at
    
    # stadard model
    new = Phone.create(:contact_id => 3, :number => "615.555.1111")
    assert_equal 1, new.position

    new = Phone.create(:contact_id => 3, :number => "615.555.2222")
    assert_equal 2, new.position

    new = Phone.create(:contact_id => 3, :number => "615.555.3333")
    assert_equal 3, new.position

    new4 = Phone.create(:contact_id => 3, :number => "615.555.4444")
    assert_equal 4, new4.position

    new4.insert_at(3)
    assert_equal 3, new4.position

    new.reload
    assert_equal 4, new.position

    new.insert_at(2)
    assert_equal 2, new.position

    new4.reload
    assert_equal 4, new4.position

    new5 = Phone.create(:contact_id => 3, :number => "615.555.5555")
    assert_equal 5, new5.position

    new5.insert_at(1)
    assert_equal 1, new5.position

    new4.reload
    assert_equal 5, new4.position
    
    
    # sti model
    new = TaxFrequency.create(:label => "Weekly")
    assert_equal 1, new.position

    new = TaxFrequency.create(:label => "Monthly")
    assert_equal 2, new.position

    new = TaxFrequency.create(:label => "Quarterly")
    assert_equal 3, new.position

    new4 = TaxFrequency.create(:label => "Yearly")
    assert_equal 4, new4.position

    new4.insert_at(3)
    assert_equal 3, new4.position

    new.reload
    assert_equal 4, new.position

    new.insert_at(2)
    assert_equal 2, new.position

    new4.reload
    assert_equal 4, new4.position

    new5 = TaxFrequency.create(:label => "Daily")
    assert_equal 5, new5.position

    new5.insert_at(1)
    assert_equal 1, new5.position

    new4.reload
    assert_equal 5, new4.position
  end


  def test_delete_middle
    
    # standard model
    contact = Contact.first
    assert_equal [1, 2, 3, 4], contact.phone_ids

    Phone.find(2).destroy
    assert_equal [1, 3, 4], contact.phone_ids

    assert_equal 1, Phone.find(1).position
    assert_equal 2, Phone.find(3).position
    assert_equal 3, Phone.find(4).position

    Phone.find(1).destroy
    assert_equal [3, 4], contact.phone_ids

    assert_equal 1, Phone.find(3).position
    assert_equal 2, Phone.find(4).position
    
    
    # sti model
    assert_equal [1, 2, 3, 4], BillingFrequency.ids

    BillingFrequency.find(2).destroy
    assert_equal [1, 3, 4], BillingFrequency.ids

    assert_equal 1, BillingFrequency.find(1).position
    assert_equal 2, BillingFrequency.find(3).position
    assert_equal 3, BillingFrequency.find(4).position

    BillingFrequency.find(1).destroy
    assert_equal [3, 4], BillingFrequency.ids

    assert_equal 1, BillingFrequency.find(3).position
    assert_equal 2, BillingFrequency.find(4).position
  end


  def test_remove_from_list_should_then_fail_in_list? 
    
    # standard model
    assert_equal true, Phone.find(1).in_list?
    
    Phone.find(1).remove_from_list
    assert_equal false, Phone.find(1).in_list?
    
    
    # sti model
    assert_equal true, BillingFrequency.find(1).in_list?
    
    BillingFrequency.find(1).remove_from_list
    assert_equal false, BillingFrequency.find(1).in_list?
  end 

   
  def test_remove_from_list_should_set_position_to_nil 
    
    # standard model
    contact = Contact.first
    assert_equal [1, 2, 3, 4], contact.phone_ids
  
    Phone.find(2).remove_from_list 
    assert_equal [2, 1, 3, 4], contact.phone_ids
  
    assert_equal 1,   Phone.find(1).position
    assert_equal nil, Phone.find(2).position
    assert_equal 2,   Phone.find(3).position
    assert_equal 3,   Phone.find(4).position
    
    
    # sti model
    assert_equal [1, 2, 3, 4], BillingFrequency.ids
  
    BillingFrequency.find(2).remove_from_list 
    assert_equal [2, 1, 3, 4], BillingFrequency.ids
  
    assert_equal 1,   BillingFrequency.find(1).position
    assert_equal nil, BillingFrequency.find(2).position
    assert_equal 2,   BillingFrequency.find(3).position
    assert_equal 3,   BillingFrequency.find(4).position
  end 


  def test_remove_before_destroy_does_not_shift_lower_items_twice 
    
    # standard model
    contact = Contact.first
    assert_equal [1, 2, 3, 4], contact.phone_ids
  
    Phone.find(2).remove_from_list 
    Phone.find(2).destroy 
    assert_equal [1, 3, 4], contact.phone_ids
  
    assert_equal 1, Phone.find(1).position
    assert_equal 2, Phone.find(3).position
    assert_equal 3, Phone.find(4).position
    
    
    # sti model
    assert_equal [1, 2, 3, 4], BillingFrequency.ids
  
    BillingFrequency.find(2).remove_from_list 
    BillingFrequency.find(2).destroy 
    assert_equal [1, 3, 4], BillingFrequency.ids
  
    assert_equal 1, BillingFrequency.find(1).position
    assert_equal 2, BillingFrequency.find(3).position
    assert_equal 3, BillingFrequency.find(4).position
  end
  
end