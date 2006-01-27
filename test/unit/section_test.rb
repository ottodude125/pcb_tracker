require File.dirname(__FILE__) + '/../test_helper'

class SectionTest < Test::Unit::TestCase
  fixtures :sections

  def setup
    @section = Section.find(sections(:section_01_1).id)
  end

  def test_create

    assert_kind_of Section,  @section

    section_01_1 = sections(:section_01_1)
    
    assert_equal(section_01_1.id,               @section.id)
    assert_equal(section_01_1.checklist_id,     @section.checklist_id)
    assert_equal(section_01_1.name,             @section.name)
    assert_equal(section_01_1.url,              @section.url)
    assert_equal(section_01_1.background_color, @section.background_color)
    assert_equal(section_01_1.sort_order,       @section.sort_order)
    assert_equal(section_01_1.date_code_check,  @section.date_code_check)
    assert_equal(section_01_1.dot_rev_check,    @section.dot_rev_check)
    assert_equal(section_01_1.full_review,      @section.full_review)
  end

  def test_update

    @section.name             = "Section One"
    @section.url              = "www.teradyne.com"
    @section.background_color = "ff00ff"
    @section.sort_order       = 2
    @section.date_code_check  = 0
    @section.dot_rev_check    = 0
    @section.full_review      = 0

    assert @section.save
    @section.reload

    assert_equal("Section One",      @section.name)
    assert_equal("www.teradyne.com", @section.url)
    assert_equal("ff00ff",           @section.background_color)
    assert_equal(2,                  @section.sort_order)
    assert_equal(0,                  @section.date_code_check)
    assert_equal(0,                  @section.dot_rev_check)
    assert_equal(0,                  @section.full_review)

  end

  def test_destroy
    @section.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Section.find(@section.id) }
  end
end
