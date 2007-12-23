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
require File.dirname(__FILE__) + '/../test_helper'

class DesignCenterTest < Test::Unit::TestCase
  fixtures :design_centers


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
      assert(name <= dc.name)
      name = dc.name
    end
    
  end
  
  
end
