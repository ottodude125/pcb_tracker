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
           :designs,
           :users

  def setup
    @audit = Audit.find(audits(:audit_mx234b).id)
  end

  def test_create

    assert_kind_of Audit,  @audit

    audit_mx234b = audits(:audit_mx234b)
    assert_equal(audit_mx234b.id,           @audit.id)
    assert_equal(audit_mx234b.design_id,    @audit.design_id)
    assert_equal(audit_mx234b.checklist_id, @audit.checklist_id)
  end


  def test_update
    
    @audit.designer_completed_checks = 100
    @audit.auditor_completed_checks  = 200

    assert @audit.save

    @audit.reload

    assert_equal(100, @audit.designer_completed_checks)
    assert_equal(200, @audit.auditor_completed_checks)

  end

  def test_destroy

    @audit.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Audit.find(@audit.id) }

  end
  
  
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

end
