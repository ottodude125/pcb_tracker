########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_center_test.rb
#
# This file contains the unit tests for the design center model
#
# $Id$
#
########################################################################
#
require File.expand_path( "../../test_helper", __FILE__ ) 

class DesignCentersTest < ActiveSupport::TestCase

  def setup
    @design_center = DesignCenter.find(1)
  end


  ######################################################################
  def test_get_all_active
    
    all_design_centers = DesignCenter.find(:all)
    all_active         = DesignCenter.get_all_active
    all_inactive       = all_design_centers - all_active
    
    assert(!all_active.empty?)
    assert(!all_inactive.empty?)
    
    all_inactive.each { |dc| assert(!dc.active?) }
    
    name = ''
    all_active.each do |dc|
      assert(dc.active?)
      assert(name <= dc.name) # check default sorting
      name = dc.name
    end

    name = "ZZZZ"
    all_active_desc = DesignCenter.get_all_active("name DESC")
    all_active_desc.each do |dc|
      assert(name >= dc.name) # check descending sorting
      name = dc.name
    end
  end
  
  
end
