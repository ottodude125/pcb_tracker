require File.dirname(__FILE__) + '/../test_helper'

class PriorityTest < Test::Unit::TestCase
  fixtures :priorities

  def setup
    @priority = Priority.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Priority,  @priority
  end
end
