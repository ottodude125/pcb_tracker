require File.expand_path( "../../test_helper", __FILE__ ) 

class BoardReviewersTest < ActiveSupport::TestCase

  def setup
    @board_reviewers = BoardReviewer.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of BoardReviewer,  @board_reviewers
  end
end
