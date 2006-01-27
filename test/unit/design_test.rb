require File.dirname(__FILE__) + '/../test_helper'

class DesignTest < Test::Unit::TestCase
  fixtures :designs

  def setup
    @design = Design.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Design,  @design
  end
end
