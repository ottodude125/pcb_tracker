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


  def review_name
    if self.review_type_id_2 == 0
      self.review_type.name
    else
      self.review_type.name + '/' + ReviewType.find(self.review_type_id_2).name
    end
  end
  
  
end
