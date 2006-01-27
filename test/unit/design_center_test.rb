require File.dirname(__FILE__) + '/../test_helper'

class DesignCenterTest < Test::Unit::TestCase
  fixtures :design_centers

  def setup
    @design_center = DesignCenter.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of DesignCenter,  @design_center
  end
end
