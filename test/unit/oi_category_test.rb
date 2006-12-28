########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: oi_category_test.rb
#
# This file contains the unit tests for the oi category model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class OiCategoryTest < Test::Unit::TestCase
  fixtures :oi_categories

  ######################################################################
  #
  # test_categories
  #
  # Description:
  # Validates the behaviour of the following methods.
  #
  #   designer()
  #   peer()
  #   input_gate()
  #
  ######################################################################s
  def test_categories
  
    oi_category_list = OiCategory.find_all.sort_by{ |oi| oi.id }
    
    assert_equal(7, oi_category_list.size)
    assert_equal('Board Preparation',   oi_category_list[0].name)
    assert_equal('Placement',           oi_category_list[1].name)
    assert_equal('Routing',             oi_category_list[2].name)
    assert_equal('Fabrication Drawing', oi_category_list[3].name)
    assert_equal('Nomenclature',        oi_category_list[4].name)
    assert_equal('Assembly Drawing',    oi_category_list[5].name)
    assert_equal('Other',               oi_category_list[6].name)

    assert_equal(1, oi_category_list[0].id)
    assert_equal(2, oi_category_list[1].id)
    assert_equal(3, oi_category_list[2].id)
    assert_equal(4, oi_category_list[3].id)
    assert_equal(5, oi_category_list[4].id)
    assert_equal(6, oi_category_list[5].id)
    assert_equal(7, oi_category_list[6].id)

  end
end
