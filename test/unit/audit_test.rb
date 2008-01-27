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
           :design_reviews,
           :design_review_results,
           :part_numbers,
           :prefixes,
           :priorities,
           :review_types,
           :revisions,
           :roles,
           :sections,
           :subsections,
           :users

  def setup
  
    @audit_mx234b        = audits(:audit_mx234b)
    @audit_in_self_audit = audits(:audit_in_self_audit)
    @audit_in_peer_audit = audits(:audit_in_peer_audit)
    @audit_complete      = audits(:audit_complete)
    @audit_109           = audits(:audit_109)
    @audit_mx700b        = audits(:audit_mx700b)
    
    @subsection_537      = subsections(:subsection_537)
    @subsection_548      = subsections(:subsection_548)
      
    @bob_g   = users(:bob_g)
    @rich_m  = users(:rich_m)
    @scott_g = users(:scott_g)
    @siva_e  = users(:siva_e)
    @cathy_m = users(:cathy_m)

    @emails     = ActionMailer::Base.deliveries
    @emails.clear

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
  def test_checklist_methods
    
    #
    #                         section  subsection  array of check ids
    #                         id       id
    full_review_checks     = {3 =>    {5 =>        [14],
                                       6 =>        [15, 16, 17, 24]},
                              4 =>    {7 =>        [18, 19, 20],
                                       8 =>        [21, 22, 23]}}
                                       
    expected_full_design_check_count = 0
    full_review_checks.each_value do |subsection|
      subsection.each_value { |checks| expected_full_design_check_count += checks.size}
    end


    #
    #                        section  subsection  array of check ids
    #                        id       id
    partial_review_checks  = {3 =>   {5 =>        [13, 14]}}

    expected_partial_design_check_count = 0
    partial_review_checks.each_value do |subsection|
      subsection.each_value { |checks| expected_partial_design_check_count += checks.size}
    end

    
    design_check_count = DesignCheck.count

    audit = Audit.new(:checklist_id => 2,
                      :design_id    => @audit_mx700b.design_id)
    audit.save
    audit.reload

    audit.create_checklist
    assert_equal(design_check_count + expected_full_design_check_count, DesignCheck.count)
    assert_equal(expected_full_design_check_count, audit.design_checks.size)
    assert_equal(11,                               audit.self_check_count)
    assert_equal(11,                               audit.checklist.full_review_self_check_count)
    assert_equal(4,                                audit.peer_check_count)
    assert_equal(4,                                audit.checklist.full_review_peer_check_count)

    actual_checks = {}
    audit.design_checks.each do |design_check|
      assert_equal(audit.id, design_check.audit_id)
      section_id    = design_check.check.subsection.section_id
      subsection_id = design_check.check.subsection_id
      actual_checks[section_id] = {} if !actual_checks[section_id]
      actual_checks[section_id][subsection_id] = [] if !actual_checks[section_id][subsection_id]
      actual_checks[section_id][subsection_id] << design_check.check_id
    end

    assert_equal(full_review_checks, actual_checks)

    
    audit.design.design_type = 'Dot Rev'
    audit.design.update
    audit.update_checklist_type

    audit.reload
    assert_equal(expected_partial_design_check_count, audit.design_checks.size)
    assert_equal(2,                                   audit.self_check_count)
    assert_equal(2,                                   audit.checklist.partial_review_self_check_count)
    assert_equal(2,                                   audit.peer_check_count)
    assert_equal(2,                                   audit.checklist.partial_review_peer_check_count)
    
    actual_checks = {}
    audit.design_checks.each do |design_check|
      assert_equal(audit.id, design_check.audit_id)
      section_id    = design_check.check.subsection.section_id
      subsection_id = design_check.check.subsection_id
      actual_checks[section_id] = {} if !actual_checks[section_id]
      actual_checks[section_id][subsection_id] = [] if !actual_checks[section_id][subsection_id]
      actual_checks[section_id][subsection_id] << design_check.check_id
    end

    partial_review_checks.each do |section_id, section|
      section.each do |subsection_id, subsection|
        assert_equal(subsection, actual_checks[section_id][subsection_id].sort)
      end
    end    

    assert_equal(design_check_count + expected_partial_design_check_count, DesignCheck.count)
    
    audit.design.design_type = 'New'
    audit.design.update
    audit.update_checklist_type
    
    audit.reload
    audit.design_checks.each do |dc|
      next if !dc.check.full_review?
      dc.designer_result = 'Verified'  if dc.check.is_self_check?
      dc.auditor_result  = 'Verified'  if dc.check.is_peer_check?
      dc.save
    end
    
    audit.designer_completed_checks = 11
    audit.auditor_completed_checks  = 4
    audit.designer_complete         = 1
    audit.auditor_complete          = 1
    audit.save
    
    audit.reload
    assert_equal(design_check_count + expected_full_design_check_count, DesignCheck.count)
    completed_check_count = audit.completed_check_count
    assert_equal(11,  completed_check_count[:self])
    assert_equal(4,   completed_check_count[:peer])
    assert_equal(100, audit.self_percent_complete)
    assert_equal(100, audit.peer_percent_complete)
    assert(audit.designer_complete?)
    assert(audit.auditor_complete?)
 
    
    audit.design.design_type = 'Dot Rev'
    audit.design.update
    audit.update_checklist_type
    
    audit.reload
    assert_equal(design_check_count + expected_partial_design_check_count, DesignCheck.count)
    completed_check_count = audit.completed_check_count
    assert_equal(1, completed_check_count[:self])
    assert_equal(1, completed_check_count[:peer])
    assert_equal(50.0, audit.self_percent_complete)
    assert_equal(50.0, audit.peer_percent_complete)
    assert(!audit.designer_complete?)
    assert(!audit.auditor_complete?)
    
    
    audit.design.design_type = 'New'
    audit.design.update
    audit.update_checklist_type
    
    audit.reload
    assert_equal(design_check_count + expected_full_design_check_count, DesignCheck.count)
    completed_check_count = audit.completed_check_count
    assert_equal(1, completed_check_count[:self])
    assert_equal(1, completed_check_count[:peer])
    assert_equal("9.09", sprintf("%3.2f", audit.self_percent_complete))
    assert_equal(25.0,   audit.peer_percent_complete)
    assert(!audit.designer_complete?)
    assert(!audit.auditor_complete?)
    
  end

  
  ######################################################################
  def test_check_counts
  
    assert_equal(11, @audit_in_self_audit.check_count[:designer])
    assert_equal(4,  @audit_in_self_audit.check_count[:peer])
    assert_equal(11, @audit_in_self_audit.self_check_count)
    assert_equal(4,  @audit_in_self_audit.peer_check_count)
    
    la454c3_audit = audits(:audit_la454c3)
    assert_equal(2, la454c3_audit.check_count[:designer])
    assert_equal(2, la454c3_audit.check_count[:peer])
    assert_equal(2, la454c3_audit.self_check_count)
    assert_equal(2, la454c3_audit.peer_check_count)
    
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
    design_check_15730.save
    @audit_109.reload
    
    assert_equal(1, @audit_109.completed_peer_audit_check_count(@subsection_537))

    design_check_15730.auditor_result = "None"
    design_check_15730.save
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
      
      expected_section.subsections.delete_if { |ss| ss.designer_auditor_check_count == 0 }
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
    
    assert(!@audit_109.self_update?(@bob_g))
    assert(!@audit_109.self_update?(@scott_g))
    assert(!@audit_109.self_update?(@rich_m))
    assert( @audit_109.peer_update?(@bob_g))
    assert(!@audit_109.peer_update?(@scott_g))
    assert(!@audit_109.peer_update?(@rich_m))
  
    @audit_109.designer_complete = 0
    
    assert_equal(:none, @audit_109.update_type(@bob_g))
    assert_equal(:self, @audit_109.update_type(@scott_g))
    assert_equal(:none, @audit_109.update_type(@rich_m))    

    assert(!@audit_109.self_update?(@bob_g))
    assert( @audit_109.self_update?(@scott_g))
    assert(!@audit_109.self_update?(@rich_m))
    assert(!@audit_109.peer_update?(@bob_g))
    assert(!@audit_109.peer_update?(@scott_g))
    assert(!@audit_109.peer_update?(@rich_m))
    
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
  def test_process_audit_updates
  
    # Validate self updates
    design_check_1        = design_checks(:design_check_20_2000)
    completed_self_checks = @audit_mx234b.designer_completed_checks
      
    assert_equal('None', design_check_1.designer_result)


    start_time = Time.now
    @audit_mx234b.process_self_audit_update('Verified', design_check_1, @rich_m)
    
    completed_self_checks += 1
    design_check_1.reload
    assert_equal(completed_self_checks, @audit_mx234b.designer_completed_checks)
    assert_equal('Verified',            design_check_1.designer_result)
    assert_equal(@rich_m.id,            design_check_1.designer_id)
    assert(start_time.to_i <= design_check_1.designer_checked_on.to_i)
    assert(Time.now.to_i   >= design_check_1.designer_checked_on.to_i)
    checked_on = design_check_1.designer_checked_on

    @audit_mx234b.process_self_audit_update('N/A', design_check_1, @scott_g)
    
    design_check_1.reload
    assert_equal(completed_self_checks, @audit_mx234b.designer_completed_checks)
    assert_equal('N/A',                 design_check_1.designer_result)
    assert_equal(@scott_g.id,           design_check_1.designer_id)
    
    assert(checked_on.to_i <= design_check_1.designer_checked_on.to_i)
    assert(Time.now.to_i   >= design_check_1.designer_checked_on.to_i)
    
    
    audit_mx234b_other = Audit.find(@audit_mx234b.id)
    design_check_2 = DesignCheck.find(design_checks(:design_check_20_2001).id)
    design_check_3 = DesignCheck.find(design_checks(:design_check_20_2005).id)
    design_check_4 = DesignCheck.find(design_checks(:design_check_20_2002).id)
    
    assert_equal('None',                design_check_2.designer_result)
    assert_equal('None',                design_check_3.designer_result)
    assert_equal(completed_self_checks, audit_mx234b_other.designer_completed_checks)

    # Verify the exception handling works when one instance of an audit contains
    # stale information.  @audit_mx234b contains stale information after 
    # audit_mx234b_other.process_self_audit_update is called.
    audit_mx234b_other.process_self_audit_update('Verified', design_check_2, @rich_m)
    
    assert_equal(completed_self_checks, @audit_mx234b.designer_completed_checks)

    completed_self_checks += 1
    design_check_2.reload
    assert_equal(completed_self_checks, audit_mx234b_other.designer_completed_checks)
    assert_equal('Verified',            design_check_2.designer_result)
    assert_equal(@rich_m.id,            design_check_2.designer_id)
    assert(completed_self_checks != @audit_mx234b.designer_completed_checks)
    
    @audit_mx234b.process_self_audit_update('Verified', design_check_3, @rich_m)
    
    completed_self_checks += 1
    assert_equal(completed_self_checks, @audit_mx234b.designer_completed_checks)

    audit_mx234b_other.reload
    assert_equal(completed_self_checks, audit_mx234b_other.designer_completed_checks)
    
    @audit_mx234b.design_checks.each do |design_check|
      assert(!@audit_mx234b.designer_complete?)
      @audit_mx234b.process_self_audit_update('Verified', design_check, @rich_m)
    end
    completed_self_checks = @audit_mx234b.design_checks.size
    assert(@audit_mx234b.designer_complete?)
    assert_equal(completed_self_checks, @audit_mx234b.designer_completed_checks)


    # Validate peer updates
    completed_peer_checks = @audit_mx234b.auditor_completed_checks
    
    assert_equal('None', design_check_1.auditor_result)

    start_time = Time.now
    comment    = 'Peer Reviewer Comment'
    @audit_mx234b.process_peer_audit_update('Verified', comment, design_check_1, @bob_g)
    
    completed_peer_checks += 1
    design_check_1.reload
    assert_equal(completed_peer_checks, @audit_mx234b.auditor_completed_checks)
    assert_equal('Verified',            design_check_1.auditor_result)
    assert_equal(@bob_g.id,             design_check_1.auditor_id)
    assert(start_time.to_i <= design_check_1.auditor_checked_on.to_i)
    assert(Time.now.to_i   >= design_check_1.auditor_checked_on.to_i)
    
    start_time = Time.now

    @audit_mx234b.process_peer_audit_update('N/A', comment, design_check_1, @bob_g)
    
    design_check_1.reload
    assert_equal('N/A',     design_check_1.auditor_result)
    assert_equal(@bob_g.id, design_check_1.auditor_id)
    assert(start_time.to_i <= design_check_1.auditor_checked_on.to_i)
    assert(Time.now.to_i   >= design_check_1.auditor_checked_on.to_i)
    assert(completed_peer_checks, @audit_mx234b.auditor_completed_checks)

    start_time = Time.now

    @audit_mx234b.process_peer_audit_update('Comment', comment, design_check_1, @bob_g)

    completed_peer_checks -= 1
    design_check_1.reload
    assert_equal('Comment', design_check_1.auditor_result)
    assert_equal(@bob_g.id, design_check_1.auditor_id)
    assert(start_time.to_i <= design_check_1.auditor_checked_on.to_i)
    assert(Time.now.to_i   >= design_check_1.auditor_checked_on.to_i)
    assert(completed_peer_checks, @audit_mx234b.auditor_completed_checks)
    
    
    audit_mx234b_other = Audit.find(@audit_mx234b.id)

    assert_equal('None', design_check_2.auditor_result)
    assert_equal('None', design_check_4.auditor_result)

    # Verify the exception handling works when one instance of an audit contains
    # stale information.  @audit_mx234b contains stale information after 
    # audit_mx234b_other.process_self_audit_update is called.
    audit_mx234b_other.process_peer_audit_update('Verified', comment, design_check_2, @bob_g)
    
    # @audit_mx234b has stale information. So it's completed check count is off - which is OK.
    assert_equal(completed_peer_checks, @audit_mx234b.auditor_completed_checks)

    completed_peer_checks += 1
    design_check_2.reload
    assert_equal(completed_peer_checks, audit_mx234b_other.auditor_completed_checks)
    assert_equal('Verified',            design_check_2.auditor_result)
    assert_equal(@bob_g.id,             design_check_2.auditor_id)
    assert(completed_peer_checks != @audit_mx234b.auditor_completed_checks)
    
    @audit_mx234b.process_peer_audit_update('Verified', comment, design_check_4, @bob_g)
    
    completed_peer_checks += 1
    assert_equal(completed_peer_checks, @audit_mx234b.auditor_completed_checks)

    audit_mx234b_other.reload
    assert_equal(completed_peer_checks, audit_mx234b_other.auditor_completed_checks)
    
    @audit_mx234b.design_checks.each do |design_check|
      assert(!@audit_mx234b.auditor_complete?)
      @audit_mx234b.process_peer_audit_update('Verified', comment, design_check, @bob_g)
    end
    assert(@audit_mx234b.auditor_complete?)

  end


  ######################################################################
  def test_manage_auditor_list
    
    assert_equal(0, @audit_109.audit_teammates.size)
    
    scott = @scott_g.id.to_s
    bob   = @bob_g.id.to_s
    
    update_message = 'Updates to the audit team for the ' +
                     @audit_109.design.part_number.pcb_display_name +
                     ' have been recorded - mail was sent'
    
    subj_audit_team_updated = 'The audit team for the pcb252_232_b0_e has been updated'
    
    self_auditors = { 330 => scott, 331 => scott, 332 => scott,
                      333 => scott, 334 => scott, 335 => scott,
                      336 => scott, 337 => scott, 338 => scott,
                      339 => scott, 340 => scott, 341 => scott,
                      342 => scott, 343 => scott, 344 => scott,
                      345 => scott }
    peer_auditors = { 330 => bob,   331 => bob,   332 => bob,
                      333 => bob,   334 => bob,   335 => bob,
                      336 => bob,   337 => bob,   338 => bob,
                      339 => bob,   340 => bob,   341 => bob,
                      342 => bob,   343 => bob,   344 => bob,
                      345 => bob }

    #--------------- TESTING - AN UNALTERED LIST
    @audit_109.manage_auditor_list(self_auditors.dup, peer_auditors.dup, @scott_g)
    
    assert_equal(0, @emails.size)
    assert_equal(0, @audit_109.audit_teammates.size)
    
    #--------------- TESTING - USING SIVA (SELF) TO ROUTE PLANES
    self_auditors[336] = @siva_e.id.to_s
    @audit_109.manage_auditor_list(self_auditors.dup, peer_auditors.dup, @scott_g)
    
    assert_equal(1,                      @emails.size)
    email = @emails.pop
    assert_equal(subj_audit_team_updated, email.subject)
    assert(email.body =~ /Added Siva Esakky - Route - Planes/)
    
    assert_equal(1,            @audit_109.audit_teammates.size)
    audit_teammate = @audit_109.audit_teammates.first
    assert_equal(@siva_e.name, audit_teammate.user.name)
    assert(audit_teammate.self?)
    assert(@audit_109.message?)
    assert_equal(update_message, @audit_109.message)
    
    #-------------- TESTING - USING SIVA (SELF) TO ROUTE PLANES (NO CHANGE)
    @audit_109.manage_auditor_list(self_auditors.dup, peer_auditors.dup, @scott_g)
    
    assert_equal(0, @emails.size)
    assert_equal(1, @audit_109.audit_teammates.size)
    audit_teammate = @audit_109.audit_teammates.first
    assert_equal(@siva_e.name, audit_teammate.user.name)
    assert(audit_teammate.self?)
    assert(!@audit_109.message?)

    #--------------- TESTING - ASSIGNING ROUTE PLANES BACK TO THE LEAD DESIGNER
    self_auditors[336] = scott
    @audit_109.manage_auditor_list(self_auditors.dup, peer_auditors.dup, @scott_g)
    
    assert_equal(1,@emails.size)
    email = @emails.pop
    assert_equal(subj_audit_team_updated, email.subject)
    assert(email.body =~ /Removed Siva Esakky - Route - Planes/)
    
    assert_equal(0, @audit_109.audit_teammates.size)
    assert(@audit_109.message?)
    assert_equal(update_message, @audit_109.message)

    #--------------- TESTING - USING SIVA (PEER) TO ROUTE PLANES
    peer_auditors[336] = @siva_e.id.to_s
    @audit_109.manage_auditor_list(self_auditors.dup, peer_auditors.dup, @scott_g)
    
    assert_equal(1,                      @emails.size)
    email = @emails.pop
    assert_equal(subj_audit_team_updated, email.subject)
    assert(email.body =~ /Added Siva Esakky - Route - Planes/)
    
    assert_equal(1, @audit_109.audit_teammates.size)
    audit_teammate = @audit_109.audit_teammates.first
    assert_equal(@siva_e.name, audit_teammate.user.name)
    assert(!audit_teammate.self?)
    assert(@audit_109.message?)
    assert_equal(update_message, @audit_109.message)
    
    
    #--------------- TESTING - USING SIVA (PEER) TO ROUTE PLANES (NO CHANGE)
    @audit_109.manage_auditor_list(self_auditors.dup, peer_auditors.dup, @scott_g)
    
    assert_equal(0, @emails.size)
    assert_equal(1, @audit_109.audit_teammates.size)
    audit_teammate = @audit_109.audit_teammates.first
    assert_equal(@siva_e.name, audit_teammate.user.name)
    assert(!audit_teammate.self?)
    assert(!@audit_109.message?)

    #--------------- TESTING - ASSIGNING ROUTE PLANES BACK TO THE LEAD PEER
    peer_auditors[336] = bob
    @audit_109.manage_auditor_list(self_auditors.dup, peer_auditors.dup, @bob_g)
    
    assert_equal(1,@emails.size)
    email = @emails.pop
    assert_equal(subj_audit_team_updated, email.subject)
    assert(email.body =~ /Removed Siva Esakky - Route - Planes/)
    
    assert_equal(0, @audit_109.audit_teammates.size)
    assert(@audit_109.message?)
    assert_equal(update_message, @audit_109.message)

    #--------------- TESTING - ASSIGNING ROUTE PLANES TO SIVA SELF/PEER
    peer_auditors[336] = @siva_e.id.to_s
    self_auditors[336] = @siva_e.id.to_s
    @audit_109.manage_auditor_list(self_auditors.dup, peer_auditors.dup, @bob_g)
    
    assert_equal(0,@emails.size)
    assert_equal(0, @audit_109.audit_teammates.size)
    assert(@audit_109.message?)
    sect = Section.find(336)
    assert_equal('WARNING: Assignments not made <br />' + '         ' + 
                 @siva_e.name + ' can not be both ' +
                 'self and peer auditor for ' + sect.name + '<br />',
                 @audit_109.message)

    #--------------- TESTING - ASSIGNING ROUTE PLANES TO SIVA SELF/PEER
    peer_auditors[336] = @siva_e.id.to_s
    peer_auditors[330] = @rich_m.id.to_s
    self_auditors[336] = @siva_e.id.to_s
    self_auditors[330] = @siva_e.id.to_s
    @audit_109.manage_auditor_list(self_auditors.dup, peer_auditors.dup, @bob_g)
    
    assert_equal(1,@emails.size)
    email = @emails.pop
    assert_equal(subj_audit_team_updated, email.subject)
    assert(email.body =~ /Added Siva Esakky - Design Report Check/)
    assert(email.body =~ /Added Rich Miller - Design Report Check/)

    assert_equal(2, @audit_109.audit_teammates.size)
    self_auditor = @audit_109.audit_teammates.first
    assert_equal(@siva_e.id, self_auditor.user_id)
    assert(self_auditor.self?)
    peer_auditor = @audit_109.audit_teammates.last
    assert_equal(@rich_m.id, peer_auditor.user_id)
    assert(!peer_auditor.self?)
    
    assert(@audit_109.message?)
    sect = Section.find(336)
    assert_equal('WARNING: Assignments not made <br />' + '         ' + 
                 @siva_e.name + ' can not be both ' +
                 'self and peer auditor for ' + sect.name + '<br />' +
                 update_message,
                 @audit_109.message)

  end

  
  ######################################################################
  def dump_audits
  
    Audit.find(:all).each { |a| dump_audit(a) }
    
  end
  
  ######################################################################
  def dump_audit(a, message='')

    a.reload
    if message.size > 0
      puts("================================================")
      puts(message)
      puts("================================================")
    end
    puts("================================================")
    puts("ID:                    #{a.id}")
    puts("CHECKLIST ID:          #{a.checklist.id}")
    puts("DESIGN:                #{a.design.name}")
    puts("DESIGN ID:             #{a.design_id}")
    puts("DESIGN TYPE:           #{a.design.design_type}")
    puts("LEAD DESIGNER:         #{a.design.designer.name}")
    puts("LEAD PEER:             #{a.design.peer.name}")
    puts("SELF AUDIT:            Yes") if a.is_self_audit?
    puts("PEER AUDIT:            Yes") if a.is_peer_audit?
    puts("COMPLETE:              Yes") if a.is_complete?
    puts("NUMBER OF TEAMMATES:   #{a.audit_teammates.size}")
    puts("SELF CHECK COUNT:      #{a.self_check_count}")
    puts("SELF COMPLETED CHECKS: #{a.designer_completed_checks}")
    puts("SELF % COMPLETE:       #{a.self_percent_complete}")
    puts("PEER CHECK COUNT:      #{a.peer_check_count}")
    puts("PEER COMPLETED CHECKS: #{a.auditor_completed_checks}")
    puts("PEER % COMPLETE:       #{a.peer_percent_complete}")
      
    if a.audit_teammates.size > 0
      puts("+++ DUMPING AUDIT TEAM")
      a.audit_teammates.each do |at|
        puts("  AUDITOR:           #{at.user.name}")
        puts("  SELF:              YES") if at.self?
        puts("  PEER:              YES") if !at.self?
      end
    end
     
    a.design_checks.reload
    puts("================================================")
    puts("DESIGN CHECKS")
    puts("================================================")
    a.design_checks.each do |dc|
      puts("  Design Check ID: #{dc.id}         Check ID:      #{dc.check_id}")
      puts("                                    Subsection ID: #{dc.check.subsection_id}")
      puts("    DESIGNER: #{User.find(dc.designer_id).name}  RESULT: #{dc.designer_result}") if dc.designer_id > 0
      puts("    DESIGNER RESULT:                #{dc.designer_result}")
      puts("    AUDITOR:  #{User.find(dc.auditor_id).name}   RESULT: #{dc.auditor_result}")  if dc.auditor_id  > 0
      puts("    AUDITOR RESULT:                 #{dc.auditor_result}")
    end

    completed_check_count = a.completed_check_count
    self_completed_checks = completed_check_count[:self]
    peer_completed_checks = completed_check_count[:peer]
    puts("================================================")
    puts("AUDIT CHECKLIST")
    puts("## CHECKLIST ID:        #{a.checklist.id}")
    puts("## REV:                 #{a.checklist.major_rev_number}.#{a.checklist.minor_rev_number}")
    puts("## FULL DESIGNER ONLY COUNT: #{a.checklist.designer_only_count}")
    puts("## COMPUTED:                 #{a.checklist.full_review_self_check_count}")
    puts("## FULL DESIGNER/AUDITOR:    #{a.checklist.designer_auditor_count}")
    puts("## COMPUTED:                 #{a.checklist.full_review_peer_check_count}")
    puts("## PARTIAL DESIGNER ONLY COUNT: #{a.checklist.dr_designer_only_count}")
    puts("## COMPUTED:                    #{a.checklist.partial_review_self_check_count}")
    puts("## PARTIAL DESIGNER/AUDITOR:    #{a.checklist.dr_designer_auditor_count}")
    puts("## COMPUTED:                    #{a.checklist.partial_review_peer_check_count}")
    puts("## NUMBER OF SECTIONS:  #{a.checklist.sections.size.to_s}")
    puts("## SELF COMPLETED:      #{self_completed_checks}")
    puts("## PEER COMPLETED:      #{peer_completed_checks}")
    a.checklist.sections.each do |section|
      puts("#### SECTION ID:            #{section.id}")
      puts("#### FULL:                  #{section.full_review.to_s}")
      puts("#### PARTIAL:               #{section.dot_rev_check.to_s}")
      puts("#### NUMBER OF SUBSECTIONs: #{section.subsections.size.to_s}")
      section.subsections.each do |subsection|
        puts("###### SUBSECTION ID:        #{subsection.id}")
        puts("###### FULL:                 #{subsection.full_review.to_s}")
        puts("###### PARTIAL:              #{subsection.dot_rev_check.to_s}")
        puts("###### SELF COMPLETED COUNT: #{a.completed_self_audit_check_count(subsection)}")
        puts("###### PEER COMPLETED COUNT: #{a.completed_peer_audit_check_count(subsection)}")
        puts("###### NUMBER OF CHECKS:     #{subsection.checks.size.to_s}")
        subsection.checks.each do |check|
          puts("--------  CHECK ID:  #{check.id}")
          puts("--------  FULL:      #{check.full_review.to_s}")
          puts("--------  PARTIAL:   #{check.dot_rev_check.to_s}")
          puts("--------  TYPE       #{check.check_type}")
          design_check = a.design_checks.detect { |dc| dc.check_id == check.id }
          if design_check
            puts("++++++++ DESIGN CHECK ID: #{design_check.id}")
          else
            puts("WARNING - NO DESIGN CHECK") 
          end
        end
      end
    end
    puts("================================================")

  end


  ######################################################################
  def test_update_check_counts
    
    complete_self_checks = @audit_mx234b.designer_completed_checks
    complete_peer_checks = @audit_mx234b.auditor_completed_checks
    
    self_checker_1_copy = Audit.find(@audit_mx234b.id)
    self_checker_2_copy = Audit.find(@audit_mx234b.id)
    peer_checker_1_copy = Audit.find(@audit_mx234b.id)
    peer_checker_2_copy = Audit.find(@audit_mx234b.id)
    
    assert(!@audit_mx234b.designer_complete?)
    assert(!@audit_mx234b.auditor_complete?)
    assert(!self_checker_1_copy.designer_complete?)
    assert(!self_checker_1_copy.auditor_complete?)
    assert(!self_checker_2_copy.designer_complete?)
    assert(!self_checker_2_copy.auditor_complete?)
    
    self_checker_2_copy.update_self_check_count
    @audit_mx234b.reload
    assert_equal(complete_self_checks + 1, @audit_mx234b.designer_completed_checks)
    assert_equal(complete_self_checks,     self_checker_1_copy.designer_completed_checks)
    assert_equal(complete_self_checks + 1, self_checker_2_copy.designer_completed_checks)
    assert_equal(complete_peer_checks,     @audit_mx234b.auditor_completed_checks)
    assert_equal(complete_peer_checks,     peer_checker_1_copy.auditor_completed_checks)
    assert_equal(complete_peer_checks,     peer_checker_2_copy.auditor_completed_checks)
    assert(!@audit_mx234b.designer_complete?)
    assert(!@audit_mx234b.auditor_complete?)
    assert(!self_checker_1_copy.designer_complete?)
    assert(!self_checker_1_copy.auditor_complete?)
    assert(!self_checker_2_copy.designer_complete?)
    assert(!self_checker_2_copy.auditor_complete?)

    self_checker_1_copy.update_self_check_count
    @audit_mx234b.reload
    assert_equal(complete_self_checks + 2, @audit_mx234b.designer_completed_checks)
    assert_equal(complete_self_checks + 2, self_checker_1_copy.designer_completed_checks)
    assert_equal(complete_self_checks + 1, self_checker_2_copy.designer_completed_checks)
    assert_equal(complete_peer_checks,     @audit_mx234b.auditor_completed_checks)
    assert_equal(complete_peer_checks,     peer_checker_1_copy.auditor_completed_checks)
    assert_equal(complete_peer_checks,     peer_checker_2_copy.auditor_completed_checks)
    assert(!@audit_mx234b.designer_complete?)
    assert(!@audit_mx234b.auditor_complete?)
    assert(!self_checker_1_copy.designer_complete?)
    assert(!self_checker_1_copy.auditor_complete?)
    assert(!self_checker_2_copy.designer_complete?)
    assert(!self_checker_2_copy.auditor_complete?)
    

    peer_checker_2_copy.update_peer_check_count
    @audit_mx234b.reload
    assert_equal(complete_self_checks + 2, @audit_mx234b.designer_completed_checks)
    assert_equal(complete_self_checks + 2, self_checker_1_copy.designer_completed_checks)
    assert_equal(complete_self_checks + 1, self_checker_2_copy.designer_completed_checks)
    assert_equal(complete_peer_checks + 1, @audit_mx234b.auditor_completed_checks)
    assert_equal(complete_peer_checks,     peer_checker_1_copy.auditor_completed_checks)
    assert_equal(complete_peer_checks + 1, peer_checker_2_copy.auditor_completed_checks)
    assert(!@audit_mx234b.designer_complete?)
    assert(!@audit_mx234b.auditor_complete?)
    assert(!self_checker_1_copy.designer_complete?)
    assert(!self_checker_1_copy.auditor_complete?)
    assert(!self_checker_2_copy.designer_complete?)
    assert(!self_checker_2_copy.auditor_complete?)
    
    peer_checker_1_copy.update_peer_check_count
    @audit_mx234b.reload
    assert_equal(complete_self_checks + 2, @audit_mx234b.designer_completed_checks)
    assert_equal(complete_self_checks + 2, self_checker_1_copy.designer_completed_checks)
    assert_equal(complete_self_checks + 1, self_checker_2_copy.designer_completed_checks)
    assert_equal(complete_peer_checks + 2, @audit_mx234b.auditor_completed_checks)
    assert_equal(complete_peer_checks + 2, peer_checker_1_copy.auditor_completed_checks)
    assert_equal(complete_peer_checks + 1, peer_checker_2_copy.auditor_completed_checks)
    assert(!@audit_mx234b.designer_complete?)
    assert(!@audit_mx234b.auditor_complete?)
    assert(!self_checker_1_copy.designer_complete?)
    assert(!self_checker_1_copy.auditor_complete?)
    assert(!self_checker_2_copy.designer_complete?)
    assert(!self_checker_2_copy.auditor_complete?)
    
    @audit_mx234b.update_self_check_count(12)
    assert(!@audit_mx234b.designer_complete?)
    self_checker_1_copy.reload
    assert(!self_checker_1_copy.designer_complete?)
    @audit_mx234b.update_self_check_count
    assert(@audit_mx234b.designer_complete?)
    self_checker_1_copy.reload
    assert(self_checker_1_copy.designer_complete?)

    @audit_mx234b.update_peer_check_count(6)
    assert(!@audit_mx234b.auditor_complete?)
    self_checker_1_copy.reload
    assert(!self_checker_1_copy.auditor_complete?)
    @audit_mx234b.update_peer_check_count
    assert(@audit_mx234b.auditor_complete?)
    self_checker_1_copy.reload
    assert(self_checker_1_copy.auditor_complete?)

  end
  
  
  ######################################################################
  def test_teammate_functions 

    # Set up so that self_auditor() and peer_auditor() return nil.
    @audit_109.audit_teammates.destroy_all
    @audit_109.design.designer_id = 0
    @audit_109.design.peer_id     = 0

    section = @audit_109.checklist.sections[0]
    
    assert_nil(@audit_109.self_auditor(section))
    assert_nil(@audit_109.peer_auditor(section))
    
    # Set the designs's lead designerr and peer and verify the results
    @audit_109.design.designer_id = @cathy_m.id
    @audit_109.design.peer_id     = @scott_g.id
    assert_equal(@cathy_m, @audit_109.self_auditor(section))
    assert_equal(@scott_g, @audit_109.peer_auditor(section))
    
    # Set a teammate to as self and peer auditor and verify the result.
    @audit_109.audit_teammates << AuditTeammate.new(:self       => 1,
                                                    :section_id => section.id,
                                                    :user_id    => @bob_g.id)
    @audit_109.audit_teammates << AuditTeammate.new(:self       => 0,
                                                    :section_id => section.id,
                                                    :user_id    => @siva_e.id)
    assert_equal(@bob_g,  @audit_109.self_auditor(section))
    assert_equal(@siva_e, @audit_109.peer_auditor(section))

  end 
  
  
  ######################################################################
  def test_auditor_lists 
    
    active_designers  = Role.active_designers
    peer_auditor_list = active_designers - [@audit_109.design.designer]
    
    assert_equal(active_designers,  @audit_109.self_auditor_list)
    assert_equal(peer_auditor_list, @audit_109.peer_auditor_list)
    
    @audit_mx234b.design.designer_id = 0
    assert_equal(active_designers, @audit_mx234b.self_auditor_list)
    assert_equal(active_designers, @audit_mx234b.peer_auditor_list)
    
  end
  

  ######################################################################
  def test_trim
    
    comparison_copy = Audit.find(@audit_109.id)
    
    @audit_109.trim
    results = create_comparison_hash(@audit_109)
    
    # Verify the trimmed audit contains all of the sections, subsections, and 
    # checks for a full audit.
    comparison_copy.checklist.sections.each do |section|
      section_id = section.id.to_s
      if section.full_review?
        assert_not_nil(results[section_id])
      else
        assert_nil(results[section_id])
      end
      section.subsections.each do |subsection|
        subsection_id = subsection.id.to_s
        if subsection.full_review?
          assert_not_nil(results[section_id+subsection_id])
        else
          assert_nil(results[section_id+subsection_id])
        end
        subsection.checks.each do |check|
          check_id = check.id.to_s
          if check.full_review?
            assert_not_nil(results[section_id+subsection_id+check_id])
          else
            assert_nil(results[section_id+subsection_id+check_id])
          end
        end
      end
    end

    @audit_109.reload
    @audit_109.design.design_type = 'Dot Rev'
    @audit_109.trim
    results = create_comparison_hash(@audit_109)
    
    # Verify the trimmed audit contains all of the sections, subsections, and 
    # checks for a full audit.
    comparison_copy.checklist.sections.each do |section|
      section_id = section.id.to_s
      if section.dot_rev_check?
        assert_not_nil(results[section_id])
      else
        assert_nil(results[section_id])
      end
      section.subsections.each do |subsection|
        subsection_id = subsection.id.to_s
        if subsection.dot_rev_check?
          assert_not_nil(results[section_id+subsection_id])
        else
          assert_nil(results[section_id+subsection_id])
        end
        subsection.checks.each do |check|
          check_id = check.id.to_s
          if check.dot_rev_check?
            assert_not_nil(results[section_id+subsection_id+check_id])
          else
            assert_nil(results[section_id+subsection_id+check_id])
          end
        end
      end
    end
 
  end
  
  
  def create_comparison_hash(audit)

    results =  {}
    audit.checklist.sections.each do |section|
      
      section_id = section.id.to_s
      results[section_id] = 'yes'
      section.subsections.each do |subsection|
        
        subsection_id = subsection.id.to_s
        results[section_id+subsection_id] = 'yes'
        subsection.checks.each do |check|
          
          check_id = check.id.to_s
          results[section_id+subsection_id+check_id] = 'yes'
        end
      end
    end

    results

  end
  
  
  def dump_tree(audit)
 
    puts
    puts("dump_tree() START")
    puts("AUDIT ID: #{audit.id}")
    puts("DESIGN ID:          #{audit.design.id}  " +
         "[#{audit.design.new?}:#{audit.design.date_code?}:#{audit.design.dot_rev?}]  " +
         "Number of Sections: #{audit.checklist.sections.size.to_s}")
    
    audit.checklist.sections.each do |section|
      puts("  SECTION ID: #{section.id}  " +
          "[#{section.full_review}:#{section.date_code_check}:#{section.dot_rev_check}]" +
          "  Number of Subsections: #{section.subsections.size.to_s}")
      
      section.subsections.each do |subsection|
        puts("    SUBSECTION ID: #{subsection.id}  " +
             "[#{subsection.full_review}:#{subsection.date_code_check}:#{subsection.dot_rev_check}]" +
             "  Number of Checks:  #{subsection.checks.size.to_s}")
        
        subsection.checks.each do |check|
          puts("      CHECK ID: #{check.id}" +
               "[#{check.full_review}:#{check.date_code_check}:#{check.dot_rev_check}]")
        end
      end
    end
    
    puts
    puts("dump_tree() END")

  end
  
  
end
