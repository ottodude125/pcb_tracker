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
           :boards,
           :designs

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

end
