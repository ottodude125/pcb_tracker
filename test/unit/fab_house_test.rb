require File.dirname(__FILE__) + '/../test_helper'

class FabHouseTest < Test::Unit::TestCase
  fixtures :fab_houses

  def setup
    @fab_house = FabHouse.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of FabHouse,  @fab_house
  end
end
