########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: checklist_test.rb
#
# This file contains the unit tests for the checklist model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class ChecklistTest < Test::Unit::TestCase
  fixtures :checklists

  def setup
    @checklist = Checklist.find(checklists(:checklist_0_1).id)
  end

  def test_create

    assert_kind_of Checklist,  @checklist

    checklist_0_1 = checklists(:checklist_0_1)
    assert_equal(checklist_0_1.id,  @checklist.id)
    assert_equal(checklist_0_1.major_rev_number,
                 @checklist.major_rev_number)
    assert_equal(checklist_0_1.minor_rev_number,
                 @checklist.minor_rev_number)
    assert_equal(checklist_0_1.released,
                 @checklist.released)
    assert_equal(checklist_0_1.used,
                 @checklist.used)
    assert_equal(checklist_0_1.released_on,
                 @checklist.released_on)
    assert_equal(checklist_0_1.released_by,
                 @checklist.released_by)
    assert_equal(checklist_0_1.created_on,
                 @checklist.created_on)
    assert_equal(checklist_0_1.created_by,
                 @checklist.created_by)
    assert_equal(checklist_0_1.designer_only_count,
                 @checklist.designer_only_count)
    assert_equal(checklist_0_1.designer_auditor_count,
                 @checklist.designer_auditor_count)
    assert_equal(checklist_0_1.dc_designer_only_count,
                 @checklist.dc_designer_only_count)
    assert_equal(checklist_0_1.dc_designer_auditor_count,
                 @checklist.dc_designer_auditor_count)
    assert_equal(checklist_0_1.dr_designer_only_count,
                 @checklist.dr_designer_only_count)
    assert_equal(checklist_0_1.dr_designer_auditor_count,
                 @checklist.dr_designer_auditor_count)
  end

  def test_update

    @checklist.major_rev_number = 4
    @checklist.minor_rev_number = 1
    @checklist.released = 0
    @checklist.used = 0
    @checklist.released_on = "2005-5-23 00:00:00"
    @checklist.released_by = 3
    @checklist.created_on = "2005-5-24 00:00:00"
    @checklist.created_by = 4

    assert @checklist.save
    @checklist.reload

    assert_equal(4,
		 @checklist.major_rev_number)
    assert_equal(1,
		 @checklist.minor_rev_number)
    assert_equal(0,
		 @checklist.released)
    assert_equal(0,
		 @checklist.used)
# FIXME ????
#    assert_equal("2005-05-23 00:00:00",
#		 @checklist.released_on)
    assert_equal(3,
		 @checklist.released_by)
    assert_equal(4,
		 @checklist.created_by)

  end

  def test_destroy
    @checklist.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Checklist.find(@checklist.id) }
  end
end
