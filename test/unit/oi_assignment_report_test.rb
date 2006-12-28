require File.dirname(__FILE__) + '/../test_helper'

class OiAssignmentReportTest < Test::Unit::TestCase
  fixtures :oi_assignment_reports

  # Replace this with your real tests.
  def test_truth
    assert_kind_of OiAssignmentReport, oi_assignment_reports(:first)
  end
end
