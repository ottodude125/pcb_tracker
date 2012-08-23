########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_review_result_test.rb
#
# This file contains the unit tests for the design review result model
#
# Revision History:
#   $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ ) 

class DesignReviewResultsTest < ActiveSupport::TestCase
  
  def setup
    @mx234a_pre_artwork_hw = design_review_results(:mx234a_pre_artwork_hw)
    
    @ben_b   = users(:ben_b)
    @lee_s   = users(:lee_s)
    @scott_g = users(:scott_g)
  end


  ###################################################################
  def test_complete
    
    results = { 'No Response' => false,
                'APPROVED'    => true,
                'WAIVED'      => true,
                'COMMENTED'   => false, 
                'REJECTED'    => true }
                
    drr = DesignReviewResult.new
    results.each do |result, expected_return|
      drr.result = result
      assert_equal(expected_return, drr.complete?)
    end
    
  end
  
  
  ###################################################################
  def test_positive_response
    
    results = { 'No Response' => false,
                'APPROVED'    => true,
                'WAIVED'      => true,
                'COMMENTED'   => false, 
                'REJECTED'    => false }
                
    drr = DesignReviewResult.new
    results.each do |result, expected_return|
      drr.result = result
      assert_equal(expected_return, drr.positive_response?)
    end
    
  end
  
  
  ###################################################################
  def test_no_response
    
    results = { 'No Response' => true,
                'APPROVED'    => false,
                'WAIVED'      => false,
                'COMMENTED'   => false, 
                'REJECTED'    => false }
                
    drr = DesignReviewResult.new
    drr.result = 'No Response'
    assert_equal(true, drr.no_response?)

    drr.result = 'APPROVED'
    assert_equal(false, drr.no_response?)
  end
  
  
  ###################################################################
  def test_reviewer
    assert_equal('Lee Schaff', @mx234a_pre_artwork_hw.reviewer.name)
    
    new_drr = DesignReviewResult.new
    assert_nil(new_drr.reviewer)
  end


  ###################################################################
  def test_set_reviewer_non_role_member_exception
    assert_raise(ArgumentError) { @mx234a_pre_artwork_hw.set_reviewer(@scott_g) }
    @mx234a_pre_artwork_hw.reload
    assert_equal(@lee_s.name, @mx234a_pre_artwork_hw.reviewer.name)
  end
  
  
  ###################################################################
 def test_set_reviewer_non_role_member
    @mx234a_pre_artwork_hw.set_reviewer(@scott_g)
  rescue => err
    assert_equal('Scott Glover is not a member of the Hardware Engineer (EE) group.', 
                 err.message)
  end
  

  ###################################################################
  def test_set_reviewer_role_member
    @mx234a_pre_artwork_hw.set_reviewer(@ben_b)
    @mx234a_pre_artwork_hw.reload
    assert_equal(@ben_b.name, @mx234a_pre_artwork_hw.reviewer.name)
  end
  
   
end
