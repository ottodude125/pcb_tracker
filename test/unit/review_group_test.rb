require File.dirname(__FILE__) + '/../test_helper'

class ReviewGroupTest < Test::Unit::TestCase
  fixtures :review_groups

  def setup
    @review_group = ReviewGroup.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of ReviewGroup,  @review_group
  end
end
