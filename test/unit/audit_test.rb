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
           :design_checks,
           :prefixes,
           :priorities,
           :revisions,
           :sections,
           :subsections,
           :users

  def setup
  
    @audit_mx234b        = audits(:audit_mx234b)
    @audit_in_self_audit = audits(:audit_in_self_audit)
    @audit_in_peer_audit = audits(:audit_in_peer_audit)
    @audit_complete      = audits(:audit_complete)
    @audit_109           = audits(:audit_109)
    
    @subsection_537      = subsections(:subsection_537)
    @subsection_548      = subsections(:subsection_548)
      
    @bob_g   = users(:bob_g)
    @rich_m  = users(:rich_m)
    @scott_g = users(:scott_g)
    @siva_e  = users(:siva_e)
    @cathy_m = users(:cathy_m)

  end

  ######################################################################
  def test_create

    assert_kind_of Audit,  @audit_mx234b

    audit_mx234b = audits(:audit_mx234b)
    assert_equal(audit_mx234b.id,           @audit_mx234b.id)
    assert_equal(audit_mx234b.design_id,    @audit_mx234b.design_id)
    assert_equal(audit_mx234b.checklist_id, @audit_mx234b.checklist_id)
  end


  ######################################################################
  def test_locking
  
    audit1 = Audit.find(@audit_mx234b.id)
    audit2 = Audit.find(@audit_mx234b.id)
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
    assert(!audit1.auditor_complete?)
    assert(audit2.designer_complete?)
    assert(!audit2.auditor_complete?)
    
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
    
    @audit_mx234b.designer_completed_checks = 100
    @audit_mx234b.auditor_completed_checks  = 200

    assert @audit_mx234b.save

    @audit_mx234b.reload

    assert_equal(100, @audit_mx234b.designer_completed_checks)
    assert_equal(200, @audit_mx234b.auditor_completed_checks)

  end


  ######################################################################
  def test_destroy

    @audit_mx234b.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Audit.find(@audit_mx234b.id) }

  end
  
  
  ######################################################################
  def test_audit_states
    
    assert_equal(Audit::SELF_AUDIT,     @audit_in_self_audit.audit_state)
    assert_equal(Audit::PEER_AUDIT,     @audit_in_peer_audit.audit_state)
    assert_equal(Audit::AUDIT_COMPLETE, @audit_complete.audit_state)
    
    assert(@audit_in_self_audit.is_self_audit?)
    assert(!@audit_in_self_audit.is_peer_audit?)
    assert(!@audit_in_self_audit.is_complete?)
    
    assert(!@audit_in_peer_audit.is_self_audit?)
    assert(@audit_in_peer_audit.is_peer_audit?)
    assert(!@audit_in_peer_audit.is_complete?)
    
    assert(!@audit_complete.is_self_audit?)
    assert(!@audit_complete.is_peer_audit?)
    assert(@audit_complete.is_complete?)
  
  end
  
  
  ######################################################################
  def test_audit_teams

    assert(@audit_in_self_audit.is_self_auditor?(@bob_g))
    assert_nil(@audit_in_self_audit.is_self_auditor?(@rich_m))
    assert_equal(audit_teammates(:mx999a_self_auditor_1),
                 @audit_in_self_audit.is_self_auditor?(@scott_g))
    
    assert(@audit_in_self_audit.is_peer_auditor?(@rich_m))
    assert_nil(@audit_in_self_audit.is_peer_auditor?(@bob_g))
    assert_equal(audit_teammates(:mx999a_peer_auditor_1),
                 @audit_in_self_audit.is_peer_auditor?(@scott_g))
  
  end
  
  
  ######################################################################
  def test_check_creation
    
    assert_equal(0, @audit_in_self_audit.design_checks.size)
    assert_equal(2, @audit_in_self_audit.checklist_id)
    @audit_in_self_audit.create_checklist
    
    # expected_checks is a nested hash.
    #
    #                 section  subsection  array of check ids
    #                 id       id
    expected_checks = {3 =>   {5 =>        [13, 14],
                               6 =>        [15, 16, 17, 24]},
                       4 =>   {7 =>        [18, 19, 20],
                               8 =>        [21, 22, 23]}}
    
    @audit_in_self_audit.reload
    assert_equal(12, @audit_in_self_audit.design_checks.size)
    
    actual_checks = {}
    @audit_in_self_audit.design_checks.each do |design_check|
      assert_equal(@audit_in_self_audit.id, design_check.audit_id)
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
  
    assert_equal(11, @audit_in_self_audit.check_count[:designer])
    assert_equal(4,  @audit_in_self_audit.check_count[:peer])
    assert_equal(11, @audit_in_self_audit.self_check_count)
    assert_equal(4,  @audit_in_self_audit.peer_check_count)
    
    la454c3_audit = audits(:audit_la454c3)
    assert_equal(7, la454c3_audit.check_count[:designer])
    assert_equal(5, la454c3_audit.check_count[:peer])
    assert_equal(7, la454c3_audit.self_check_count)
    assert_equal(5, la454c3_audit.peer_check_count)
    
    la453b_eco2_audit = audits(:audit_la453b_eco2)
    assert_equal(7, la453b_eco2_audit.check_count[:designer])
    assert_equal(5, la453b_eco2_audit.check_count[:peer])
    assert_equal(7, la453b_eco2_audit.self_check_count)
    assert_equal(5, la453b_eco2_audit.peer_check_count)
    
  end
  
  ######################################################################
  def test_completion_stats
  
    assert_equal(" 91", 
                 sprintf("%3.f", @audit_in_self_audit.completion_stats[:self]))
    assert_equal("  0", 
                 sprintf("%3.f", @audit_in_self_audit.completion_stats[:peer]))
    assert_equal(" 91", 
                 sprintf("%3.f", @audit_in_self_audit.self_percent_complete))
    assert_equal("  0", 
                 sprintf("%3.f", @audit_in_self_audit.peer_percent_complete))
    
    assert_equal("100", 
                 sprintf("%3.f", @audit_in_peer_audit.completion_stats[:self]))
    assert_equal(" 75", 
                 sprintf("%3.f", @audit_in_peer_audit.completion_stats[:peer]))
    assert_equal("100", 
                 sprintf("%3.f", @audit_in_peer_audit.self_percent_complete))
    assert_equal(" 75", 
                 sprintf("%3.f", @audit_in_peer_audit.peer_percent_complete))

    assert_equal("100", 
                 sprintf("%3.f", @audit_complete.completion_stats[:self]))
    assert_equal("100", 
                 sprintf("%3.f", @audit_complete.completion_stats[:peer]))
    assert_equal("100", 
                 sprintf("%3.f", @audit_complete.self_percent_complete))
    assert_equal("100", 
                 sprintf("%3.f", @audit_complete.peer_percent_complete))

  end
  
  
  ######################################################################
  def test_completion_counts
  
    design_check_15730 = design_checks(:audit_109_design_check_15730)
  
    assert_equal(7, @audit_109.completed_self_audit_check_count(@subsection_537))
    assert_equal(2, @audit_109.completed_self_audit_check_count(@subsection_548))

    assert_equal(0, @audit_109.completed_peer_audit_check_count(@subsection_537))
    
    design_check_15730.auditor_result = "APPROVED"
    design_check_15730.update
    @audit_109.reload
    
    assert_equal(1, @audit_109.completed_peer_audit_check_count(@subsection_537))

    design_check_15730.auditor_result = "None"
    design_check_15730.update
    @audit_109.reload
    
    assert_equal(0, @audit_109.completed_peer_audit_check_count(@subsection_537))
  
  end
  

  ######################################################################
  def test_audit_teammate
  
    # Initially there are no audit teammates for this section.
    section = @subsection_537.section
    assert_nil(@audit_109.get_section_teammate(section))
    
    #Create a teammate records for this audit section.
    AuditTeammate.new(:audit_id   => @audit_109.id,
                      :section_id => section.id,
                      :user_id    => @scott_g.id,
                      :self       => 1).save
    AuditTeammate.new(:audit_id   => @audit_109.id,
                      :section_id => section.id,
                      :user_id    => @bob_g.id,
                      :self       => 0).save
    
    # Verify that the peer audit teammate is returned.
    @audit_109.audit_teammates.reload
    assert_equal(@bob_g, @audit_109.get_section_teammate(section))
    
    # Verify that the self audit teammate is returned.
    @audit_109.designer_complete = 0
    assert_equal(@scott_g, @audit_109.get_section_teammate(section))

  end


  ######################################################################
  def test_section_auditor
  
    # Initially there are no audit teammates for this section.
    # Scott - Designer
    # Bob   - Peer
    section = @subsection_537.section
    @audit_109.designer_complete = 0
    
    assert(!@audit_109.section_auditor?(section, @siva_e))
    assert(!@audit_109.section_auditor?(section, @bob_g))
    assert( @audit_109.section_auditor?(section, @scott_g))
    
    @audit_109.designer_complete = 1
    
    assert(!@audit_109.section_auditor?(section, @siva_e))
    assert( @audit_109.section_auditor?(section, @bob_g))
    assert(!@audit_109.section_auditor?(section, @scott_g))
    
    @audit_109.auditor_complete = 1
    
    assert(!@audit_109.section_auditor?(section, @siva_e))
    assert(!@audit_109.section_auditor?(section, @bob_g))
    assert(!@audit_109.section_auditor?(section, @scott_g))
    
    #Create a teammate records for this audit section.
    # Rich - self audit teammate
    # Siva - peer audit teammate
    AuditTeammate.new(:audit_id   => @audit_109.id,
                      :section_id => section.id,
                      :user_id    => @siva_e.id,
                      :self       => 1).save
    AuditTeammate.new(:audit_id   => @audit_109.id,
                      :section_id => section.id,
                      :user_id    => @rich_m.id,
                      :self       => 0).save

    @audit_109.audit_teammates.reload
    @audit_109.designer_complete = 0
    @audit_109.auditor_complete  = 0

    assert(!@audit_109.section_auditor?(section, @rich_m))
    assert( @audit_109.section_auditor?(section, @siva_e))
    assert(!@audit_109.section_auditor?(section, @scott_g))

    @audit_109.designer_complete = 1
    
    assert(!@audit_109.section_auditor?(section, @siva_e))
    assert(!@audit_109.section_auditor?(section, @scott_g))
    assert(!@audit_109.section_auditor?(section, @bob_g))
    assert( @audit_109.section_auditor?(section, @rich_m))
    
    @audit_109.auditor_complete = 1

    assert(!@audit_109.section_auditor?(section, @siva_e))
    assert(!@audit_109.section_auditor?(section, @scott_g))
    assert(!@audit_109.section_auditor?(section, @bob_g))
    assert(!@audit_109.section_auditor?(section, @rich_m))
    
  end
  

  ######################################################################
  def test_filtered_checklist
  
    full_checklist = [ 
      { :section => sections(:section_344) },   # sort order:  1
      { :section => sections(:section_345) },   # sort order:  2
      { :section => sections(:section_332) },   # sort order:  3
      { :section => sections(:section_333) },   # sort order:  4
      { :section => sections(:section_334) },   # sort order:  5
      { :section => sections(:section_335) },   # sort order:  6
      { :section => sections(:section_336) },   # sort order:  7
      { :section => sections(:section_331) },   # sort order:  8
      { :section => sections(:section_337) },   # sort order:  9
      { :section => sections(:section_338) },   # sort order: 10
      { :section => sections(:section_339) },   # sort order: 11
      { :section => sections(:section_340) },   # sort order: 12
      { :section => sections(:section_330) },   # sort order: 13
      { :section => sections(:section_341) },   # sort order: 14
      { :section => sections(:section_342) },   # sort order: 15
      { :section => sections(:section_343) }    # sort order: 16
    ]
    
    @audit_109.designer_complete = 0
    
    assert_equal(full_checklist.size, @audit_109.checklist.sections.size) 
    @audit_109.checklist.sections.each_with_index do |section, i|

      expected_section = full_checklist[i][:section]
      assert_equal(expected_section,                  section)
      assert_equal(expected_section.subsections.size, section.subsections.size)

      section.subsections.each_with_index do |subsection, j|
      
        expected_subsection = expected_section.subsections[j]
        assert_equal(expected_subsection, subsection)
      
      end
      
    end

    @audit_109.filtered_checklist(@scott_g)

    full_checklist = [ 
      { :section => sections(:section_344) },   # sort order:  1
      { :section => sections(:section_345) },   # sort order:  2
      { :section => sections(:section_332) },   # sort order:  3
      { :section => sections(:section_333) },   # sort order:  4
      { :section => sections(:section_334) },   # sort order:  5
      { :section => sections(:section_335) },   # sort order:  6
      { :section => sections(:section_336) },   # sort order:  7
      { :section => sections(:section_331) },   # sort order:  8
      { :section => sections(:section_337) },   # sort order:  9
      { :section => sections(:section_338) },   # sort order: 10
      { :section => sections(:section_339) },   # sort order: 11
      { :section => sections(:section_340) },   # sort order: 12
      { :section => sections(:section_330) },   # sort order: 13
      { :section => sections(:section_341) },   # sort order: 14
      { :section => sections(:section_342) },   # sort order: 15
      { :section => sections(:section_343) }    # sort order: 16
    ]
    
    assert_equal(full_checklist.size, @audit_109.checklist.sections.size) 
    @audit_109.checklist.sections.each_with_index do |section, i|

      expected_section = full_checklist[i][:section]
      assert_equal(expected_section,                  section)
      assert_equal(expected_section.subsections.size, section.subsections.size)

      section.subsections.each_with_index do |subsection, j|
      
        expected_subsection = expected_section.subsections[j]
        assert_equal(expected_subsection, subsection)
      
      end
      
    end


    @audit_109.reload
    @audit_109.design.design_type = 'Dot Rev'
    @audit_109.filtered_checklist(@scott_g)

    dot_rev_checklist = [ 
      { :section => sections(:section_344) },   # sort order:  1
      { :section => sections(:section_331) },   # sort order:  8
      { :section => sections(:section_330) },   # sort order: 13
      { :section => sections(:section_341) },   # sort order: 14
      { :section => sections(:section_342) },   # sort order: 15
      { :section => sections(:section_343) }    # sort order: 16
    ]
    
    assert_equal(dot_rev_checklist.size, @audit_109.checklist.sections.size) 
    @audit_109.checklist.sections.each_with_index do |section, i|

      expected_section = dot_rev_checklist[i][:section]
      expected_section.subsections.delete_if { |ss| !ss.dot_rev_check? }
      assert_equal(expected_section,                  section)
      assert_equal(expected_section.subsections.size, section.subsections.size)

      section.subsections.each_with_index do |subsection, j|
      
        expected_subsection = expected_section.subsections[j]
        assert_equal(expected_subsection, subsection)
      
      end
      
    end
     
          
    @audit_109.reload
    @audit_109.design.design_type = 'Date Code'
    @audit_109.filtered_checklist(@scott_g)

    date_code_checklist = [ 
      { :section => sections(:section_344) },   # sort order:  1
      { :section => sections(:section_331) },   # sort order:  8
      { :section => sections(:section_330) },   # sort order: 13
      { :section => sections(:section_341) },   # sort order: 14
      { :section => sections(:section_342) },   # sort order: 15
      { :section => sections(:section_343) }    # sort order: 16
    ]
    
    assert_equal(date_code_checklist.size, @audit_109.checklist.sections.size) 
    @audit_109.checklist.sections.each_with_index do |section, i|

      expected_section = date_code_checklist[i][:section]
      expected_section.subsections.delete_if { |ss| !ss.date_code_check? }
      assert_equal(expected_section,                  section)
      assert_equal(expected_section.subsections.size, section.subsections.size)

      section.subsections.each_with_index do |subsection, j|
      
        expected_subsection = expected_section.subsections[j]
        assert_equal(expected_subsection, subsection)
      
      end
      
    end
    
    
    @audit_109.reload
    @audit_109.filtered_checklist(@bob_g)

    full_checklist = [ 
      { :section => sections(:section_332) },   # sort order:  3
      { :section => sections(:section_335) },   # sort order:  6
      { :section => sections(:section_336) },   # sort order:  7
      { :section => sections(:section_331) },   # sort order:  8
      { :section => sections(:section_337) },   # sort order:  9
      { :section => sections(:section_338) },   # sort order: 10
      { :section => sections(:section_339) },   # sort order: 11
      { :section => sections(:section_340) },   # sort order: 12
      { :section => sections(:section_330) },   # sort order: 13
      { :section => sections(:section_341) },   # sort order: 14
      { :section => sections(:section_342) },   # sort order: 15
      { :section => sections(:section_343) }    # sort order: 16
    ]
    
    assert_equal(full_checklist.size, @audit_109.checklist.sections.size) 
    @audit_109.checklist.sections.each_with_index do |section, i|

      expected_section = full_checklist[i][:section]
      expected_section.reload
      assert_equal(expected_section, section)
      
      expected_section.subsections.delete_if { |ss| ss.designer_auditor_checks == 0 }
      assert_equal(expected_section.subsections.size, section.subsections.size)

      section.subsections.each_with_index do |subsection, j|
      
        expected_subsection = expected_section.subsections[j]
        assert_equal(expected_subsection, subsection)
      
      end
      
    end

  end
  
  ######################################################################
  def test_update_type
  
    assert_equal(:peer, @audit_109.update_type(@bob_g))
    assert_equal(:none, @audit_109.update_type(@scott_g))
    assert_equal(:none, @audit_109.update_type(@rich_m))
  
    @audit_109.designer_complete = 0
    
    assert_equal(:none, @audit_109.update_type(@bob_g))
    assert_equal(:self, @audit_109.update_type(@scott_g))
    assert_equal(:none, @audit_109.update_type(@rich_m))    
    
  end

  ######################################################################
  def test_class_methods
  
    incomplete_audits = Audit.find_incomplete_audits
    assert(incomplete_audits.size < Audit.count)  

    incomplete_audits.each { |a|  assert(!a.is_complete?) }
  
    jims_audits = Audit.active_audits(users(:jim_l))
    assert(jims_audits.size == 0)
    
    bobs_expected_audits = [audits(:audit_mx700b), 
                            audits(:audit_la453a1), 
                            audits(:audit_109)]
    bobs_audits = Audit.active_audits(@bob_g)
    assert_equal(bobs_expected_audits.size, bobs_audits.size)
    
    bobs_expected_audits.each_with_index do |a,i| 
      assert_equal(a.design.name, bobs_audits[i].design.name) 
    end
  
    scotts_expected_audits = [audits(:audit_mx234a), 
                              audits(:audit_in_self_audit), 
                              audits(:audit_la454c3),
                              audits(:audit_mx234b), 
                              audits(:audit_mx600a), 
                              audits(:audit_mx234c)]
    scotts_audits = Audit.active_audits(@scott_g)
    assert_equal(scotts_expected_audits.size, scotts_audits.size)
    
    scotts_expected_audits.each_with_index do |a,i| 
      assert_equal(a.design.name, scotts_audits[i].design.name) 
    end
  
    richs_expected_audits = [audits(:audit_in_peer_audit), 
                             audits(:audit_in_self_audit), 
                             audits(:audit_la455b),
                             audits(:audit_la453b_eco2), 
                             audits(:audit_la453a2), 
                             audits(:audit_la453a_eco1),
                             audits(:audit_la453b)]
    richs_audits = Audit.active_audits(@rich_m)
    assert_equal(richs_expected_audits.size, richs_audits.size)
    
    richs_expected_audits.each_with_index do |a,i| 
      assert_equal(a.design.name, richs_audits[i].design.name) 
    end
  
    cathys_expected_audits = [audits(:audit_in_self_audit), 
                              audits(:audit_mx234b)]
    cathys_audits = Audit.active_audits(@cathy_m)
    assert_equal(cathys_expected_audits.size, cathys_audits.size)
    
    cathys_expected_audits.each_with_index do |a,i| 
      assert_equal(a.design.name, cathys_audits[i].design.name) 
    end
  
  end
  
  ######################################################################
  def no_test_dump_audits
  
    audits = Audit.find(:all)
    
    puts
    audits.each do |a|
    
      puts("================================================")
      puts("ID:                  #{a.id}")
      puts("DESIGN:              #{a.design.name}")
      puts("LEAD DESIGNER:       #{a.design.designer.name}")
      puts("LEAD PEER:           #{a.design.peer.name}")
      puts("SELF AUDIT:          Yes") if a.is_self_audit?
      puts("PEER AUDIT:          Yes") if a.is_peer_audit?
      puts("COMPLETE:            Yes") if a.is_complete?
      puts("NUMBER OF TEAMMATES: #{a.audit_teammates.size}")
      
      a.audit_teammates.each do |at|
        puts("  AUDITOR:           #{at.user.name}")
        puts("  SELF:              YES") if at.self?
        puts("  PEER:              YES") if !at.self?
      end
    
    end
    
    puts("================================================")
  
  end

end
