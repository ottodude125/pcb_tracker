########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: debug_helper.rb
#
# This contains the helper methods for debug.
#
# $Id$
#
########################################################################
#
module DebugHelper


  ######################################################################
  #
  # design_reviews
  #
  # Description:
  # Returns a list of design review results sorted by the role name
  # for the design review identified by the ID tha is passed in.
  #
  ######################################################################
  #
  def design_reviews(design_review_id)
    design_reviews = DesignReviewResult.find_all_by_design_review_id(design_review_id)
    return design_reviews.sort_by { |drr| drr.role.name }
  end


end
