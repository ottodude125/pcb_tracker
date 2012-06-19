require File.dirname(__FILE__) + '/../test_helper'

class CcListHistoryTest < Test::Unit::TestCase
  fixtures :cc_list_histories

  def setup
    @cc_list_history = CcListHistory.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of CcListHistory,  @cc_list_history
  end
end
