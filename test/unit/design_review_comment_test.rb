require File.dirname(__FILE__) + '/../test_helper'

class DesignReviewCommentTest < Test::Unit::TestCase
  fixtures :design_review_comments

  def setup
    @design_review_comment = DesignReviewComment.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of DesignReviewComment,  @design_review_comment
  end
end
