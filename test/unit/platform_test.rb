########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: platform_test.rb
#
# This file contains the unit tests for the platform model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class PlatformTest < Test::Unit::TestCase
  fixtures :platforms


  ######################################################################
  #
  # setup
  #
  ######################################################################
  #
  def setup
    @platform = Platform.find(platforms(:catalyst).id)
  end

  ######################################################################
  #
  # test_create
  #
  ######################################################################
  #
  def test_create

    assert_kind_of Platform,  @platform

    catalyst = platforms(:catalyst)
    assert_equal(catalyst.id,     @platform.id)
    assert_equal(catalyst.name,   @platform.name) 
    assert_equal(catalyst.active, @platform.active)

  end


  ######################################################################
  #
  # test_update
  #
  ######################################################################
  #
  def test_update

    @platform.name   = "PLATFORM 1"
    @platform.active = 0

    assert @platform.save
    @platform.reload

    assert_equal("PLATFORM 1", @platform.name)
    assert_equal(0,            @platform.active)

  end


  ######################################################################
  #
  # test_destroy
  #
  ######################################################################
  #
  def test_destroy
    @platform.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Platform.find(@platform.id) }
  end


  ######################################################################
  #
  # test_access
  #
  ######################################################################
  #
  def test_access
  
    platform_list = Platform.find_all
    
    inactive_list = []
    platform_list.each do |expected_platform|
      inactive_list << expected_platform if !expected_platform.active?  
    end
    
    # Verify the list sizes.
    active_list = Platform.get_all_active
    assert_equal(platform_list.size, (inactive_list.size + active_list.size))
    assert_equal(nil,                active_list.detect { |p| !p.active })
    
    # Verify the list is sorted by the name
    name = ''
    active_list.each do |platform|
      assert(platform.name > name)
      name = platform.name
    end

    name = 'zzz'
    Platform.get_all_active('name DESC').each do |platform|
      assert(platform.name < name)
      name = platform.name
    end
  
  end


end
