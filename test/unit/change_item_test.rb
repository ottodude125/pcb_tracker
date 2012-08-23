########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: change_item_test.rb
#
# This file contains the unit tests for the change item model
#
# Revision History:
#   $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ ) 

class ChangeItemsTest < ActiveSupport::TestCase
  
  def setup
    @change_type_2_2   = change_types(:change_type_2_2)
    @change_item_2_2_1 = change_items(:change_item_2_2_1)
    @change_item_2_2_2 = change_items(:change_item_2_2_2)
    @change_item_1_1_3 = change_items(:change_item_1_1_3)
    @change_item_count = ChangeItem.count
  end
  
  
  ######################################################################
  def test_presence_of_name_on_create
    expected_error_message = 'can not be blank'
    change_item = ChangeItem.new( :name       => '',
                                  :position   => 1,
                                  :active     => false,
                                  :definition => 'Testing empty name')
    change_item.save
    assert_equal(1, change_item.errors.count)
    assert_equal(expected_error_message, change_item.errors[:name][0])
    
    # Retry with blanks
    change_item.name = '  '
    change_item.save
    assert_equal(1, change_item.errors.count)
    assert_equal(expected_error_message, change_item.errors[:name][0])
    
    # Retry with tabs
    change_item.name = "\t\t"
    change_item.save
    assert_equal(1, change_item.errors.count)
    assert_equal(expected_error_message, change_item.errors[:name][0])
  end
  
  
  ######################################################################
  def test_presence_of_name_on_update
    expected_error_message = 'can not be blank'
    change_item = ChangeItem.find(:first)
    change_item.name = ''
    change_item.save
    assert_equal(1, change_item.errors.count)
    assert_equal(expected_error_message, change_item.errors[:name][0])
    
    # Retry with blanks
    change_item.name = '  '
    change_item.save
    assert_equal(1, change_item.errors.count)
    assert_equal(expected_error_message, change_item.errors[:name][0])
    
    # Retry with tabs
    change_item.name = "\t\t"
    change_item.save
    assert_equal(1, change_item.errors.count)
    assert_equal(expected_error_message, change_item.errors[:name][0])
  end
  
  
  ######################################################################
  def test_add_first_change_item
    
    # Clear out the change item table to add the first change type
    empty_change_item_table
    
    change_class_item_count = @change_type_2_2.change_items.size
    change_item = ChangeItem.new( :name            => 'First Item',
                                  :position        => 1,
                                  :change_type_id => @change_type_2_2.id,
                                  :active          => false,
                                  :definition      => 'Added to an empty list')
                                  
    change_item.add_to_list
    change_item.reload
    @change_type_2_2.reload
    
    assert_equal(1,                            ChangeItem.count)
    assert_equal(change_class_item_count + 1,  @change_type_2_2.change_items.size)
    assert_equal('First Item',                 change_item.name)
    assert_equal(1,                            change_item.position)
    assert_equal(false,                        change_item.active)
    assert_equal(@change_type_2_2.id,          change_item.change_type_id)
    assert_equal('Added to an empty list',     change_item.definition)
    
  end


  ######################################################################
  def test_add_to_end
    
    change_type_item_count = @change_type_2_2.change_items.size
    change_item = ChangeItem.new( :name           => 'New Item',
                                  :position       => 3,
                                  :change_type_id => @change_type_2_2.id,
                                  :active         => true,
                                  :definition     => 'Tack on to end')
    change_item.add_to_list
    change_item.reload
    @change_type_2_2.reload

    assert_equal(@change_item_count + 1,      ChangeItem.count)
    assert_equal(change_type_item_count + 1, @change_type_2_2.change_items.size)
    assert_equal('New Item',                  change_item.name)
    assert_equal(3,                           change_item.position)
    assert_equal(true,                        change_item.active)
    assert_equal(@change_type_2_2.id,         change_item.change_type_id)
    assert_equal('Tack on to end',            change_item.definition)
    
  end


  ######################################################################
  def test_insert_in_the_middle
    
    change_type_item_count = @change_type_2_2.change_items.size
    change_item = ChangeItem.new( :name           => 'New Item',
                                  :position       => 2,
                                  :change_type_id => @change_type_2_2.id,
                                  :active         => true,
                                  :definition     => 'Insert in the middle')
    change_item.add_to_list
    change_item.reload
    @change_type_2_2.reload

    assert_equal(@change_item_count + 1,     ChangeItem.count)
    assert_equal(change_type_item_count + 1, @change_type_2_2.change_items.size)
    assert_equal('New Item',                 change_item.name)
    assert_equal(2,                          change_item.position)
    assert_equal(true,                       change_item.active)
    assert_equal('Insert in the middle',     change_item.definition)
    
    @change_item_2_2_1.reload
    @change_item_2_2_2.reload
    assert_equal(1, @change_item_2_2_1.position)
    assert_equal(3, @change_item_2_2_2.position)
    
  end
  
  
  ######################################################################
  def test_insert_at_the_beginning
    
    change_type_item_count = @change_type_2_2.change_items.size
    change_item = ChangeItem.new( :name           => 'New Item',
                                  :position       => 1,
                                  :change_type_id => @change_type_2_2.id,
                                  :active         => true,
                                  :definition     => 'New First')
    change_item.add_to_list
    change_item.reload
    @change_type_2_2.reload

    assert_equal(@change_item_count + 1,      ChangeItem.count)
    assert_equal(change_type_item_count + 1,  @change_type_2_2.change_items.size)
    assert_equal('New Item',                  change_item.name)
    assert_equal(1,                           change_item.position)
    assert_equal(true,                        change_item.active)
    assert_equal('New First',                 change_item.definition)
    
    @change_item_2_2_1.reload
    @change_item_2_2_2.reload
    assert_equal(2, @change_item_2_2_1.position)
    assert_equal(3, @change_item_2_2_2.position)
    
  end
  
  
  ######################################################################
  def test_move_to_the_beginning
    
    @change_item_2_2_2.update_list({ :name           => @change_item_2_2_2.name,
                                     :position       => 1,
                                     :change_type_id => @change_item_2_2_2.change_type_id,
                                     :active         => @change_item_2_2_2.active,
                                     :definition     => @change_item_2_2_2.definition })

    @change_item_2_2_1.reload
    @change_item_2_2_2.reload
    assert_equal(2, @change_item_2_2_1.position)
    assert_equal(1, @change_item_2_2_2.position)
    
  end
  
  
  ######################################################################
  def test_move_to_the_end
    
    @change_item_2_2_1.update_list({ :name           => @change_item_2_2_2.name,
                                     :position       => 2,
                                     :change_type_id => @change_item_2_2_2.change_type_id,
                                     :active         => @change_item_2_2_2.active,
                                     :definition     => @change_item_2_2_2.definition })

    @change_item_2_2_1.reload
    @change_item_2_2_2.reload
    assert_equal(2, @change_item_2_2_1.position)
    assert_equal(1, @change_item_2_2_2.position)
    
  end
  
  
  ######################################################################
  def test_update
    
    @change_item_2_2_1.update_list({ :name           => @change_item_2_2_1.name + ' Update',
                                     :position       => 1,
                                     :change_type_id => @change_item_2_2_1.change_type_id,
                                     :active         => !@change_item_2_2_1.active,
                                     :definition     => @change_item_2_2_1.definition + ' Update' })
    
    @change_item_2_2_1.reload
    @change_item_2_2_2.reload
    assert_equal('Class 2, Type 2, Item 1 Update',            @change_item_2_2_1.name)
    assert_equal(1,                                           @change_item_2_2_1.position)
    assert_equal('Describes the first item (class 2, type 2) Update', 
                 @change_item_2_2_1.definition)
    assert(!@change_item_2_2_1.active)
    assert_equal(2, @change_item_2_2_2.position)


  end

  
  ######################################################################
  def test_get_active_change_details
    all_details      = @change_item_1_1_3.change_details.find(:all)
    active_details   = @change_item_1_1_3.get_active_change_details
    inactive_details = all_details - active_details
    
    inactive_details.each { |change_detail| assert(!change_detail.active?) }
   
    pos = 0
    active_details.each do |change_detail|
      assert(change_detail.active)
      assert(change_detail.position > pos)
      pos = change_detail.position
    end
    
  end

  
private 

  
  def empty_change_item_table
    ChangeItem.delete_all
    assert_equal(0, ChangeItem.count)
  end
  
  
end
