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

  # Replace this with your real tests.
  def test_truth
    assert_kind_of OiAssignment, oi_assignments(:first)
  end
end
