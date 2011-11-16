module Coroutine                    #:nodoc:
  module ActsAsList                 #:nodoc:
    module Base                     #:nodoc:
      
      def self.included(base)
        base.extend(ClassMethods)
      end

      
      module ClassMethods
        
        # = Description
        #
        # This +acts_as+ extension provides the capabilities for sorting and reordering a number of objects in a list.
        # The class that has this specified needs to have a +position+ column defined as an integer on
        # the mapped database table.
        #
        #
        # = Usage
        #
        #   class TodoList < ActiveRecord::Base
        #     has_many :todo_items, :order => "position"
        #   end
        #
        #   class TodoItem < ActiveRecord::Base
        #     belongs_to :todo_list
        #     acts_as_list :scope => :todo_list
        #   end
        #
        #   todo_list.first.move_to_bottom
        #   todo_list.last.move_higher
        #
        #
        # = Configuration
        #
        # * +column+ - specifies the column name to use for keeping the position integer (default: +position+)
        # * +scope+ - restricts what is to be considered a list. Given a symbol, it'll attach <tt>_id</tt> 
        #   (if it hasn't already been added) and use that as the foreign key restriction. It's also possible 
        #   to give it an entire string that is interpolated if you need a tighter scope than just a foreign key.
        #   Example: <tt>acts_as_list :scope => 'todo_list_id = #{todo_list_id} AND completed = 0'</tt>
        #
        def acts_as_list(options = {})
          
          #-------------------------------------------
          # scrub options
          #-------------------------------------------
          options       = {} if !options.is_a?(Hash)
          column        = options.key?(:column) ? options[:column]  : :position
          scope         = options.key?(:scope)  ? options[:scope]   : "1 = 1"
                    

          #--------------------------------------------
          # mix methods into class definition
          #--------------------------------------------
          class_eval do
            
            # define attributes
            class_attribute :acts_as_list_column
            class_attribute :acts_as_list_scope
            class_attribute :acts_as_list_default_scope
            class_attribute :acts_as_list_scope_condition
            
            # set values from options
            self.acts_as_list_column          = column
            self.acts_as_list_scope           = scope
            self.acts_as_list_default_scope   = "1 = 1"
            self.acts_as_list_scope_condition = nil
            
            
            # validations (column is allowed to be nil to support soft deletes)
            validates_numericality_of   column, :only_integer => true, :greater_than => 0, :allow_nil => true
            
            
            # instance methods
            include Coroutine::ActsAsList::Base::InstanceMethods


            # callbacks
            before_validation   :add_to_list_bottom, :if => :position_blank?, :on => :create     
            before_destroy      :remove_from_list
              
          end
          
        end
         
      end


      # All the methods available to a record that has had <tt>acts_as_list</tt> specified. Each method works
      # by assuming the object to be the item in the list, so <tt>chapter.move_lower</tt> would move that chapter
      # lower in the list of all chapters. Likewise, <tt>chapter.first?</tt> would return +true+ if that chapter is
      # the first in the list of all chapters.
      #
      module InstanceMethods
        
        # This method returns the instance's class object
        #
        def acts_as_list_class
          self.class
        end
        
        # This method returns the column name that holds the position value.
        #
        def position_column
          acts_as_list_column
        end
        
        # This method returns the scope condition appropriate for the specified definition. (This 
        # could probably be refactored for brevity.)
        #
        def scope_condition
          if acts_as_list_scope_condition.nil?
            
            # if symbol, do convenience conversions
            if acts_as_list_scope.is_a?(Symbol)
              scope_as_sym  = acts_as_list_scope
              scope_as_str  = acts_as_list_scope.to_s
              if scope_as_str.nil?
                acts_as_list_scope_condition = "#{scope_as_str} IS NULL"
              else
                scope_with_id = scope_as_str + "_id"
                if scope_as_str !~ /_id$/ && acts_as_list_class.column_names.include?("#{scope_with_id}")
                  scope_as_sym = scope_with_id.to_sym
                  scope_as_str = scope_as_sym.to_s
                end
                acts_as_list_scope_condition = "#{scope_as_str} = \'#{self[scope_as_sym]}\'"
              end
            
            # if lambda, execute in scope of instance
            elsif acts_as_list_scope.is_a?(Proc)
              acts_as_list_scope_condition = acts_as_list_scope.call(self)
              
            # else, return string as is  
            else
             acts_as_list_scope_condition = !acts_as_list_scope.blank? ? acts_as_list_scope.to_s : acts_as_list_default_scope.to_s
            end
          end
          
          acts_as_list_scope_condition
        end
                
        # Insert the item at the given position (defaults to the top position of 1).
        def insert_at(position = 1)
          insert_at_position(position)
        end

        # Swap positions with the next lower item, if one exists.
        def move_lower
          return unless lower_item
          
          acts_as_list_class.transaction do
            lower_item.decrement_position
            increment_position
          end
        end

        # Swap positions with the next higher item, if one exists.
        def move_higher
          return unless higher_item

          acts_as_list_class.transaction do
            higher_item.increment_position
            decrement_position
          end
        end

        # Move to the bottom of the list. If the item is already in the list, the items below it have their
        # position adjusted accordingly.
        def move_to_bottom
          return unless in_list?
          acts_as_list_class.transaction do
            decrement_positions_on_lower_items
            assume_bottom_position
          end
        end

        # Move to the top of the list. If the item is already in the list, the items above it have their
        # position adjusted accordingly.
        def move_to_top
          return unless in_list?
          acts_as_list_class.transaction do
            increment_positions_on_higher_items
            assume_top_position
          end
        end

        # Removes the item from the list.
        def remove_from_list
          if in_list?
            decrement_positions_on_lower_items
            update_attribute position_column, nil
          end
        end

        # Increase the position of this item without adjusting the rest of the list.
        def increment_position
          return unless in_list?
          update_attribute position_column, self.send(position_column).to_i + 1
        end

        # Decrease the position of this item without adjusting the rest of the list.
        def decrement_position
          return unless in_list?
          update_attribute position_column, self.send(position_column).to_i - 1
        end

        # Return +true+ if this object is the first in the list.
        def first?
          return false unless in_list?
          self.send(position_column) == 1
        end

        # Return +true+ if this object is the last in the list.
        def last?
          return false unless in_list?
          self.send(position_column) == bottom_position_in_list
        end

        # Return the next higher item in the list.
        def higher_item
          return nil unless in_list?
          conditions = "#{scope_condition} AND #{position_column} = #{(send(position_column).to_i - 1).to_s}"
          
          acts_as_list_class.where(conditions).first
        end

        # This method returns the next lower item in the list.
        #
        def lower_item
          return nil unless in_list?
          conditions = "#{scope_condition} AND #{position_column} = #{(send(position_column).to_i + 1).to_s}"
          
          acts_as_list_class.where(conditions).first
        end

        # Test if this record is in a list
        def in_list?
          !send(position_column).nil?
        end

        # This returns whether or not the position column is blank.
        def position_blank?
          return self.send(position_column).blank?
        end
        
        
        
        private
          
          # This method adds the new item to the top of the list.
          def add_to_list_top
            increment_positions_on_all_items
          end

          # This method adds the new item to the bottom of the list.
          def add_to_list_bottom
            self[position_column] = bottom_position_in_list.to_i + 1
          end

          # This method returns the bottom position number in the list.
          def bottom_position_in_list(except = nil)
            item = bottom_item(except)
            item ? item.send(position_column) : 0
          end

          # This method returns the bottom item.
          def bottom_item(except = nil)
            conditions  = scope_condition
            conditions  = "#{conditions} AND #{self.class.primary_key} != #{except.id}" unless except.blank?
            order_by    = "#{position_column} DESC"
            
            acts_as_list_class.where(conditions).order(order_by).first
          end

          # This method forces item to assume the bottom position in the list.
          def assume_bottom_position
            update_attribute(position_column, bottom_position_in_list(self).to_i + 1)
          end

          # This method forces item to assume the top position in the list.
          def assume_top_position
            update_attribute(position_column, 1)
          end

          # This has the effect of moving all the higher items up one.
          def decrement_positions_on_higher_items(position)
            acts_as_list_class.update_all(
              "#{position_column} = (#{position_column} - 1)", "#{scope_condition} AND #{position_column} <= #{position}"
            )
          end

          # This has the effect of moving all the lower items up one.
          def decrement_positions_on_lower_items
            return unless in_list?
            acts_as_list_class.update_all(
              "#{position_column} = (#{position_column} - 1)", "#{scope_condition} AND #{position_column} > #{send(position_column).to_i}"
            )
          end

          # This has the effect of moving all the higher items down one.
          def increment_positions_on_higher_items
            return unless in_list?
            acts_as_list_class.update_all(
              "#{position_column} = (#{position_column} + 1)", "#{scope_condition} AND #{position_column} < #{send(position_column).to_i}"
            )
          end

          # This has the effect of moving all the lower items down one.
          def increment_positions_on_lower_items(position)
            acts_as_list_class.update_all(
              "#{position_column} = (#{position_column} + 1)", "#{scope_condition} AND #{position_column} >= #{position}"
           )
          end

          # Increments position (<tt>position_column</tt>) of all items in the list.
          def increment_positions_on_all_items
            acts_as_list_class.update_all(
              "#{position_column} = (#{position_column} + 1)",  "#{scope_condition}"
            )
          end

          # This adds the item at the specified position value.
          def insert_at_position(position)
            remove_from_list
            increment_positions_on_lower_items(position)
            self.update_attribute(position_column, position)
          end
          
      end 
    end
  end
end
