require File.dirname(__FILE__) + '/../test_helper'

class ReviewTypeTest < Test::Unit::TestCase
  fixtures :review_types

  def setup
    @review_type = ReviewType.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of ReviewType,  @review_type
  end
end
