########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_check_test.rb
#
# This file contains the unit tests for the design check model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class DesignCheckTest < Test::Unit::TestCase

  fixtures :audits,
           :checks,
           :design_checks,
           :users

  def setup
    @design_check = design_checks(:first_design_check)
    @dc_15704     = design_checks(:audit_109_design_check_15704)
    
    @scott_g  = users(:scott_g)
    @bob_g    = users(:bob_g)
  end


  ######################################################################
  def test_access
    
    @dc_15704.auditor_id = @bob_g.id
    assert_equal('Scott Glover',  @dc_15704.self_auditor.name)
    assert_equal('Robert Goldin', @dc_15704.peer_auditor.name)
    
    @dc_15704.designer_id = 0
    @dc_15704.auditor_id  = 0
    assert_equal('Not Assigned',  @dc_15704.self_auditor.name)
    assert_equal('Not Assigned', @dc_15704.peer_auditor.name)
    
    assert(!@design_check.self_auditor_checked?)
    assert(!@design_check.peer_auditor_checked?)
    
    @design_check.auditor_result = 'Comment'
    assert(!@design_check.peer_auditor_checked?)
    
    @design_check.designer_result = 'Verified'
    @design_check.auditor_result  = 'Verified'
    assert(@design_check.self_auditor_checked?)
    assert(@design_check.peer_auditor_checked?)
    
    @design_check.designer_result = 'N/A'
    @design_check.auditor_result  = 'N/A'
    assert(@design_check.self_auditor_checked?)
    assert(@design_check.peer_auditor_checked?)
    
    @design_check.designer_result = 'Waived'
    @design_check.auditor_result  = 'Waived'
    assert(@design_check.self_auditor_checked?)
    assert(@design_check.peer_auditor_checked?)
    
  end


  ######################################################################
  def test_create

    assert_kind_of DesignCheck,  @design_check

    first_design_check = design_checks(:first_design_check)
    assert_equal(first_design_check.id,         @design_check.id)
    assert_equal(first_design_check.audit_id,   @design_check.audit_id)
    assert_equal(first_design_check.check_id,   @design_check.check_id)
    assert_equal(first_design_check.auditor_id, @design_check.auditor_id)
    assert_equal(first_design_check.auditor_result,
                 @design_check.auditor_result)
    assert_equal(first_design_check.auditor_checked_on,
                 @design_check.auditor_checked_on)
    assert_equal(first_design_check.designer_id,
                 @design_check.designer_id)
    assert_equal(first_design_check.designer_result,
                 @design_check.designer_result)
    assert_equal(first_design_check.designer_checked_on,
                 @design_check.designer_checked_on)
  end


  ######################################################################
  def test_add
    
    dc_list  = DesignCheck.find(:all)
    dc_count = dc_list.size
    
    audit = audits(:audit_mx234a)
    check = checks(:check_01)
    
    DesignCheck.add(audit, check)

    design_check = (DesignCheck.find(:all) - dc_list).pop
    assert_equal(dc_count + 1, DesignCheck.count)
    assert_equal(audit.id,     design_check.audit_id)
    assert_equal(check.id,     design_check.check_id)

  end
  
    
  ######################################################################
  def test_update
    
    @design_check.audit_id            = 2
    @design_check.check_id            = 4
    @design_check.auditor_id          = 5
    @design_check.auditor_result      = 'N/A'
    @design_check.auditor_checked_on  = '20050610113323'
    @design_check.designer_id         = 554
    @design_check.designer_result     = 'No'
    @design_check.designer_checked_on = '20050610113323'

    assert @design_check.save
    @design_check.reload

    assert_equal(2,     @design_check.audit_id)
    assert_equal(4,     @design_check.check_id)
    assert_equal(5,     @design_check.auditor_id)
    assert_equal('N/A', @design_check.auditor_result)
    assert_equal(Time.local(2005, 'jun', 10, 11, 33, 23),
		 @design_check.auditor_checked_on)
    assert_equal(554,   @design_check.designer_id)
    assert_equal('No',  @design_check.designer_result)
    assert_equal(Time.local(2005, 'jun', 10, 11, 33, 23), 
                 @design_check.designer_checked_on)
               
    
    design_check = DesignCheck.new
    assert_equal('None', design_check.designer_result)
    
    start_time = Time.now
    design_check.update_designer_result('Verified', @scott_g)
    assert_equal('Verified',  design_check.designer_result)
    assert_equal(@scott_g.id, design_check.designer_id)
    assert(start_time <= design_check.designer_checked_on)
    assert(design_check.designer_checked_on <= Time.now)
    
    start_time = Time.now
    assert(!design_check.auditor_verified?)
    assert_equal(1, design_check.update_auditor_result('Verified', @bob_g))
    assert(design_check.auditor_verified?)
    assert_equal('Verified',  design_check.auditor_result)
    assert_equal(@bob_g.id,   design_check.auditor_id)
    assert(start_time <= design_check.auditor_checked_on)
    assert(design_check.auditor_checked_on <= Time.now)

    assert_equal(-1, design_check.update_auditor_result('Comment', @bob_g))
    assert(!design_check.auditor_verified?)
    assert_equal('Comment',  design_check.auditor_result)
    assert_equal(@bob_g.id,  design_check.auditor_id)
    assert(start_time <= design_check.auditor_checked_on)
    assert(design_check.auditor_checked_on <= Time.now)

  end


  ######################################################################
  def test_destroy
    @design_check.destroy
    assert_raise(ActiveRecord::RecordNotFound) { DesignCheck.find(@design_check.id) }
  end
  
  
  ######################################################################
  def test_comment_required
  
    dc_yes_no           = design_checks(:audit_109_design_check_15729)
    dc_designer_only    = design_checks(:audit_109_design_check_15695)
    dc_designer_auditor = design_checks(:audit_109_design_check_15778)
    
    assert(!dc_yes_no.comment_required?('Yes', ''))
    assert( dc_yes_no.comment_required?('No',  ''))
    
    assert(!dc_designer_only.comment_required?('N/A',      ''))
    assert(!dc_designer_only.comment_required?('Verified', ''))
    assert( dc_designer_only.comment_required?('Waived',   ''))
    
    assert(!dc_designer_auditor.comment_required?('N/A',      ''))
    assert(!dc_designer_auditor.comment_required?('Verified', ''))
    assert( dc_designer_auditor.comment_required?('Waived',   ''))
    assert(!dc_designer_auditor.comment_required?('', 'N/A'))
    assert(!dc_designer_auditor.comment_required?('', 'Verified'))
    assert( dc_designer_auditor.comment_required?('', 'Waived'))
    assert( dc_designer_auditor.comment_required?('', 'Comment'))

  end


end
