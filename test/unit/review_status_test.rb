require File.dirname(__FILE__) + '/../test_helper'

class ReviewStatusTest < Test::Unit::TestCase
  fixtures :review_statuses

  def setup
    @review_status = ReviewStatus.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of ReviewStatus,  @review_status
  end
end
