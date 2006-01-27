require File.dirname(__FILE__) + '/../test_helper'

class DesignCheckTest < Test::Unit::TestCase
  fixtures :design_checks

  def setup
    @design_check = DesignCheck.find(design_checks(:first_design_check).id)
  end

  def test_create

    assert_kind_of DesignCheck,  @design_check

    first_design_check = design_checks(:first_design_check)
    assert_equal(first_design_check.id,         @design_check.id)
    assert_equal(first_design_check.audit_id,   @design_check.audit_id)
    assert_equal(first_design_check.check_id,   @design_check.check_id)
    assert_equal(first_design_check.auditor_id, @design_check.auditor_id)
    assert_equal(first_design_check.auditor_result,
                 @design_check.auditor_result)
    assert_equal(first_design_check.auditor_checked_on,
                 @design_check.auditor_checked_on)
    assert_equal(first_design_check.designer_id,
                 @design_check.designer_id)
    assert_equal(first_design_check.designer_result,
                 @design_check.designer_result)
    assert_equal(first_design_check.designer_checked_on,
                 @design_check.designer_checked_on)
  end

  def test_update
    @design_check.audit_id            = 2
    @design_check.check_id            = 4
    @design_check.auditor_id          = 5
    @design_check.auditor_result      = 'N/A'
    @design_check.auditor_checked_on  = '20050610113323'
    @design_check.designer_id         = 554
    @design_check.designer_result     = 'No'
    @design_check.designer_checked_on = '20050610113323'

    assert @design_check.save
    @design_check.reload

    assert_equal(2,     @design_check.audit_id)
    assert_equal(4,     @design_check.check_id)
    assert_equal(5,     @design_check.auditor_id)
    assert_equal('N/A', @design_check.auditor_result)
##    assert_equal(Time.at(20050610),
##		 @design_check.auditor_checked_on)
    assert_equal(554,   @design_check.designer_id)
    assert_equal('No',  @design_check.designer_result)
#    assert_equal('20050610113323', @design_check.designer_checked_on)
    
  end

  def test_destroy
    @design_check.destroy
    assert_raise(ActiveRecord::RecordNotFound) { DesignCheck.find(@design_check.id) }
  end
end
