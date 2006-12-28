require File.dirname(__FILE__) + '/../test_helper'

class OiInstructionTest < Test::Unit::TestCase
  fixtures :oi_instructions

  # Replace this with your real tests.
  def test_truth
    assert_kind_of OiInstruction, oi_instructions(:first)
  end
end
