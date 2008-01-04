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
 
  REVIEW_COMPLETE = [APPROVED, REJECTED, WAIVED]
  POSITIVE_RESULT = [APPROVED, WAIVED]

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
  rescue
    nil
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
    REVIEW_COMPLETE.include?(self.result)
  end

  
  ######################################################################
  #
  # positive_response?
  #
  # Description:
  # Indicates that the review result has been processed by the reviewer
  # and a positive response has been entered.
  #
  # Return value:
  # TRUE if the review result is either APPROVED or WAIVED, otherwise FALSE
  #
  ######################################################################
  #
  def positive_response?
    POSITIVE_RESULT.include?(self.result)
  end

  
end
