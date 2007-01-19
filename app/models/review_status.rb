########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: review_status.rb
#
# This file maintains the state for review statuss.
#
# $Id$
#
########################################################################

class ReviewStatus < ActiveRecord::Base

  has_many :design_reviews


  validates_uniqueness_of(:name,
                          :message => 'already exists in the database')
  validates_presence_of   :name


  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################

  
  ######################################################################
  #
  # get_all_active
  #
  # Description:
  # This method returns a list of the active review status values
  #
  # Parameters:
  # sort - specifies the field(s) and sort order
  #
  # Return value:
  # An array of active review status records
  #
  ######################################################################
  #
  def ReviewStatus.get_all_active(sort = 'name ASC')
    ReviewStatus.find_all_by_active(1, sort)
  end
  

end
