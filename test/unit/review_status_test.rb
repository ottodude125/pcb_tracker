########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: review_status_test.rb
#
# This file contains the unit tests for the review status model
#
# $Id$
#
########################################################################
#
require File.expand_path( "../../test_helper", __FILE__ ) 

class ReviewStatusesTest < ActiveSupport::TestCase


  ######################################################################
  def test_get_all_active
    
    all_review_statuses = ReviewStatus.find(:all)
    all_active          = ReviewStatus.get_all_active
    all_inactive        = all_review_statuses - all_active
    
    assert(!all_active.empty?)
    assert(!all_inactive.empty?)
    
    all_inactive.each { |rs| assert(!rs.active?) }
    
    name = ''
    all_active.each do |rs|
      assert(rs.active?)
      assert(name <= rs.name)
      name = rs.name
    end
    
  end
  
  
end
