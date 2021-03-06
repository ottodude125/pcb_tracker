########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: change_class_test.rb
#
# This file contains the unit tests for the change class model
#
# Revision History:
#   $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ ) 

class ChangeClassTest < ActiveSupport::TestCase
  
  def setup
    @change_class_1 = change_classes(:change_class_1)
    @change_class_2 = change_classes(:change_class_2)
  end
  
  
  ######################################################################
  def test_presence_of_name_on_create
    expected_error_message = 'can not be blank'
    change_class = ChangeClass.new( :name       => '',
                                    :position   => 1,
                                    :active     => false,
                                    :definition => 'Testing empty name')
    change_class.save
    assert_equal(1, change_class.errors.count)
    assert_equal(expected_error_message, change_class.errors[:name][0])
    
    # Retry with blanks
    change_class.name = '  '
    change_class.save
    assert_equal(1, change_class.errors.count)
    assert_equal(expected_error_message, change_class.errors[:name][0])
    
    # Retry with tabs
    change_class.name = "\t\t"
    change_class.save
    assert_equal(1, change_class.errors.count)
    assert_equal(expected_error_message, change_class.errors[:name][0])
  end
  
  
  ######################################################################
  def test_presence_of_name_on_update
    expected_error_message = 'can not be blank'
    change_class = ChangeClass.find(:first)
    change_class.name = ''
    change_class.save
    assert_equal(1, change_class.errors.count)
    assert_equal(expected_error_message, change_class.errors[:name][0])
    
    # Retry with blanks
    change_class.name = '  '
    change_class.save
    assert_equal(1, change_class.errors.count)
    assert_equal(expected_error_message, change_class.errors[:name][0])
    
    # Retry with tabs
    change_class.name = "\t\t"
    change_class.save
    assert_equal(1, change_class.errors.count)
    assert_equal(expected_error_message, change_class.errors[:name][0])
  end
  
  
  ######################################################################
  def test_add_first_change_class
    
    # Clear out the change class table to add the first change class
    empty_change_class_table
    
    change_class = ChangeClass.new( :name       => 'First Class',
                                    :position   => 1,
                                    :active     => false,
                                    :definition => 'Added to an empty list')
                                  
    change_class.add_to_list
    change_class.reload
    
    assert_equal(1,                        ChangeClass.count)
    assert_equal('First Class',            change_class.name)
    assert_equal(1,                        change_class.position)
    assert_equal(false,                    change_class.active)
    assert_equal('Added to an empty list', change_class.definition)
    
  end


  ######################################################################
  def test_add_to_end
    
    change_class = ChangeClass.new( :name       => 'New Class',
                                    :position   => 4,
                                    :active     => true,
                                    :definition => 'Tack on to end')
    change_class.add_to_list
    change_class.reload

    assert_equal(4,                ChangeClass.count)
    assert_equal('New Class',      change_class.name)
    assert_equal(4,                change_class.position)
    assert_equal(true,             change_class.active)
    assert_equal('Tack on to end', change_class.definition)
    
  end


  ######################################################################
  def test_insert_in_the_middle
    
    change_class = ChangeClass.new( :name       => 'New Class',
                                    :position   => 2,
                                    :active     => true,
                                    :definition => 'Insert in the middle')
    change_class.add_to_list
    change_class.reload

    assert_equal(4,                      ChangeClass.count)
    assert_equal('New Class',            change_class.name)
    assert_equal(2,                      change_class.position)
    assert_equal(true,                   change_class.active)
    assert_equal('Insert in the middle', change_class.definition)
    
    @change_class_1.reload
    @change_class_2.reload
    assert_equal(1, @change_class_1.position)
    assert_equal(3, @change_class_2.position)
    
  end
  
  
  ######################################################################
  def test_insert_at_the_beginning
    
    change_class = ChangeClass.new( :name       => 'New Class',
                                    :position   => 1,
                                    :active     => true,
                                    :definition => 'New First')
    change_class.add_to_list
    change_class.reload

    assert_equal(4,           ChangeClass.count)
    assert_equal('New Class', change_class.name)
    assert_equal(1,           change_class.position)
    assert_equal(true,        change_class.active)
    assert_equal('New First', change_class.definition)
    
    @change_class_1.reload
    @change_class_2.reload
    assert_equal(2, @change_class_1.position)
    assert_equal(3, @change_class_2.position)
    
  end
  
  
  ######################################################################
  def test_move_to_the_beginning
    
    update = { :name       => @change_class_2.name,
               :position   => 1,
               :active     => @change_class_2.active,
               :definition => @change_class_2.definition }
    @change_class_2.update_list(update)

    @change_class_1.reload
    @change_class_2.reload
    assert_equal(2, @change_class_1.position)
    assert_equal(1, @change_class_2.position)
    
  end
  
  
  ######################################################################
  def test_move_to_the_end
    
    update = { :name       => @change_class_1.name,
               :position   => 2,
               :active     => @change_class_1.active,
               :definition => @change_class_1.definition }
    @change_class_1.update_list(update)

    @change_class_1.reload
    @change_class_2.reload
    assert_equal(2, @change_class_1.position)
    assert_equal(1, @change_class_2.position)
    
  end
  
  
  ######################################################################
  def test_update
    
    update = { :name       => @change_class_1.name + ' Update',
               :position   => 1,
               :active     => !@change_class_1.active,
               :definition => @change_class_1.definition + ' Update' }
    @change_class_1.update_list(update)
    
    @change_class_1.reload
    @change_class_2.reload
    assert_equal('Class 1 Update',                   @change_class_1.name)
    assert_equal(1,                                  @change_class_1.position)
    assert_equal('Describes the first class Update', @change_class_1.definition)
    assert(!@change_class_1.active)
    assert_equal(2,                @change_class_2.position)


  end
  
  
  ######################################################################
  def test_get_active_change_types
    all_types      = @change_class_1.change_types.find(:all)
    active_types   = @change_class_1.get_active_change_types
    inactive_types = all_types - active_types
    
    inactive_types.each { |change_type| assert(!change_type.active?) }
   
    pos = 0
    active_types.each do |change_type|
      assert(change_type.active)
      assert(change_type.position > pos)
      pos = change_type.position
    end
    
  end

  
private 

  
  def empty_change_class_table
    ChangeClass.delete_all
    assert_equal(0, ChangeClass.count)
  end
  
  
end
