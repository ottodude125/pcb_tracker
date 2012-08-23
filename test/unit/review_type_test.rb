########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: review_type_test.rb
#
# This file contains the unit tests for the review type model
#
# Revision History:
#   $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ ) 

class ReviewTypesTest < ActiveSupport::TestCase


  def setup
    @pre_artwork = review_types(:pre_artwork)
    @placement   = review_types(:placement)
    @routing     = review_types(:routing)
    @final       = review_types(:final)
    @release     = review_types(:release)
    @inactive    = review_types(:neither_required_nor_active)
  end


  ##############################################################################
  def test_get
  
    expected = [ @pre_artwork,       @placement,         @routing,
                 @final,             @release ]
  
    all_review_types = ReviewType.get_review_types
    all_active       = ReviewType.get_active_review_types
    
    assert_equal(all_active+[@inactive], all_review_types)
    
    sort_order = 0
    all_review_types.each do |rt|
      assert(rt.sort_order > sort_order)
      sort_order = rt.sort_order
    end
    
    sort_order = 0
    all_active.each_with_index do |rt, i| 
      assert_equal(expected[i], rt)
      assert(rt.sort_order > sort_order)
      sort_order = rt.sort_order
    end
    
    assert_equal(@pre_artwork, ReviewType.get_pre_artwork)
    assert_equal(@placement,   ReviewType.get_placement)
    assert_equal(@routing,     ReviewType.get_routing)
    assert_equal(@final,       ReviewType.get_final)
    assert_equal(@release,     ReviewType.get_release)
    
  end
  
  ##############################################################################
  def test_next
  
    pre_artwork_review_type = @pre_artwork  
    placement_review_type   = pre_artwork_review_type.next
    routing_review_type     = placement_review_type.next
    final_review_type       = routing_review_type.next
    release_review_type     = final_review_type.next
    
    assert_equal(@placement, placement_review_type)
    assert_equal(@routing,   routing_review_type)
    assert_equal(@final,     final_review_type)
    assert_equal(@release,   release_review_type)
    
    next_review_type = release_review_type.next
    assert_nil(next_review_type)

  end
  
  
end
