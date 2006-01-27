require File.dirname(__FILE__) + '/../test_helper'

class DesignReviewResultTest < Test::Unit::TestCase
  fixtures :design_review_results

  def setup
    @design_review_result = DesignReviewResult.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of DesignReviewResult,  @design_review_result
  end
end
