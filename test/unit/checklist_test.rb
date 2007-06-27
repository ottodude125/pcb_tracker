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
  fixtures :checks,
           :checklists,
           :sections,
           :subsections

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

    assert_equal(4, @checklist.major_rev_number)
    assert_equal(1, @checklist.minor_rev_number)
    assert_equal(0, @checklist.released)
    assert_equal(0, @checklist.used)
    assert_equal(Time.local(2005, "may", 23, 0, 0, 0).to_i,
                 @checklist.released_on.to_i)
    assert_equal(3, @checklist.released_by)
    assert_equal(4, @checklist.created_by)

  end
  
  
  def test_increment_checklist_counters
  
    expected_results = { 
     :designer_auditor_count    => [0, 1, 0, 0, 0, 0, 0],
     :dc_designer_auditor_count => [0, 0, 1, 0, 0, 0, 0],
     :dr_designer_auditor_count => [0, 0, 0, 1, 0, 0, 0],
     :designer_only_count       => [0, 0, 0, 0, 1, 0, 0],
     :dc_designer_only_count    => [0, 0, 0, 0, 0, 1, 0],
     :dr_designer_only_count    => [0, 0, 0, 0, 0, 0, 1]
    }
    
    checklist = Checklist.new
    check     = Check.new
    
    expected_results.each { |field, value|
      assert_equal(value[0], checklist.send(field)) }
    
    
    check.check_type  = 'designer_auditor'
    check.full_review = 1

    checklist.increment_checklist_counters(check, 1)
    expected_results.each { |field, value|
      assert_equal(value[1], checklist.send(field)) }

    checklist.increment_checklist_counters(check, -1)
    expected_results.each { |field, value|
      assert_equal(value[0], checklist.send(field)) }
      
    
    check.full_review     = 0
    check.date_code_check = 1

    checklist.increment_checklist_counters(check, 1)
    expected_results.each { |field, value|
      assert_equal(value[2], checklist.send(field)) }

    checklist.increment_checklist_counters(check, -1)
    expected_results.each { |field, value|
      assert_equal(value[0], checklist.send(field)) }


    check.date_code_check = 0
    check.dot_rev_check   = 1

    checklist.increment_checklist_counters(check, 1)
    expected_results.each { |field, value|
      assert_equal(value[3], checklist.send(field)) }

    checklist.increment_checklist_counters(check, -1)
    expected_results.each { |field, value|
      assert_equal(value[0], checklist.send(field)) }


    check.check_type    = 'designer_only'
    check.dot_rev_check = 0
    check.full_review   = 1

    checklist.increment_checklist_counters(check, 1)
    expected_results.each { |field, value|
      assert_equal(value[4], checklist.send(field)) }

    checklist.increment_checklist_counters(check, -1)
    expected_results.each { |field, value|
      assert_equal(value[0], checklist.send(field)) }
      
    
    check.check_type      = "yes_no"
    check.full_review     = 0
    check.date_code_check = 1

    checklist.increment_checklist_counters(check, 1)
    expected_results.each { |field, value|
      assert_equal(value[5], checklist.send(field)) }

    checklist.increment_checklist_counters(check, -1)
    expected_results.each { |field, value|
      assert_equal(value[0], checklist.send(field)) }


    check.check_type      = 'designer_only'
    check.date_code_check = 0
    check.dot_rev_check   = 1

    checklist.increment_checklist_counters(check, 1)
    expected_results.each { |field, value|
      assert_equal(value[6], checklist.send(field)) }

    checklist.increment_checklist_counters(check, -1)
    expected_results.each { |field, value|
      assert_equal(value[0], checklist.send(field)) }

  end
  
  
  def test_each_check
    expected_checks = [
      checks(:check_10_000),     checks(:check_10_001),     checks(:check_10_002),
      checks(:check_10_003),     checks(:check_10_004),     checks(:check_10_005),
      checks(:check_10_006),     checks(:check_10_007),     checks(:check_10_008),
      checks(:check_10_009),     checks(:check_10_010),     checks(:check_10_011),
      checks(:check_10_012),     checks(:check_10_013),     checks(:check_10_014)]
    i = 0
    checklists(:checklist_2_0).each_check do |c|
      assert_equal(expected_checks[i], c)
      i += 1
    end
  end
  

  def test_destroy
    @checklist.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Checklist.find(@checklist.id) }
  end
end
