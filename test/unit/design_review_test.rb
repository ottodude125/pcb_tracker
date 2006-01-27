require File.dirname(__FILE__) + '/../test_helper'

class DesignReviewTest < Test::Unit::TestCase
  fixtures :design_reviews

  def setup
    @design_review = DesignReview.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of DesignReview,  @design_review
  end
end
