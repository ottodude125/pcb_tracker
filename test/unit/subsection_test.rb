########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: subsection_test.rb
#
# This file contains the unit tests for the subsection model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class SubsectionTest < Test::Unit::TestCase
  
  
  fixtures :checklists,
           :checks,
           :sections,
           :subsections
  
  
  ######################################################################
  def test_designer_auditor_check_count
    
    subsection = checks(:check_2744).subsection
    assert_equal(13, subsection.designer_auditor_check_count)
    assert_equal( 0, Subsection.new.designer_auditor_check_count)
    
  end


  ######################################################################
  def test_insert
    
    checklist  = Checklist.new
    checklist.save
    section    = Section.new( :checklist_id => checklist.id )
    section.save
    
    assert_equal(0, section.subsections.size)
    
    first_subsection = Subsection.new( :name       => 'First Subsection Name',
                                       :note       => 'First Subsection Note',
                                       :section_id => section.id )
    first_subsection.insert(section.id, 1)

    section.reload
    first_subsection.reload
    assert_equal(1, section.subsections.size)
    assert_equal(1, first_subsection.position)
    assert(first_subsection.errors.empty?)
    
    new_first_subsection = Subsection.new( :name       => 'New First Subsection Name',
                                           :note       => 'New First Subsection Note',
                                           :section_id => section.id )
    new_first_subsection.insert(section.id, first_subsection.position)

    section.reload
    new_first_subsection.reload
    first_subsection.reload
    assert_equal(2, section.subsections.size)
    assert_equal(1, new_first_subsection.position)
    assert_equal(2, first_subsection.position)
    assert(new_first_subsection.errors.empty?)
    
    new_second_subsection = Subsection.new( :name       => 'New Second Check Title',
                                            :note       => 'New Second Check',
                                            :section_id => section.id )
    new_second_subsection.insert(section.id, first_subsection.position)

    section.reload
    new_second_subsection.reload
    new_first_subsection.reload
    first_subsection.reload
    assert_equal(3, section.subsections.size)
    assert_equal(1, new_first_subsection.position)
    assert_equal(2, new_second_subsection.position)
    assert_equal(3, first_subsection.position)
    assert(new_second_subsection.errors.empty?)
    
  end


  ######################################################################
  def test_remove
    
    checklist = Checklist.find(subsections(:subsection_01_1_1).checklist.id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(3, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(3, checklist.dr_designer_auditor_count)

    subsection_01_1_1 = subsections(:subsection_01_1_1)
    subsection_01_1_2 = subsections(:subsection_01_1_2)
    section                    = subsection_01_1_1.section
    checklist                  = section.checklist
    subsection_count           = section.subsections.size
    
    subsection_01_1_1_check_count = subsection_01_1_1.checks.size
    subsection_01_1_2_check_count = subsection_01_1_2.checks.size
    check_count                   = Check.count
    
    assert_equal(2, section.subsections.size)
    assert_equal(1, subsection_01_1_1.position)
    assert_equal(2, subsection_01_1_2.position)
   
    assert(subsection_01_1_1.remove)

    section.reload
    subsection_01_1_2.reload
    subsection_count -= 1
    assert_equal(subsection_count, section.subsections.size)
    assert_equal(1, subsection_01_1_2.position)

    check_count -= subsection_01_1_1_check_count
    assert_equal(check_count, Check.count)

    checklist.reload
    assert_equal(6, checklist.designer_only_count)
    assert_equal(3, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(0, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(0, checklist.dr_designer_auditor_count)
    

    assert(subsection_01_1_2.remove)

    section.reload
    check_count -= subsection_01_1_2_check_count
    assert_equal(0,           section.subsections.size)
    assert_equal(check_count, Check.count)

    checklist.reload
    assert_equal(3, checklist.designer_only_count)
    assert_equal(3, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(0, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(0, checklist.dr_designer_auditor_count)

    subsection_01_2_1             = subsections(:subsection_01_2_1)
    subsection_01_2_1_check_count = subsection_01_2_1.checks.size
    section                       = subsection_01_2_1.section

    assert_equal(3, section.subsections.size)
    assert_equal(3, subsection_01_2_1_check_count)

    assert(subsection_01_2_1.remove)

    section.reload
    check_count -= subsection_01_2_1_check_count
    assert_equal(2,           section.subsections.size)
    assert_equal(check_count, Check.count)

    checklist.reload
    assert_equal(0, checklist.designer_only_count)
    assert_equal(3, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(0, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(0, checklist.dr_designer_auditor_count)

  end


  ######################################################################
  def test_short_cuts
    
    assert_nil(Subsection.new.checklist)
    
    subsection    = checks(:check_2744).subsection
    section_331   = sections(:section_331)
    checklist_101 = checklists(:checklists_101)
    assert_equal(section_331,   subsection.section)
    assert_equal(checklist_101, subsection.checklist)

  end


  ######################################################################
  def test_locked
    assert( subsections(:subsection_10_1_1).locked?)
    assert(!subsections(:subsection_01_2_1).locked?)
  end


  ######################################################################
  def test_get_checks
    
    checklist = checklists(:checklist_1_0)
    checklist.sections.each do |sect|
      sect.subsections.each do |ss|
        
        all_checks = ss.checks
        
        checks = ss.get_checks(:self, :full)
        discarded_checks = all_checks - checks
        checks.each do |check|
          assert(check.is_self_check?)
          assert(check.full?)
        end
        discarded_checks.each do |check|
          assert(!(check.is_self_check? && check.full?))
        end
        ss.reload
        
        checks = ss.get_checks(:self, :partial)
        discarded_checks = all_checks - checks
        checks.each do |check|
          assert(check.is_self_check?)
          assert(check.partial?)
        end
        discarded_checks.each do |check|
          assert(!(check.is_self_check? && check.partial?))
        end
        ss.reload
        
        checks = ss.get_checks(:peer, :full)
        discarded_checks = all_checks - checks
        checks.each do |check|
          assert(check.is_peer_check?)
          assert(check.full?)
        end
        discarded_checks.each do |check|
          assert(!(check.is_peer_check? && check.full?))
        end
        ss.reload
        
        checks = ss.get_checks(:peer, :partial)
        discarded_checks = all_checks - checks
        checks.each do |check|
          assert(check.is_peer_check?)
          assert(check.partial?)
        end
        discarded_checks.each do |check|
          assert(!(check.is_peer_check? && check.partial?))
        end
        
      end
    end
    
    # Test all possible combinations
    subsection = Subsection.new
    subsection.save

    checks = [ { :check => '1', 
                 :check_type => 'designer_auditor', :full => 1, :dot_rev => 1, 
                 :peer => true,  :full => true,  :partial => true,  :self => true },
               { :check => '2', 
                 :check_type => 'designer_auditor', :full => 1, :dot_rev => 0, 
                 :peer => true,  :full => true,  :partial => false, :self => true },
               { :check => '3', 
                 :check_type => 'designer_auditor', :full => 0, :dot_rev => 1, 
                 :peer => true,  :full => false, :partial => true,  :self => true },
               { :check => '4', 
                 :check_type => 'desginer_only',    :full => 1, :dot_rev => 1, 
                 :peer => false, :full => true,  :partial => true,  :self => true },
               { :check => '5', 
                 :check_type => 'yes_no',           :full => 1, :dot_rev => 0, 
                 :peer => false, :full => true,  :partial => false, :self => true },
               { :check => '6', 
                 :check_type => 'designer_only',    :full => 0, :dot_rev => 1, 
                 :peer => false, :full => false, :partial => true,  :self => true } ]
              
    assert_equal(0, subsection.checks.size)
    checks.each_with_index do |c, i| 
      check = Check.new
      check.check         = c[:check]
      check.check_type    = c[:check_type]
      check.full_review   = c[:full]
      check.dot_rev_check = c[:dot_rev]
      check.subsection_id = subsection.id
      check.position      = i+1
      check.save
    end

    subsection.reload
    assert_equal(checks.size, subsection.checks.size)
    
    returned_checks = subsection.get_checks(:peer, :full)
    assert_equal(2, returned_checks.size)
    returned_checks.each do |check|
      chk = checks.detect { |c| c[:check] == check.check }
      assert(chk[:peer])
      assert(chk[:full])
    end

    subsection.reload
    returned_checks = subsection.get_checks(:peer, :partial)
    assert_equal(2, returned_checks.size)
    returned_checks.each do |check|
      chk = checks.detect { |c| c[:check] == check.check }
      assert(chk[:peer])
      assert(chk[:partial])
    end

    subsection.reload
    returned_checks = subsection.get_checks(:self, :full)
    assert_equal(4, returned_checks.size)
    returned_checks.each do |check|
      chk = checks.detect { |c| c[:check] == check.check }
      assert(chk[:self])
      assert(chk[:full])
    end

    subsection.reload
    returned_checks = subsection.get_checks(:self, :partial)
    assert_equal(4, returned_checks.size)
    returned_checks.each do |check|
      chk = checks.detect { |c| c[:check] == check.check }
      assert(chk[:self])
      assert(chk[:partial])
    end

  end


end
