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

require File.dirname(__FILE__) + '/../test_helper'

class ReviewTypeTest < Test::Unit::TestCase
  fixtures :review_types

  def setup
    @review_type = ReviewType.find(1)
  end

  ##############################################################################
  def test_next
  
    pre_art   = review_types(:pre_artwork)
    
    next_review_type = pre_art.next
    assert_equal(review_types(:placement).id, next_review_type.id)
    next_review_type = next_review_type.next
    assert_equal(review_types(:routing).id,   next_review_type.id)
    next_review_type = next_review_type.next
    assert_equal(review_types(:final).id,     next_review_type.id)
    next_review_type = next_review_type.next
    assert_equal(review_types(:release).id,   next_review_type.id)
    next_review_type = next_review_type.next
    assert_nil(next_review_type)

  end
  
  
end
