########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: check_test.rb
#
# This file contains the unit tests for the check model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class CheckTest < Test::Unit::TestCase
  fixtures :checks,
           :checklists,
           :designs,
           :sections,
           :subsections

  def setup
    @check = Check.find(checks(:check_18).id)
  end


  ######################################################################
  def test_belongs_to
  
    new_design       = Design.new(:design_type => "New")
    date_code_design = Design.new(:design_type => "Date Code")
    dot_rev_design   = Design.new(:design_type => "Dot Rev")
    
    full_review_check = Check.new(:full_review     => 1)
    date_code_check   = Check.new(:date_code_check => 1)
    dot_rev_check     = Check.new(:dot_rev_check   => 1)
    
    assert(full_review_check.belongs_to?(new_design))
    assert(date_code_check.belongs_to?(new_design))
    assert(dot_rev_check.belongs_to?(new_design))
    
    assert(!full_review_check.belongs_to?(date_code_design))
    assert( date_code_check.belongs_to?(date_code_design))
    assert(!dot_rev_check.belongs_to?(date_code_design))
    
    assert(!full_review_check.belongs_to?(dot_rev_design))
    assert(!date_code_check.belongs_to?(dot_rev_design))
    assert( dot_rev_check.belongs_to?(dot_rev_design))
    
    assert(full_review_check.full?)
    assert(!full_review_check.partial?)
    
    assert(!dot_rev_check.full?)
    assert(dot_rev_check.partial?)
    
  end
  
  ######################################################################
  def test_accessors
  
    check_01 = checks(:check_01)
    check_04 = checks(:check_04)
    check_09 = checks(:check_09)
    
    assert(check_04.yes_no?)
    assert(!check_04.designer_auditor?)
    assert(!check_04.designer_only?)
    assert(!check_04.is_peer_check?)
    assert(check_04.is_self_check?)
    
    assert(check_01.designer_auditor?)
    assert(!check_01.yes_no?)
    assert(!check_01.designer_only?)
    assert(check_01.is_peer_check?)
    assert(check_01.is_self_check?)
    
    assert(check_09.designer_only?)
    assert(!check_09.yes_no?)
    assert(!check_09.designer_auditor?)
    assert(!check_09.is_peer_check?)
    assert(check_09.is_self_check?)
  
  end


  ######################################################################
  def test_insert
    
    checklist  = Checklist.new
    checklist.save
    section    = Section.new( :checklist_id => checklist.id )
    section.save
    subsection = Subsection.new( :section_id => section.id )
    subsection.save
    
    assert_equal(0, subsection.checks.size)
    
    first_check = Check.new( :title         => 'First Check Title',
                             :check         => 'First Check',
                             :subsection_id => subsection.id )
    first_check.insert(subsection.id, 1)

    subsection.reload
    first_check.reload
    assert_equal(1, subsection.checks.size)
    assert_equal(1, first_check.position)
    assert(first_check.errors.empty?)
    
    new_first_check = Check.new( :title         => 'New First Check Title',
                                 :check         => 'New First Check',
                                 :subsection_id => subsection.id )
    new_first_check.insert(subsection.id, first_check.position)

    subsection.reload
    new_first_check.reload
    first_check.reload
    assert_equal(2, subsection.checks.size)
    assert_equal(1, new_first_check.position)
    assert_equal(2, first_check.position)
    assert(new_first_check.errors.empty?)
    
    new_second_check = Check.new( :title         => 'New Second Check Title',
                                  :check         => 'New Second Check',
                                  :subsection_id => subsection.id )
    new_second_check.insert(subsection.id, first_check.position)

    subsection.reload
    new_second_check.reload
    new_first_check.reload
    first_check.reload
    assert_equal(3, subsection.checks.size)
    assert_equal(1, new_first_check.position)
    assert_equal(2, new_second_check.position)
    assert_equal(3, first_check.position)
    assert(new_second_check.errors.empty?)
    
  end


  ######################################################################
  def test_remove

    check_02    = checks(:check_02)
    subsection  = check_02.subsection
    section     = subsection.section
    checklist   = section.checklist
    check_count = subsection.checks.size
    
    assert_equal(6, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(3, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(3, checklist.dr_designer_auditor_count)
    
    total_checks = Check.count

    result = check_02.remove
    assert(result)
    
    check_count -= 1
    subsection.reload
    assert_equal(check_count, subsection.checks.size)

    subsection.checks.each_with_index do |check, i|
      assert_equal(i+1, check.position)
    end
    
    checklist.reload
    assert_equal(6, checklist.designer_only_count)
    assert_equal(4, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(2, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(2, checklist.dr_designer_auditor_count)

  end
  
  
  ######################################################################
  def test_released
    
    check_2744    = checks(:check_2744)

    assert(check_2744.locked?)
    
    check_2744.checklist.released = 0
    assert(!check_2744.locked?)
    
  end
 
 
  ######################################################################
  def test_short_cuts
    
    check = Check.new
    assert_nil(check.section)
    assert_nil(check.checklist)
    
    check_2744    = checks(:check_2744)
    section_331   = sections(:section_331)
    checklist_101 = checklists(:checklists_101)
    assert_equal(section_331,   check_2744.section)
    assert_equal(checklist_101, check_2744.checklist)
    
  end


end
