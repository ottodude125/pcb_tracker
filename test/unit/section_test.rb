########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: section_test.rb
#
# This file contains the unit tests for the section model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class SectionTest < Test::Unit::TestCase
  fixtures :sections


  def setup
    @section = Section.find(sections(:section_01_1).id)
  end

 
  ######################################################################
  def test_insert
    
    checklist  = Checklist.new
    checklist.save

    assert_equal(0, checklist.sections.size)
    
    first_section = Section.new( :name => 'First Section Name' )
    first_section.insert(checklist.id, 1)

    checklist.reload
    assert_equal(1, checklist.sections.size)
    assert_equal(1, first_section.position)
    assert(first_section.errors.empty?)
    
    new_first_section = Section.new( :name => 'New First Section Name' )
    new_first_section.insert(checklist.id, first_section.position)

    checklist.reload
    first_section.reload
    new_first_section.reload
    assert_equal(2, checklist.sections.size)
    assert_equal(1, new_first_section.position)
    assert_equal(2, first_section.position)
    assert(new_first_section.errors.empty?)
    
    new_second_section = Section.new( :name => 'New Second Section Name' )
    new_second_section.insert(checklist.id, first_section.position)

    checklist.reload
    new_second_section.reload
    new_first_section.reload
    first_section.reload
    assert_equal(3, checklist.sections.size)
    assert_equal(1, new_first_section.position)
    assert_equal(2, new_second_section.position)
    assert_equal(3, first_section.position)
    assert(new_second_section.errors.empty?)
    
  end

  def dump(cl)
    cl.reload
    puts("--------------------------------------------")
    puts("#### DUMPING CHECKLIST: " + cl.id.to_s)
    puts("     NUMBER OF SECTIONS: " + cl.sections.size.to_s)
    cl.sections.each do |s|
      puts("  #### SECTION ID: " + s.id.to_s + '  POSITION: ' + s.position.to_s)
    end
    puts("--------------------------------------------")
  end

  
  ######################################################################
  def test_remove
    
    checklist = Checklist.find(sections(:section_01_1).checklist.id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(3, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(3, checklist.dr_designer_auditor_count)

    sections = { :sect_01_1   => { :section          => sections(:section_01_1),
                                   :subsection_count => sections(:section_01_1).subsections.size,
                                   :check_count      => 0},
                 :sect_01_2   => { :section          => sections(:section_01_2),
                                   :subsection_count => sections(:section_01_2).subsections.size,
                                   :check_count      => 0},
                 :sect_01_3   => { :section          => sections(:section_01_3),
                                   :subsection_count => sections(:section_01_3).subsections.size,
                                   :check_count      => 0},
                 :sect_10_1_5 => { :section          => sections(:section_10_1_5),
                                   :subsection_count => sections(:section_10_1_5).subsections.size,
                                   :check_count      => 0}}

    section_10_1_5 = sections(:section_10_1_5)
    check_count = 0
    checklist.sections.each do |section|
      section.subsections.each { |subsection| check_count += subsection.checks.size }
    end
    section_count = checklist.sections.size
    
    sections[:sect_01_1][:section].subsections.each do |subsection|
      sections[:sect_01_1][:check_count] += subsection.checks.size
    end

    sections[:sect_01_2][:section].subsections.each do |subsection|
      sections[:sect_01_2][:check_count] += subsection.checks.size
    end

    sections[:sect_01_3][:section].subsections.each do |subsection|
      sections[:sect_01_3][:check_count] += subsection.checks.size
    end

    sections[:sect_10_1_5][:section].subsections.each do |subsection|
      sections[:sect_10_1_5][:check_count] += subsection.checks.size
    end
    
    assert_equal(check_count,
                 sections[:sect_01_1][:check_count] + sections[:sect_01_2][:check_count] +
                 sections[:sect_01_3][:check_count] + sections[:sect_10_1_5][:check_count])
    
    assert_equal(4, checklist.sections.size)
    assert_equal(1, sections[:sect_01_1][:section].position)
    assert_equal(2, sections[:sect_01_2][:section].position)
    assert_equal(3, sections[:sect_01_3][:section].position)
    assert_equal(4, sections[:sect_10_1_5][:section].position)
    
    total_check_count      = Check.count
    total_subsection_count = Subsection.count
    total_section_count    = Section.count

    assert(sections[:sect_01_2][:section].remove)
    
    total_check_count -= sections[:sect_01_2][:check_count]
    assert_equal(total_check_count, Check.count)
    

    checklist.reload
    sections[:sect_01_1][:section].reload
    sections[:sect_01_3][:section].reload
    sections[:sect_10_1_5][:section].reload
    
    assert_equal(3, checklist.sections.size)
    assert_equal(1, sections[:sect_01_1][:section].position)
    assert_equal(2, sections[:sect_01_3][:section].position)
    assert_equal(3, sections[:sect_10_1_5][:section].position)

    section_count -= 1
    assert_equal(section_count, checklist.sections.size)
    assert_equal(1, sections[:sect_01_1][:section].position)
    assert_equal(2, sections[:sect_01_3][:section].position)
    assert_equal(3, sections[:sect_10_1_5][:section].position)

    check_count -= sections[:sect_01_2][:check_count]
    assert_equal(check_count,
                 sections[:sect_01_1][:check_count] + sections[:sect_01_3][:check_count] +
                 sections[:sect_10_1_5][:check_count])

    checklist.reload
    assert_equal(3, checklist.designer_only_count)
    assert_equal(2, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(3, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(3, checklist.dr_designer_auditor_count)
    
    assert(sections[:sect_01_1][:section].remove)
    
    total_check_count -= sections[:sect_01_1][:check_count]
    assert_equal(total_check_count, Check.count)
    

    checklist.reload
    sections[:sect_01_3][:section].reload
    sections[:sect_10_1_5][:section].reload
    
    assert_equal(2, checklist.sections.size)
    assert_equal(1, sections[:sect_01_3][:section].position)
    assert_equal(2, sections[:sect_10_1_5][:section].position)

    section_count -= 1
    assert_equal(section_count, checklist.sections.size)

    check_count -= sections[:sect_01_1][:check_count]
    assert_equal(check_count,
                 sections[:sect_01_3][:check_count] + sections[:sect_10_1_5][:check_count])

    checklist.reload
    assert_equal(0, checklist.designer_only_count)
    assert_equal(0, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(0, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(0, checklist.dr_designer_auditor_count)

  end

  
  ######################################################################
  def test_destroy
    @section.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Section.find(@section.id) }
  end

  
  ######################################################################
  def test_locked
    assert( sections(:section_10_1).locked?)
    assert(!sections(:section_01_2).locked?)
  end

  
  ######################################################################
  def test_designer_auditor_check_count
    assert_equal(2, sections(:section_10_1).designer_auditor_check_count)
  end

  
end
