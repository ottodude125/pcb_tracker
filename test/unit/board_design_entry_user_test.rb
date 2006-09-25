require File.dirname(__FILE__) + '/../test_helper'

class BoardDesignEntryUsersTest < Test::Unit::TestCase
  fixtures :board_design_entry_users

  # Replace this with your real tests.
  def test_truth
    assert_kind_of BoardDesignEntryUser, BoardDesignEntryUser.find(1)
  end
end
