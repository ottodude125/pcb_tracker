require File.dirname(__FILE__) + '/../test_helper'

class SubsectionTest < Test::Unit::TestCase
  
  
  fixtures :checklists,
           :checks,
           :sections,
           :subsections
  
  
  ######################################################################
  def test_designer_auditor_checks
    
    subsection = checks(:check_2744).subsection
    assert_equal(13, subsection.designer_auditor_checks)
    assert_equal( 0, Subsection.new.designer_auditor_checks)
    
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


end
