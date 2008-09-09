########################################################################
#
# Copyright 2008, by Teradyne, Inc., North Reading MA
#
# File: eco_type_test.rb
#
# This file contains the unit tests for the eco type model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class EcoTypeTest < ActiveSupport::TestCase


  fixtures :eco_types
         

  def setup
    # All are active
    @assy_dwg  = eco_types(:assembly_drawing) 
    @fab_dwg   = eco_types(:fabrication_drawing)    
    @schematic = eco_types(:schematic) 
  end

  
  ######################################################################
  def test_find_active_no_types
    # Remove the existing tasks in the test database.
    EcoType.delete_all
    
    assert_equal(0, EcoType.find_active.size)
  end
  
  
  ######################################################################
  def test_find_active_no_active_types
    
    all_types = EcoType.find(:all)
    all_types.each do |t|
      t.active = 0
      t.save
    end
    
    assert_equal(0, EcoType.find_active.size)
  end

  
  ######################################################################
  def test_find_active_one_active_types
    @assy_dwg.active = 0
    @assy_dwg.save
    @fab_dwg.active = 0
    @fab_dwg.save

    active_types = EcoType.find_active
    assert_equal(1,          active_types.size)
    assert_equal(@schematic, active_types[0])
  end

  
  ######################################################################
  def test_find_active_multiple_active_types
    active_types = EcoType.find_active
    assert_equal(3,           active_types.size)
    assert_equal(@assy_dwg,   active_types[0])
    assert_equal(@fab_dwg,    active_types[1])
    assert_equal(@schematic,  active_types[2])
  end


end
