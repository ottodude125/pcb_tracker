########################################################################
#
# Copyright 2008, by Teradyne, Inc. North Reading MA
#
# File: design_change_test.rb
#
# This file contains the unit tests for the design change model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class DesignChangeTest < ActiveSupport::TestCase
  
  fixtures :change_classes,
           :change_details,
           :change_items,
           :change_types,
           :designs,
           :design_changes,
           :users
  
  
  def setup
    @expected_pending_changes  = [ design_changes(:mx234a_design_change),
                                   design_changes(:empty_design_change),
                                   design_changes(:design_change_ids_zero),
                                   design_changes(:design_change_ids_set),
                                   design_changes(:design_change_id_set_nonexistent) ].sort_by { |dc| dc.id }
    @expected_approved_changes = [ design_changes(:design_change_already_approved),
                                   design_changes(:design_change_already_approved_too) ]
    @mx234a_design_change      = design_changes(:mx234a_design_change)
  end
  
  
  ######################################################################
  def test_change_class_undefined
    assert(!design_changes(:empty_design_change).change_class_set?)
  end
  
  
  ######################################################################
  def test_change_class_id_zero
    assert(!design_changes(:design_change_ids_zero).change_class_set?)
  end
  
  
  ######################################################################
  def test_change_class_id_nonexistent
    assert(!design_changes(:design_change_id_set_nonexistent).change_class_set?)
  end
  
  
  ######################################################################
  def test_change_class_defined
    assert(design_changes(:design_change_ids_set).change_class_set?)
  end
  
  
  ######################################################################
  def test_change_type_undefined
    assert(!design_changes(:empty_design_change).change_type_set?)
  end
  
  
  ######################################################################
  def test_change_type_id_zero
    assert(!design_changes(:design_change_ids_zero).change_type_set?)
  end
  
  
  ######################################################################
  def test_change_type_id_nonexistent
    assert(!design_changes(:design_change_id_set_nonexistent).change_type_set?)
  end
  
  
  ######################################################################
  def test_change_type_defined
    assert(design_changes(:design_change_ids_set).change_type_set?)
  end
  
  
  ######################################################################
  def test_change_item_undefined
    assert(!design_changes(:empty_design_change).change_item_set?)
  end
  
  
  ######################################################################
  def test_change_item_id_zero
    assert(!design_changes(:design_change_ids_zero).change_item_set?)
  end
  
  
  ######################################################################
  def test_change_item_id_nonexistent
    assert(!design_changes(:design_change_id_set_nonexistent).change_item_set?)
  end
  
  
  ######################################################################
  def test_change_item_defined
    assert(design_changes(:design_change_ids_set).change_item_set?)
  end
  
  
  ######################################################################
  def test_change_detail_undefined
    assert(!design_changes(:empty_design_change).change_detail_set?)
  end
  
    
  ######################################################################
  def test_change_detail_id_zero
    assert(!design_changes(:design_change_ids_zero).change_detail_set?)
  end
  
  
  ######################################################################
  def test_change_detail_id_nonexistent
    assert(!design_changes(:design_change_id_set_nonexistent).change_detail_set?)
  end
  
  
  ######################################################################
  def test_change_detail_defined
    assert(design_changes(:design_change_ids_set).change_detail_set?)
  end
  
  
  ######################################################################
  def test_change_type_required_should_fail
    assert(!design_changes(:empty_design_change).change_type_required?)
    assert(!design_changes(:design_change_ids_zero).change_type_required?)
    assert(!design_changes(:design_change_id_set_nonexistent).change_type_required?)
  end
  
  
  ######################################################################
  def test_change_type_required_should_pass
    assert(design_changes(:design_change_ids_set).change_type_required?)
  end
  
  
  ######################################################################
  def test_change_item_required_should_fail
    assert(!design_changes(:empty_design_change).change_item_required?)
    assert(!design_changes(:design_change_ids_zero).change_item_required?)
    assert(!design_changes(:design_change_id_set_nonexistent).change_item_required?)
  end
  
  
  ######################################################################
  def test_change_item_required_should_pass
    assert(design_changes(:design_change_ids_set).change_item_required?)
  end
  
  
  ######################################################################
  def test_change_detail_required_should_fail
    assert(!design_changes(:empty_design_change).change_detail_required?)
    assert(!design_changes(:design_change_ids_zero).change_detail_required?)
    assert(!design_changes(:design_change_id_set_nonexistent).change_detail_required?)
  end
  
  
  ######################################################################
  def test_change_detail_required_should_pass
    assert(design_changes(:design_change_ids_set).change_detail_required?)
  end
  
  
  ######################################################################
  def test_impact
    design_change = DesignChange.new
    assert_equal(0.0, design_change.schedule_impact)
    design_change.impact = 'Added'
    assert_equal(0.0, design_change.schedule_impact)
    design_change.impact = 'Removed'
    assert_equal(0.0, design_change.schedule_impact)
    design_change.impact = 'None'
    design_change.hours  = 1.5
    assert_equal(0.0, design_change.schedule_impact)
    design_change.impact = 'Added'
    assert_equal(1.5, design_change.schedule_impact)
    design_change.impact = 'Removed'
    assert_equal(-1.5, design_change.schedule_impact)
  end

  
 ######################################################################
 def test_time_added
   design_change = DesignChange.new
   assert !design_change.time_added?
   design_change.impact =  'Removed'
   assert !design_change.time_added?
   design_change.impact =  'Added'
   assert  design_change.time_added?
 end

  
 ######################################################################
 def test_time_removed
   design_change = DesignChange.new
   assert !design_change.time_removed?
   design_change.impact =  'Added'
   assert !design_change.time_removed?
   design_change.impact =  'Removed'
   assert  design_change.time_removed?
 end

  
 ######################################################################
 def test_schedule_impact
   design_change = DesignChange.new
   assert !design_change.schedule_impact?
   design_change.impact =  'Added'
   assert  design_change.schedule_impact?
   design_change.impact =  'Removed'
   assert  design_change.schedule_impact?
 end

  
 ######################################################################
 def test_schedule_impact_statment
   design_change = DesignChange.new
   assert_equal('No impact to the schedule', 
                design_change.schedule_impact_statement)
   design_change.hours  = 3.5
   design_change.impact =  'Added'
   assert_equal('3.5 hours added to the schedule', 
                design_change.schedule_impact_statement)
   design_change.impact =  'Removed'
   assert_equal('3.5 hours removed from the schedule', 
                design_change.schedule_impact_statement)
 end

 
  ######################################################################
  def test_approval_status
    design_change = DesignChange.new
    assert_equal('Pending ',  design_change.approval_status)
    design_change.approved = true
    assert_equal('Approved ', design_change.approval_status)
  end
  
  
  ######################################################################
  def test_manager
    design_change = DesignChange.new
    assert_equal('Not Assigned',  design_change.manager.name)
    design_change.manager = users(:jim_l)
    assert_equal('James Light',   design_change.manager.name)
  end
  
  
  ######################################################################
  def test_designer
    design_change = DesignChange.new
    assert_equal('Not Assigned',  design_change.designer.name)
    design_change.designer = users(:scott_g)
    assert_equal('Scott Glover',   design_change.designer.name)
  end
  
  
  ######################################################################
  def test_approving_change_should_return_true
    design_change = design_changes(:design_change_ids_set)
    assert !design_change.approving_change?(false)
    
    design_change.approved = true
    design_change.save
    assert design_change.approving_change?(true)
  end


  ######################################################################
  def test_approving_change_should_return_false
    design_change = design_changes(:design_change_already_approved)
    assert !design_change.approving_change?(false)
    
    design_change.approved = true
    design_change.save
    assert !design_change.approving_change?(true)
  end
  
  
  ######################################################################
  def test_round_hours
    test_data = [ { :hours => 1.0,    :expected_result => 1.0 },
                  { :hours => 1.1,    :expected_result => 1.0 },
                  { :hours => 1.2,    :expected_result => 1.0 },
                  { :hours => 1.24,   :expected_result => 1.0 },
                  { :hours => 1.2499, :expected_result => 1.0 } ,
                  { :hours => 1.25,   :expected_result => 1.5 },
                  { :hours => 1.3,    :expected_result => 1.5 },
                  { :hours => 1.5,    :expected_result => 1.5 },
                  { :hours => 1.6,    :expected_result => 1.5 },
                  { :hours => 1.7,    :expected_result => 1.5 },
                  { :hours => 1.74,   :expected_result => 1.5 },
                  { :hours => 1.7499, :expected_result => 1.5 },
                  { :hours => 1.75,   :expected_result => 2.0 },
                  { :hours => 1.8,    :expected_result => 2.0 },
                  { :hours => 1.9,    :expected_result => 2.0 } ]
    
    design_change = design_changes(:design_change_ids_set)
    design_change.designer_comment = 'Test'
    design_change.impact           = 'Added'
    
    test_data.each do |test|
      design_change.hours = test[:hours]
      design_change.save!
      design_change.reload
      assert_equal(test[:expected_result], design_change.hours)
    end
  end
    
    
  ######################################################################
  def test_setting_approved
    
    design_change = design_changes(:design_change_ids_set)
    current_time  = Time.now
    
    assert(!design_change.approved_at)
    assert_equal('Not Assigned', design_change.manager.name)
    
    design_change.approve(users(:jim_l))
    
    assert(design_change.approved_at)
    assert(current_time              <= design_change.approved_at)
    assert(design_change.approved_at <= Time.now)
    assert_equal('James Light', design_change.manager.name)
    
  end
  
  
  
  ######################################################################
  def test_pending_approval_flag
    assert DesignChange.pending_approval?
    
    DesignChange.destroy_all
    assert !DesignChange.pending_approval?
  end
  
  
  ######################################################################
  def test_find_pending
    pending_design_change_list = DesignChange.find_pending
    assert_equal(@expected_pending_changes, pending_design_change_list)
    
    created_at = pending_design_change_list[0].created_at
    pending_design_change_list.each do |design_change|
      assert(created_at <= design_change.created_at)
      created_at = design_change.created_at
    end

    DesignChange.destroy_all
    assert_equal([], DesignChange.find_pending)
  end
  
  
  ######################################################################
  def test_pending_count
    assert_equal(@expected_pending_changes.size, DesignChange.pending_count)

    DesignChange.destroy_all
    assert_equal(0, DesignChange.pending_count)
  end
  
  
  ######################################################################
  def test_find_approved
    approved_design_change_list = DesignChange.find_approved
    assert_equal(@expected_approved_changes, approved_design_change_list)
    
    created_at = approved_design_change_list[0].created_at
    approved_design_change_list.each do |design_change|
      assert(created_at <= design_change.created_at)
      created_at = design_change.created_at
    end

    DesignChange.destroy_all
    assert_equal([], DesignChange.find_approved)
  end
  
  
  ######################################################################
  def test_approved_count
    assert_equal(@expected_approved_changes.size, DesignChange.approved_count)

    DesignChange.destroy_all
    assert_equal(0, DesignChange.approved_count)
  end


  ######################################################################
  def test_create_invalid_change_class_not_set
    design_change = DesignChange.new

    design_change.change_class_id = nil
    design_change.save
    assert_equal("Change Class selection is required",
                 design_change.errors[:change_class_id])
    design_change.change_class_id = 0
    design_change.save
    assert_equal("Change Class selection is required",
                 design_change.errors[:change_class_id])
  end


  ######################################################################
  def test_update_invalid_change_class_not_set
    @mx234a_design_change.change_class_id = nil
    @mx234a_design_change.save
    assert_equal("Change Class selection is required",
                 @mx234a_design_change.errors[:change_class_id])
    @mx234a_design_change.change_class_id = 0
    @mx234a_design_change.save
    assert_equal("Change Class selection is required",
                 @mx234a_design_change.errors[:change_class_id])
  end


  ######################################################################
  def test_create_invalid_change_type_not_set
    design_change = DesignChange.new

    design_change.change_class_id = 1
    design_change.change_type_id  = nil
    design_change.save
    assert_equal("Change Type selection is required",
                 design_change.errors[:change_type_id])
    design_change.change_type_id = 0
    design_change.save
    assert_equal("Change Type selection is required",
                 design_change.errors[:change_type_id])
  end


  ######################################################################
  def test_update_invalid_change_type_not_set
    @mx234a_design_change.change_type_id = nil
    @mx234a_design_change.save
    assert_equal("Change Type selection is required",
                 @mx234a_design_change.errors[:change_type_id])
    @mx234a_design_change.change_type_id = 0
    @mx234a_design_change.save
    assert_equal("Change Type selection is required",
                 @mx234a_design_change.errors[:change_type_id])
  end


  ######################################################################
  def test_create_invalid_change_item_not_set
    design_change = DesignChange.new

    design_change.change_class_id = 1
    design_change.change_type_id  = 11
    design_change.change_item_id  = nil
    design_change.save
    assert_equal("Change Item selection is required",
                 design_change.errors[:change_item_id])
    design_change.change_item_id = 0
    design_change.save
    assert_equal("Change Item selection is required",
                 design_change.errors[:change_item_id])
  end


  ######################################################################
  def test_update_invalid_change_item_not_set
    @mx234a_design_change.change_item_id = nil
    @mx234a_design_change.save
    assert_equal("Change Item selection is required",
                 @mx234a_design_change.errors[:change_item_id])
    @mx234a_design_change.change_item_id = 0
    @mx234a_design_change.save
    assert_equal("Change Item selection is required",
                 @mx234a_design_change.errors[:change_item_id])
  end


  ######################################################################
  def test_create_invalid_change_detail_not_set
    design_change = DesignChange.new

    design_change.change_class_id  = 1
    design_change.change_type_id   = 11
    design_change.change_item_id   = 113
    design_change.change_detail_id = nil
    design_change.save
    assert_equal("Change Detail selection is required",
                 design_change.errors[:change_detail_id])
    design_change.change_detail_id = 0
    design_change.save
    assert_equal("Change Detail selection is required",
                 design_change.errors[:change_detail_id])
  end


  ######################################################################
  def test_update_invalid_change_detail_not_set
    @mx234a_design_change.change_detail_id = nil
    @mx234a_design_change.save
    assert_equal("Change Detail selection is required",
                 @mx234a_design_change.errors[:change_detail_id])
    @mx234a_design_change.change_detail_id = 0
    @mx234a_design_change.save
    assert_equal("Change Detail selection is required",
                 @mx234a_design_change.errors[:change_detail_id])
  end


  ######################################################################
  def test_update_should_get_error_no_impact_with_hours
    @mx234a_design_change.impact = 'None'
    @mx234a_design_change.hours  = 40.0
    @mx234a_design_change.save
    assert_equal("If there is no schedule impact, the hours need to be set to '0.0'",
                 @mx234a_design_change.errors[:hours])
  end

  
end
