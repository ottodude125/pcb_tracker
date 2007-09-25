########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: division_test.rb
#
# This file contains the unit tests for the division model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class DivisionTest < Test::Unit::TestCase
  fixtures :divisions


  ######################################################################
  #
  # setup
  #
  ######################################################################
  #
  def setup
    @division = Division.find(divisions(:std).id)
  end


  ######################################################################
  #
  # test_create
  #
  ######################################################################
  #
  def test_create

    assert_kind_of Division,  @division

    std = divisions(:std)
    assert_equal(std.id,     @division.id)
    assert_equal(std.name,   @division.name)
    assert_equal(std.active, @division.active)
 
  end


  ######################################################################
  #
  # test_update
  #
  ######################################################################
  #
  def test_update
    
    @division.name   = "EB"
    @division.active = 0

    assert @division.save
    @division.reload

    assert_equal("EB", @division.name)
    assert_equal(0,    @division.active)

  end


  ######################################################################
  #
  # test_destroy
  #
  ######################################################################
  #
  def test_destroy
    @division.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Division.find(@division.id) }
  end
  
  
  ######################################################################
  #
  # test_get_active
  #
  ######################################################################
  #
  def test_get_active
    
    active_divisions = Division.get_active_divisions
    
    assert(active_divisions.size > 1)
    assert(active_divisions.size < Division.count)
    
    name = ''
    active_divisions.each do |division|
      assert(name < division.name)
      name = division.name
    end
    
  end


end
