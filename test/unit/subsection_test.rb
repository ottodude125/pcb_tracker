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

require File.expand_path( "../../test_helper", __FILE__ ) 

class SubsectionsTest < ActiveSupport::TestCase
  
  
  
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
  def test_check_methods
    
    Subsection.find(:all).each do |subsection|
      check_count = Check.count(:conditions => "subsection_id = #{subsection.id}")
      assert_equal(check_count, subsection.check_count)
    end
    
  end


  ######################################################################
  def test_locked
    assert( subsections(:subsection_10_1_1).locked?)
    assert(!subsections(:subsection_01_2_1).locked?)
  end


  ######################################################################
  def test_issue_methods
    
    audit = audits(:audit_109)
    audit.trim_checklist_for_peer_audit
    audit.get_design_checks
    
    # Get a subsection for testing.
    section_336    = sections(:section_336)
    subsection_539 = subsections(:subsection_539)
    section    = audit.checklist.sections.detect { |s| s.id == section_336.id}
    subsection = section.subsections.detect { |ss| ss.id == subsection_539.id }
     
    assert(!subsection.issues?)
    assert_equal(0, subsection.issue_count)
     
    check = subsection.checks.detect { |c| c.id = 2817}
    check.design_check.auditor_result = 'Comment'
    assert(subsection.issues?)
    assert_equal(1, subsection.issue_count)
     
    check.design_check.auditor_result = 'Verified'
    assert(!subsection.issues?)
    assert_equal(0, subsection.issue_count)
    
    subsection.checks.each { |chk| chk.design_check.auditor_result = 'Comment'}
    assert(subsection.issues?)
    assert_equal(7, subsection.issue_count)
     
  end
  
  
  ######################################################################
  def test_check_count_stats
    
    audit = audits(:audit_109)
    
    check = checks(:check_2818)
    check.check_type = 'designer_only'
    check.save 
    check = checks(:check_2820)
    check.check_type = 'yes_no'
    check.save 
    check = checks(:check_2819)
    check.check_type = 'yes_no'
    check.save 
    
    
    ## Collect the self audit statistics
    audit.trim_checklist_for_self_audit
    audit.get_design_checks
    
    # Get a subsection for testing.
    section_336    = sections(:section_336)
    subsection_539 = subsections(:subsection_539)
    section    = audit.checklist.sections.detect { |s| s.id == section_336.id}
    subsection = section.subsections.detect { |ss| ss.id == subsection_539.id }
    
    # Set the design checks
    subsection.checks.each do |check|
      next if !check.design_check
      check.design_check.designer_result = 'None'
      check.design_check.auditor_result  = 'None'
      check.design_check.save
    end
    
    # At this point, none of the design checks have not been verified.
    assert_equal(0, subsection.completed_self_design_checks)
    assert_equal(0, subsection.completed_peer_design_checks)
    assert_equal(0, subsection.completed_self_design_checks_percentage)
    assert_equal(0, subsection.completed_peer_design_checks_percentage)

    design_checks = subsection.checks.collect { |c| c.design_check }
    dc_15734 = design_checks.detect { |dc| dc.id == design_checks(:audit_109_design_check_15734).id }
    dc_15735 = design_checks.detect { |dc| dc.id == design_checks(:audit_109_design_check_15735).id }
    dc_15736 = design_checks.detect { |dc| dc.id == design_checks(:audit_109_design_check_15736).id }
    dc_15737 = design_checks.detect { |dc| dc.id == design_checks(:audit_109_design_check_15737).id }
    dc_15738 = design_checks.detect { |dc| dc.id == design_checks(:audit_109_design_check_15738).id }
    dc_15739 = design_checks.detect { |dc| dc.id == design_checks(:audit_109_design_check_15739).id }
    dc_15740 = design_checks.detect { |dc| dc.id == design_checks(:audit_109_design_check_15740).id }
    
    dc_15739.designer_result = 'Yes'
    dc_15740.designer_result = 'No'
    assert_equal(2, subsection.completed_self_design_checks)
    assert_equal(0, subsection.completed_peer_design_checks)
    assert_equal("28.57",
                 sprintf("%3.2f", subsection.completed_self_design_checks_percentage))
    assert_equal(0, subsection.completed_peer_design_checks_percentage)

    dc_15738.designer_result = 'N/A'
    dc_15737.designer_result = 'Verified'
    assert_equal(4, subsection.completed_self_design_checks)
    assert_equal(0, subsection.completed_peer_design_checks)
    assert_equal("57.14",
                 sprintf("%3.2f", subsection.completed_self_design_checks_percentage))
    assert_equal(0, subsection.completed_peer_design_checks_percentage)
    
    dc_15734.designer_result = 'N/A'
    dc_15735.designer_result = 'Verified'
    dc_15736.designer_result = 'Waived'
    assert_equal(7, subsection.completed_self_design_checks)
    assert_equal(0, subsection.completed_peer_design_checks)
    assert_equal("100.00",
                 sprintf("%3.2f", subsection.completed_self_design_checks_percentage))
    assert_equal(0, subsection.completed_peer_design_checks_percentage)

    
    ## Collect the self audit statistics
    audit.trim_checklist_for_peer_audit
    
    dc_15734.auditor_result = 'N/A'
    assert_equal(1, subsection.completed_peer_design_checks)
    assert_equal('25.00', 
                 sprintf("%3.2f", subsection.completed_peer_design_checks_percentage))
    
    dc_15734.auditor_result = 'Comment'
    assert_equal(0, subsection.completed_peer_design_checks)
    assert_equal('0.00', 
                 sprintf("%3.2f", subsection.completed_peer_design_checks_percentage))

    dc_15734.auditor_result = 'Verified'
    dc_15735.auditor_result = 'Waived'
    assert_equal(2, subsection.completed_peer_design_checks)
    assert_equal('50.00', 
                 sprintf("%3.2f", subsection.completed_peer_design_checks_percentage))

    dc_15736.auditor_result = 'Verified'
    dc_15737.auditor_result = 'Waived'
    assert_equal(4, subsection.completed_peer_design_checks)
    assert_equal('100.00', 
                 sprintf("%3.2f", subsection.completed_peer_design_checks_percentage))

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
