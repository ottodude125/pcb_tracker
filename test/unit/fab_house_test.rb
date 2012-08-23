########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: fab_house_test.rb
#
# This file contains the unit tests for the fab_house model
#
# Revision History:
#   $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ ) 

class FabHousesTest < ActiveSupport::TestCase

  ######################################################################
  #
  # test_create
  #
  ######################################################################
  #
  def setup
    @fab_house = FabHouse.find(1)
  end


  ######################################################################
  #
  # test_access
  #
  ######################################################################
  #
  def test_access
  
    fab_house_list = FabHouse.find(:all)
    
    inactive_list = []
    fab_house_list.each do |expected_fab_house|
      inactive_list << expected_fab_house if !expected_fab_house.active?  
    end
    
    # Verify the list sizes.
    active_list = FabHouse.get_all_active
    assert_equal(fab_house_list.size, (inactive_list.size + active_list.size))
    assert_equal(nil,                 active_list.detect { |fh| !fh.active })
    
    # Verify the list is sorted by the name
    name = ''
    active_list.each do |fab_house|
      assert(fab_house.name > name)
      name = fab_house.name
    end
    
    name = 'zzzz'
    FabHouse.get_all_active('name DESC').each do |fab_house|
      assert(fab_house.name < name)
      name = fab_house.name
    end
  
  end


end
