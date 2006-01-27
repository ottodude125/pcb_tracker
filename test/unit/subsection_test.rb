require File.dirname(__FILE__) + '/../test_helper'

class SubsectionTest < Test::Unit::TestCase
  fixtures :subsections

  def setup
    @subsection = Subsection.find(subsections(:subsection_01_2_1).id)
  end

  def test_create
    assert_kind_of Subsection,  @subsection

    subsection_01_2_1 = subsections(:subsection_01_2_1)
    
    assert_equal(subsection_01_2_1.id,           @subsection.id)
    assert_equal(subsection_01_2_1.checklist_id, @subsection.checklist_id)
    assert_equal(subsection_01_2_1.section_id,	 @subsection.section_id)
    assert_equal(subsection_01_2_1.name,         @subsection.name)
    assert_equal(subsection_01_2_1.note,         @subsection.note)
    assert_equal(subsection_01_2_1.url,          @subsection.url)
    assert_equal(subsection_01_2_1.sort_order,   @subsection.sort_order)
    assert_equal(subsection_01_2_1.date_code_check,
                 @subsection.date_code_check)
    assert_equal(subsection_01_2_1.dot_rev_check,
                 @subsection.dot_rev_check)
    assert_equal(subsection_01_2_1.full_review,
                 @subsection.full_review)
  end

  def test_update

    assert_equal(subsections(:subsection_01_2_1).id, @subsection.id)

    @subsection.name = "Subsection One"
    @subsection.note = "Subsection One Note"
    @subsection.url  = "www.pirateball.com"
    @subsection.sort_order      = 2
    @subsection.date_code_check = 0
    @subsection.dot_rev_check   = 0
    @subsection.full_review     = 0

    assert @subsection.save
    @subsection.reload

    assert_equal("Subsection One",      @subsection.name)
    assert_equal("Subsection One Note", @subsection.note)
    assert_equal("www.pirateball.com",  @subsection.url)
    assert_equal(2, @subsection.sort_order)
    assert_equal(0, @subsection.date_code_check)
    assert_equal(0, @subsection.dot_rev_check)
    assert_equal(0, @subsection.full_review)

  end

  def test_destroy
    @subsection.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Subsection.find(@subsection.id) }
  end
end
