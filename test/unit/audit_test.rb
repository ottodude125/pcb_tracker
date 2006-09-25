########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: audit_test.rb
#
# This file contains the unit tests for the audit model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class AuditTest < Test::Unit::TestCase

  fixtures :audits,
           :audit_teammates,
           :boards,
           :checklists,
           :checks,
           :designs,
           :sections,
           :subsections,
           :users

  def setup
    @audit = Audit.find(audits(:audit_mx234b).id)
  end

  ######################################################################
  def test_create

    assert_kind_of Audit,  @audit

    audit_mx234b = audits(:audit_mx234b)
    assert_equal(audit_mx234b.id,           @audit.id)
    assert_equal(audit_mx234b.design_id,    @audit.design_id)
    assert_equal(audit_mx234b.checklist_id, @audit.checklist_id)
  end


  ######################################################################
  def test_locking
  
    audit1 = Audit.find(@audit.id)
    audit2 = Audit.find(@audit.id)
    assert_equal(false, audit1.designer_complete?)
    assert_equal(false, audit1.auditor_complete?)
    
    audit1.designer_complete = 1
    audit2.auditor_complete  = 1
    
    audit1.save
    
    assert_raises(ActiveRecord::StaleObjectError) {
      audit2.save
    }
    
    audit1.reload
    audit2.reload
    assert(audit1.designer_complete?)
    assert_equal(false, audit1.auditor_complete?)
    assert(audit2.designer_complete?)
    assert_equal(false, audit2.auditor_complete?)
    
    audit1.save
    begin
      audit2.auditor_complete = 1
      audit2.save
    rescue ActiveRecord::StaleObjectError
      audit2.reload
      retry
    end
    
    audit1.reload
    audit2.reload
    assert(audit1.designer_complete?)
    assert(audit1.auditor_complete?)
    assert(audit2.designer_complete?)
    assert(audit2.auditor_complete?)
    
  end
  
  
  ######################################################################
  def test_update
    
    @audit.designer_completed_checks = 100
    @audit.auditor_completed_checks  = 200

    assert @audit.save

    @audit.reload

    assert_equal(100, @audit.designer_completed_checks)
    assert_equal(200, @audit.auditor_completed_checks)

  end


  ######################################################################
  def test_destroy

    @audit.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Audit.find(@audit.id) }

  end
  
  
  ######################################################################
  def test_audit_states
  
    audit_in_self_audit = audits(:audit_in_self_audit)
    audit_in_peer_audit = audits(:audit_in_peer_audit)
    audit_complete      = audits(:audit_complete)
    
    assert_equal(Audit::SELF_AUDIT,     audit_in_self_audit.audit_state)
    assert_equal(Audit::PEER_AUDIT,     audit_in_peer_audit.audit_state)
    assert_equal(Audit::AUDIT_COMPLETE, audit_complete.audit_state)
    
    assert_equal(true,  audit_in_self_audit.is_self_audit?)
    assert_equal(false, audit_in_self_audit.is_peer_audit?)
    assert_equal(false, audit_in_self_audit.is_complete?)
    
    assert_equal(false, audit_in_peer_audit.is_self_audit?)
    assert_equal(true,  audit_in_peer_audit.is_peer_audit?)
    assert_equal(false, audit_in_peer_audit.is_complete?)
    
    assert_equal(false, audit_complete.is_self_audit?)
    assert_equal(false, audit_complete.is_peer_audit?)
    assert_equal(true,  audit_complete.is_complete?)
  
  end
  
  
  ######################################################################
  def test_audit_teams
  
    audit_in_self_audit = audits(:audit_in_self_audit)
    bob_g   = users(:bob_g)
    rich_m  = users(:rich_m)
    scott_g = users(:scott_g)

    assert(audit_in_self_audit.is_self_auditor?(bob_g))
    assert_equal(nil, audit_in_self_audit.is_self_auditor?(rich_m))
    assert_equal(audit_teammates(:mx999a_self_auditor),
                 audit_in_self_audit.is_self_auditor?(scott_g))
    
    assert(audit_in_self_audit.is_peer_auditor?(rich_m))
    assert_equal(nil, audit_in_self_audit.is_peer_auditor?(bob_g))
    assert_equal(audit_teammates(:mx999a_peer_auditor),
                 audit_in_self_audit.is_peer_auditor?(scott_g))
  
  end
  
  
  ######################################################################
  def test_check_creation
  
    audit_in_self_audit = audits(:audit_in_self_audit)
    
    assert_equal(0, audit_in_self_audit.design_checks.size)
    assert_equal(2, audit_in_self_audit.checklist_id)
    audit_in_self_audit.create_checklist
    
    # expected_checks is a nested hash.
    #
    #                 section  subsection  array of check ids
    #                 id       id
    expected_checks = {3 =>   {5 =>        [13, 14],
                               6 =>        [15, 16, 17, 24]},
                       4 =>   {7 =>        [18, 19, 20],
                               8 =>        [21, 22, 23]}}
    
    audit_in_self_audit.reload
    assert_equal(12, audit_in_self_audit.design_checks.size)
    
    actual_checks = {}
    for design_check in audit_in_self_audit.design_checks
      assert_equal(audit_in_self_audit.id, design_check.audit_id)
      section_id    = design_check.check.section_id
      subsection_id = design_check.check.subsection_id
      actual_checks[section_id] = {} if !actual_checks[section_id]
      actual_checks[section_id][subsection_id] = [] if !actual_checks[section_id][subsection_id]
      actual_checks[section_id][subsection_id] << design_check.check_id
    end
    
    assert_equal(expected_checks, actual_checks)
     
  end
  
  
  ######################################################################
  def test_check_counts
  
    audit_in_self_audit = audits(:audit_in_self_audit)
    assert_equal(11, audit_in_self_audit.check_count[:designer])
    assert_equal(4,  audit_in_self_audit.check_count[:peer])
    
    la454c3_audit = audits(:audit_la454c3)
    assert_equal(7, la454c3_audit.check_count[:designer])
    assert_equal(5, la454c3_audit.check_count[:peer])
    
    la453b_eco2_audit = audits(:audit_la453b_eco2)
    assert_equal(7, la453b_eco2_audit.check_count[:designer])
    assert_equal(5, la453b_eco2_audit.check_count[:peer])
    
  end
  
  ######################################################################
  def test_completion_stats
  
    audit_in_self_audit = audits(:audit_in_self_audit)
    assert_equal(" 91", 
                 sprintf("%3.f", audit_in_self_audit.completion_stats[:self]))
    assert_equal("  0", 
                 sprintf("%3.f", audit_in_self_audit.completion_stats[:peer]))
    
    audit_in_peer_audit = audits(:audit_in_peer_audit)
    assert_equal("100", 
                 sprintf("%3.f", audit_in_peer_audit.completion_stats[:self]))
    assert_equal(" 75", 
                 sprintf("%3.f", audit_in_peer_audit.completion_stats[:peer]))

    audit_complete = audits(:audit_complete)
    assert_equal("100", 
                 sprintf("%3.f", audit_complete.completion_stats[:self]))
    assert_equal("100", 
                 sprintf("%3.f", audit_complete.completion_stats[:peer]))

  end
  
end
