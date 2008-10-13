########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: change_detail_test.rb
#
# This file contains the unit tests for the change detail model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class ChangeDetailTest < ActiveSupport::TestCase
  
  fixtures :change_classes,
           :change_details,
           :change_items,
           :change_types
  
  
  def setup
    #@change_type_2_2       = change_types(:change_type_2_2)
    @change_item_2_2_1     = change_items(:change_item_2_2_1)
    #@change_item_2_2_2     = change_items(:change_item_2_2_2)
    @change_detail_2_2_1_1 = change_details(:change_detail_2_2_1_1)
    @change_detail_2_2_1_2 = change_details(:change_detail_2_2_1_2)
    @change_detail_count   = ChangeDetail.count
  end
  
  
  ######################################################################
  def test_add_first_change_detail
    
    # Clear out the change item table to add the first change type
    empty_change_detail_table
    
    change_item_details_count = @change_item_2_2_1.change_details.size
    change_detail = ChangeDetail.new( :name           => 'First Detail',
                                      :position       => 1,
                                      :change_item_id => @change_item_2_2_1.id,
                                      :active         => false,
                                      :definition     => 'Added to an empty list')
                                  
    change_detail.add_to_list
    change_detail.reload
    @change_item_2_2_1.reload
    
    assert_equal(1,                             ChangeDetail.count)
    assert_equal(change_item_details_count + 1, @change_item_2_2_1.change_details.size)
    assert_equal('First Detail',                change_detail.name)
    assert_equal(1,                             change_detail.position)
    assert_equal(false,                         change_detail.active)
    assert_equal(@change_item_2_2_1.id,         change_detail.change_item_id)
    assert_equal('Added to an empty list',      change_detail.definition)
    
  end


  ######################################################################
  def test_add_to_end
    
    change_item_details_count = @change_item_2_2_1.change_details.size
    change_detail = ChangeDetail.new( :name           => 'New Detail',
                                      :position       => 3,
                                      :change_item_id => @change_item_2_2_1.id,
                                      :active         => true,
                                      :definition     => 'Tack on to end')
    change_detail.add_to_list
    change_detail.reload
    @change_item_2_2_1.reload

    assert_equal(@change_detail_count + 1,      ChangeDetail.count)
    assert_equal(change_item_details_count + 1, @change_item_2_2_1.change_details.size)
    assert_equal('New Detail',                  change_detail.name)
    assert_equal(3,                             change_detail.position)
    assert_equal(true,                          change_detail.active)
    assert_equal(@change_item_2_2_1.id,         change_detail.change_item_id)
    assert_equal('Tack on to end',              change_detail.definition)
    
  end


  ######################################################################
  def test_insert_in_the_middle
    
    change_item_details_count = @change_item_2_2_1.change_details.size
    change_detail = ChangeDetail.new( :name           => 'New Detail',
                                      :position       => 2,
                                      :change_item_id => @change_item_2_2_1.id,
                                      :active         => true,
                                      :definition     => 'Insert in the middle')
    change_detail.add_to_list
    change_detail.reload
    @change_item_2_2_1.reload

    assert_equal(@change_detail_count + 1,      ChangeDetail.count)
    assert_equal(change_item_details_count + 1, @change_item_2_2_1.change_details.size)
    assert_equal('New Detail',                  change_detail.name)
    assert_equal(2,                             change_detail.position)
    assert_equal(true,                          change_detail.active)
    assert_equal('Insert in the middle',        change_detail.definition)
    
    @change_detail_2_2_1_1.reload
    @change_detail_2_2_1_2.reload
    assert_equal(1, @change_detail_2_2_1_1.position)
    assert_equal(3, @change_detail_2_2_1_2.position)
    
  end
  
  
  ######################################################################
  def test_insert_at_the_beginning
    
    change_item_details_count = @change_item_2_2_1.change_details.size
    change_detail = ChangeDetail.new( :name           => 'New Detail',
                                      :position       => 1,
                                      :change_item_id => @change_item_2_2_1.id,
                                      :active         => true,
                                      :definition     => 'New First')
    change_detail.add_to_list
    change_detail.reload
    @change_item_2_2_1.reload

    assert_equal(@change_detail_count + 1,      ChangeDetail.count)
    assert_equal(change_item_details_count + 1, @change_item_2_2_1.change_details.size)
    assert_equal('New Detail',                  change_detail.name)
    assert_equal(1,                             change_detail.position)
    assert_equal(true,                          change_detail.active)
    assert_equal('New First',                   change_detail.definition)
    
    @change_detail_2_2_1_1.reload
    @change_detail_2_2_1_2.reload
    assert_equal(2, @change_detail_2_2_1_1.position)
    assert_equal(3, @change_detail_2_2_1_2.position)
    
  end
  
  
  ######################################################################
  def test_move_to_the_beginning
    
   @change_detail_2_2_1_2.update_list({ :name        => @change_detail_2_2_1_2.name,
                                     :position       => 1,
                                     :change_item_id => @change_detail_2_2_1_2.change_item_id,
                                     :active         => @change_detail_2_2_1_2.active,
                                     :definition     => @change_detail_2_2_1_2.definition })

    @change_detail_2_2_1_1.reload
    @change_detail_2_2_1_2.reload
    assert_equal(2, @change_detail_2_2_1_1.position)
    assert_equal(1, @change_detail_2_2_1_2.position)
    
  end
  
  
  ######################################################################
  def test_move_to_the_end
    
    @change_detail_2_2_1_1.update_list({ :name           => @change_detail_2_2_1_1.name,
                                         :position       => 2,
                                         :change_item_id => @change_detail_2_2_1_1.change_item_id,
                                         :active         => @change_detail_2_2_1_1.active,
                                         :definition     => @change_detail_2_2_1_1.definition })

    @change_detail_2_2_1_1.reload
    @change_detail_2_2_1_2.reload
    assert_equal(2, @change_detail_2_2_1_1.position)
    assert_equal(1, @change_detail_2_2_1_2.position)
    
  end
  
  
  ######################################################################
  def test_update
    
    @change_detail_2_2_1_1.update_list(
      { :name           => @change_detail_2_2_1_1.name + ' Update',
        :position       => 1,
        :change_item_id => @change_detail_2_2_1_1.change_item_id,
        :active         => !@change_detail_2_2_1_1.active,
        :definition     => @change_detail_2_2_1_1.definition + ' Update' })
    
    @change_detail_2_2_1_1.reload
    @change_detail_2_2_1_2.reload
    assert_equal('Class 2, Type 2, Item 1, Detail 1 Update',  @change_detail_2_2_1_1.name)
    assert_equal(1,                                           @change_detail_2_2_1_1.position)
    assert_equal('Describes the first detail (class 2, type 2, item 1) Update', 
                 @change_detail_2_2_1_1.definition)
    assert(!@change_detail_2_2_1_1.active)
    assert_equal(1, @change_detail_2_2_1_1.position)


  end

  
private 

  
  def empty_change_detail_table
    ChangeDetail.delete_all
    assert_equal(0, ChangeDetail.count)
  end
  
  
end
