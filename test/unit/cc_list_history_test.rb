require File.expand_path( "../../test_helper", __FILE__ ) 

class CcListHistorysTest < ActiveSupport::TestCase

  def setup
    @cc_list_history = CcListHistory.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of CcListHistory,  @cc_list_history
  end
end
