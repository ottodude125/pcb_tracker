########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_review.rb
#
# This file maintains the state for design reviews.
#
# $Id$
#
########################################################################

class DesignReview < ActiveRecord::Base

  belongs_to :design
  belongs_to :design_center
  belongs_to :priority
  belongs_to :review_status
  belongs_to :review_type

  has_many   :design_review_results


  ######################################################################
  #
  # review_name
  #
  # Description:
  # This method returns the review (type) name for the object.
  #
  # Parameters:
  # None
  #
  # Return value:
  # The review (type) name
  #
  ######################################################################
  #
  def review_name
    if self.review_type_id_2 == 0
      self.review_type.name
    else
      self.review_type.name + '/' + ReviewType.find(self.review_type_id_2).name
    end
  end
  
  
  ######################################################################
  #
  # comments
  #
  # Description:
  # This method returns the comments for the design review object.
  #
  # Parameters:
  # order - specifies the sort order for the created_on field.  Either 
  #         'ASC' or 'DESC'
  #
  # Return value:
  # A list of comments for the design review.
  #
  ######################################################################
  #
  def comments(order = 'DESC')
    DesignReviewComment.find_all_by_design_review_id(self.id,
                                                     "created_on #{order}")
  end
  
  
  ######################################################################
  #
  # review_results_by_role_name
  #
  # Description:
  # This method returns the review results sorted by the review role
  # for the design review object.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of design_review_result objects for the design review.
  #
  ######################################################################
  #
  def review_results_by_role_name
    self.design_review_results.sort_by { |review_result| 
      review_result.role.name
    }
  end
  
  
  def reviewers(reviewer_list = [],
                sorted        = false)
  
    for review_result in self.design_review_results
      if not reviewer_list.detect { |reviewer| reviewer.id == review_result.reviewer_id }
        reviewer_list << User.find(review_result.reviewer_id)
      end
    end
    
    reviewer_list = 
      reviewer_list.sort_by { |reviewer| reviewer.last_name } if sorted
    
    reviewer_list.uniq
    
  end
  
  
  
end
