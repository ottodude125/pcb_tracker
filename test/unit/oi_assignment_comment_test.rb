require File.dirname(__FILE__) + '/../test_helper'

class OiAssignmentCommentTest < Test::Unit::TestCase
  fixtures :oi_assignment_comments

  # Replace this with your real tests.
  def test_truth
    assert_kind_of OiAssignmentComment, oi_assignment_comments(:first)
  end
end
