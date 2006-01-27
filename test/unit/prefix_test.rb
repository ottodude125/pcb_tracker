require File.dirname(__FILE__) + '/../test_helper'

class PrefixTest < Test::Unit::TestCase
  fixtures :prefixes

  def setup
    @prefix = Prefix.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Prefix,  @prefix
  end
end
