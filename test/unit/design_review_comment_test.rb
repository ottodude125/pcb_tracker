require File.expand_path( "../../test_helper", __FILE__ ) 

class DesignReviewCommentsTest < ActiveSupport::TestCase

  def setup
    @design_review_comment = DesignReviewComment.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of DesignReviewComment,  @design_review_comment
  end
end
