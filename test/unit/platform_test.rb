require File.dirname(__FILE__) + '/../test_helper'

class PlatformTest < Test::Unit::TestCase
  fixtures :platforms

  def setup
    @platform = Platform.find(platforms(:catalyst).id)
  end

  def test_create

    assert_kind_of Platform,  @platform

    catalyst = platforms(:catalyst)
    assert_equal(catalyst.id,     @platform.id)
    assert_equal(catalyst.name,   @platform.name) 
    assert_equal(catalyst.active, @platform.active)

  end

  def test_update

    @platform.name   = "PLATFORM 1"
    @platform.active = 0

    assert @platform.save
    @platform.reload

    assert_equal("PLATFORM 1", @platform.name)
    assert_equal(0,            @platform.active)

  end

  def test_destroy
    @platform.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Platform.find(@platform.id) }
  end

end
