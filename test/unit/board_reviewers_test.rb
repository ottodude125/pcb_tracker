require File.dirname(__FILE__) + '/../test_helper'

class BoardReviewersTest < Test::Unit::TestCase
  fixtures :board_reviewers

  def setup
    @board_reviewers = BoardReviewers.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of BoardReviewers,  @board_reviewers
  end
end
