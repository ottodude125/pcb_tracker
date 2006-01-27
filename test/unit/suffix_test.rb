require File.dirname(__FILE__) + '/../test_helper'

class SuffixTest < Test::Unit::TestCase
  fixtures :suffixes

  def setup
    @suffix = Suffix.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Suffix,  @suffix
  end
end
