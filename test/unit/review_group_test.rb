require File.expand_path( "../../test_helper", __FILE__ ) 

class ReviewGroupsTest < ActiveSupport::TestCase

  def setup
    @review_group = ReviewGroup.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of ReviewGroup,  @review_group
  end
end
