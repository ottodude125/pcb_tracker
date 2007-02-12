########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: oi_assignment_test_test.rb
#
# This file contains the unit tests for the outsource instruction
# assignment model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class OiAssignmentTest < Test::Unit::TestCase
  fixtures :oi_assignments

  ######################################################################
  def test_complexity_list
  
    expected_complexity_list = [ ['High', 1], ['Medium', 2], ['Low', 3] ]
    assert_equal(expected_complexity_list, OiAssignment.complexity_list)
    
  end


  ######################################################################
  def test_complexity_name
  
    assert_equal('High',      OiAssignment.complexity_name(1))
    assert_equal('Medium',    OiAssignment.complexity_name(2))
    assert_equal('Low',       OiAssignment.complexity_name(3))
    assert_equal('Undefined', OiAssignment.complexity_name(33))
    
  end


  ######################################################################
  def test_complexity_id
  
    assert_equal(1, OiAssignment.complexity_id('High'))
    assert_equal(2, OiAssignment.complexity_id('Medium'))
    assert_equal(3, OiAssignment.complexity_id('Low'))
    
  end


end
