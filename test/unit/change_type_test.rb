########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: change_type_test.rb
#
# This file contains the unit tests for the change type model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class ChangeTypeTest < ActiveSupport::TestCase
  
  fixtures :change_classes,
           :change_types
  
  
  def setup
    @change_class_2    = change_classes(:change_class_2)
    @change_type_1_1   = change_types(:change_type_1_1)
    @change_type_2_1   = change_types(:change_type_2_1)
    @change_type_2_2   = change_types(:change_type_2_2)
    @change_type_count = ChangeType.count
  end
  
  
  ######################################################################
  def test_presence_of_name_on_create
    expected_error_message = 'can not be blank'
    change_type = ChangeType.new( :name       => '',
                                  :position   => 1,
                                  :active     => false,
                                  :definition => 'Testing empty name')
    change_type.save
    assert_equal(1, change_type.errors.count)
    assert_equal(expected_error_message, change_type.errors.on(:name))
    
    # Retry with blanks
    change_type.name = '  '
    change_type.save
    assert_equal(1, change_type.errors.count)
    assert_equal(expected_error_message, change_type.errors.on(:name))
    
    # Retry with tabs
    change_type.name = "\t\t"
    change_type.save
    assert_equal(1, change_type.errors.count)
    assert_equal(expected_error_message, change_type.errors.on(:name))
  end
  
  
  ######################################################################
  def test_presence_of_name_on_update
    expected_error_message = 'can not be blank'
    change_type = ChangeType.find(:first)
    change_type.name = ''
    change_type.save
    assert_equal(1, change_type.errors.count)
    assert_equal(expected_error_message, change_type.errors.on(:name))
    
    # Retry with blanks
    change_type.name = '  '
    change_type.save
    assert_equal(1, change_type.errors.count)
    assert_equal(expected_error_message, change_type.errors.on(:name))
    
    # Retry with tabs
    change_type.name = "\t\t"
    change_type.save
    assert_equal(1, change_type.errors.count)
    assert_equal(expected_error_message, change_type.errors.on(:name))
  end
  
  
  ######################################################################
  def test_add_first_change_type
    
    # Clear out the change type table to add the first change type
    empty_change_type_table
    
    change_class_type_count = @change_class_2.change_types.size
    change_type = ChangeType.new( :name            => 'First Type',
                                  :position        => 1,
                                  :change_class_id => @change_class_2.id,
                                  :active          => false,
                                  :definition      => 'Added to an empty list')
                                  
    change_type.add_to_list
    change_type.reload
    @change_class_2.reload
    
    assert_equal(1,                        ChangeType.count)
    assert_equal(change_class_type_count + 1, @change_class_2.change_types.size)
    assert_equal('First Type',             change_type.name)
    assert_equal(1,                        change_type.position)
    assert_equal(false,                    change_type.active)
    assert_equal(@change_class_2.id,       change_type.change_class_id)
    assert_equal('Added to an empty list', change_type.definition)
    
  end


  ######################################################################
  def test_add_to_end
    
    change_class_type_count = @change_class_2.change_types.size
    change_type = ChangeType.new( :name            => 'New Type',
                                  :position        => 3,
                                  :change_class_id => @change_class_2.id,
                                  :active          => true,
                                  :definition      => 'Tack on to end')
    change_type.add_to_list
    change_type.reload
    @change_class_2.reload

    assert_equal(@change_type_count + 1,      ChangeType.count)
    assert_equal(change_class_type_count + 1, @change_class_2.change_types.size)
    assert_equal('New Type',                  change_type.name)
    assert_equal(3,                           change_type.position)
    assert_equal(true,                        change_type.active)
    assert_equal(@change_class_2.id,          change_type.change_class_id)
    assert_equal('Tack on to end',            change_type.definition)
    
  end


  ######################################################################
  def test_insert_in_the_middle
    
    change_class_type_count = @change_class_2.change_types.size
    change_type = ChangeType.new( :name            => 'New Type',
                                  :position        => 2,
                                  :change_class_id => @change_class_2.id,
                                  :active          => true,
                                  :definition      => 'Insert in the middle')
    change_type.add_to_list
    change_type.reload
    @change_class_2.reload

    assert_equal(@change_type_count + 1,      ChangeType.count)
    assert_equal(change_class_type_count + 1, @change_class_2.change_types.size)
    assert_equal('New Type',                  change_type.name)
    assert_equal(2,                           change_type.position)
    assert_equal(true,                        change_type.active)
    assert_equal('Insert in the middle',      change_type.definition)
    
    @change_type_2_1.reload
    @change_type_2_2.reload
    assert_equal(1, @change_type_2_1.position)
    assert_equal(3, @change_type_2_2.position)
    
  end
  
  
  ######################################################################
  def test_insert_at_the_beginning
    
    change_class_type_count = @change_class_2.change_types.size
    change_type = ChangeType.new( :name            => 'New Type',
                                  :position        => 1,
                                  :change_class_id => @change_class_2.id,
                                  :active     => true,
                                  :definition => 'New First')
    change_type.add_to_list
    change_type.reload
    @change_class_2.reload

    assert_equal(@change_type_count + 1,      ChangeType.count)
    assert_equal(change_class_type_count + 1, @change_class_2.change_types.size)
    assert_equal('New Type',                  change_type.name)
    assert_equal(1,                           change_type.position)
    assert_equal(true,                        change_type.active)
    assert_equal('New First',                 change_type.definition)
    
    @change_type_2_1.reload
    @change_type_2_2.reload
    assert_equal(2, @change_type_2_1.position)
    assert_equal(3, @change_type_2_2.position)
    
  end
  
  
  ######################################################################
  def test_move_to_the_beginning
    
    @change_type_2_2.update_list({ :name            => @change_type_2_2.name,
                                   :position        => 1,
                                   :change_class_id => @change_type_2_2.change_class_id,
                                   :active          => @change_type_2_2.active,
                                   :definition      => @change_type_2_2.definition })

    @change_type_2_1.reload
    @change_type_2_2.reload
    assert_equal(2, @change_type_2_1.position)
    assert_equal(1, @change_type_2_2.position)
    
  end
  
  
  ######################################################################
  def test_move_to_the_end
    
    @change_type_2_1.update_list({ :name            => @change_type_2_2.name,
                                   :position        => 2,
                                   :change_class_id => @change_type_2_2.change_class_id,
                                   :active          => @change_type_2_2.active,
                                   :definition      => @change_type_2_2.definition })

    @change_type_2_1.reload
    @change_type_2_2.reload
    assert_equal(2, @change_type_2_1.position)
    assert_equal(1, @change_type_2_2.position)
    
  end
  
  
  ######################################################################
  def test_update
    
    @change_type_2_1.update_list({ :name            => @change_type_2_1.name + ' Update',
                                   :position        => 1,
                                   :change_class_id => @change_type_2_1.change_class_id,
                                   :active          => !@change_type_2_1.active,
                                   :definition     =>  @change_type_2_1.definition + ' Update' })
    
    @change_type_2_1.reload
    @change_type_2_2.reload
    assert_equal('Class 2, Type 1 Update',                    @change_type_2_1.name)
    assert_equal(1,                                           @change_type_2_1.position)
    assert_equal('Describes the first type (class 2) Update', @change_type_2_1.definition)
    assert(!@change_type_2_1.active)
    assert_equal(2, @change_type_2_2.position)


  end

  
  ######################################################################
  def test_get_active_change_items
    all_items      = @change_type_1_1.change_items.find(:all)
    active_items   = @change_type_1_1.get_active_change_items
    inactive_items = all_items - active_items
    
    inactive_items.each { |change_item| assert(!change_item.active?) }
   
    pos = 0
    active_items.each do |change_item|
      assert(change_item.active)
      assert(change_item.position > pos)
      pos = change_item.position
    end
    
  end

  
private 

  
  def empty_change_type_table
    ChangeType.delete_all
    assert_equal(0, ChangeType.count)
  end
  
  
end
