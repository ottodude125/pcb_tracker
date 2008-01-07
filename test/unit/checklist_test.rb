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
  
  
  def test_release
    
    # Remove any existing released checklists.
    released_checklists = Checklist.find(:all, :conditions => "released=1")
    released_checklists.each { |checklist| checklist.destroy }
    
    # There are no released checklists - a new checklist should be returned.
    released_checklist = Checklist.latest_release
    assert_nil(released_checklist.id)
    assert(!released_checklist.released?)
    assert(!released_checklist.locked?)
    
    checklist = Checklist.find(:first)
    message   = checklist.release
    assert_equal('Checklist successfully released', message)
    
    # The checklist that was just released should be returned.
    released_checklist = Checklist.latest_release
    assert_not_nil(released_checklist.id)
    assert_equal(0, released_checklist.minor_rev_number)
    assert_equal(1, released_checklist.major_rev_number)
    assert(released_checklist.released?)
    assert(released_checklist.locked?)
    
  end
  
  
  ######################################################################
  def test_remove
    
    checklist_101    = checklists(:checklists_101)
    checklist_101_id = checklist_101.id
    assert(checklist_101.locked?)
    
    checklist_101.released = 0
    checklist_101.save
    
    assert(!checklist_101.locked?)
    
    total_checks      = Check.count
    total_subsections = Subsection.count
    total_sections    = Section.count
    total_checklists  = Checklist.count
    
    ids = { :checks      => [],
            :subsections => [],
            :sections    => [] }
            
    checklist_101.sections.each do |section|
      ids[:sections] << section.id
      section.subsections.each do |subsection|
        ids[:subsections] << subsection.id
        subsection.checks.each do |check|
          ids[:checks] << check.id
        end
      end
    end
    
    assert(checklist_101.remove)
    
    total_checks      -= ids[:checks].size
    total_subsections -= ids[:subsections].size
    total_sections    -= ids[:sections].size
    
    assert_equal(total_checks,       Check.count)
    assert_equal(total_subsections,  Subsection.count)
    assert_equal(total_sections,     Section.count)
    assert_equal(total_checklists-1, Checklist.count)
    
    all_checks      = Check.find(:all)
    all_subsections = Subsection.find(:all)
    all_sections    = Section.find(:all)
    all_checklists  = Checklist.find(:all)
    ids[:checks].each { |id| assert(!all_checks.detect { |c| c.id == id }) }
    ids[:subsections].each { |id| assert(!all_subsections.detect { |ss| ss.id == id })}
    ids[:sections].each { |id| assert(!all_sections.detect { |s| s.id == id })}
    assert(!all_checklists.detect { |cl| cl.id == checklist_101_id })
    
  end
  
  

  def test_destroy
    @checklist.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Checklist.find(@checklist.id) }
  end
end
