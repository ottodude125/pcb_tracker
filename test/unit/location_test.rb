require File.dirname(__FILE__) + '/../test_helper'

class LocationTest < Test::Unit::TestCase
  fixtures :locations


  ######################################################################
  #
  # setup
  #
  ######################################################################
  #
  def setup
    @location = Location.find(locations(:fridley).id)
  end


  ######################################################################
  #
  # test_create
  #
  ######################################################################
  #
  def test_create

    assert_kind_of Location, @location

    fridley = locations(:fridley)
    assert_equal(fridley.id,     @location.id)
    assert_equal(fridley.name,   @location.name)
    assert_equal(fridley.active, @location.active)
 
  end


  ######################################################################
  #
  # test_update
  #
  ######################################################################
  #
  def test_update
    
    @location.name   = "Dallas"
    @location.active = 0

    assert @location.save
    @location.reload

    assert_equal("Dallas", @location.name)
    assert_equal(0,        @location.active)

  end


  ######################################################################
  #
  # test_destroy
  #
  ######################################################################
  #
  def test_destroy
    @location.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Location.find(@location.id) }
  end


  ######################################################################
  #
  # test_get_active
  #
  ######################################################################
  #
  def test_get_active
    
    active_locations = Location.get_active_locations
    
    assert(active_locations.size > 1)
    assert(active_locations.size < Location.count)
    
    name = ''
    active_locations.each do |location|
      assert(name < location.name)
      name = location.name
    end
    
  end


end
