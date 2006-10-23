########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_review_result.rb
#
# This file maintains the state for design review results.
#
# $Id$
#
########################################################################

class DesignReviewResult < ActiveRecord::Base

  belongs_to :design_review
  belongs_to :role
  
  
  APPROVED = 'APPROVED'
  REJECTED = 'REJECTED'
  WAIVED   = 'WAIVED'

  ######################################################################
  #
  # reviewer
  #
  # Description:
  # Provides a user record for the reviewer
  #
  # Return value:
  # A user record
  #
  ######################################################################
  #
  def reviewer
    User.find(self.reviewer_id)
  end
  
  
  ######################################################################
  #
  # complete?
  #
  # Description:
  # Indicates that the review result has been processed by the reviewer
  #
  # Return value:
  # TRUE if the review result is complete, otherwise FALSE
  #
  ######################################################################
  #
  def complete?
    self.result == APPROVED || self.result == WAIVED || self.result == REJECTED
  end
  
  
end
