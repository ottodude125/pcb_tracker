########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_center.rb
#
# This file maintains the state for the design centers.
#
# $Id$
#
########################################################################

class DesignCenter < ActiveRecord::Base

  has_many :design_reviews
  has_many :users

  validates_uniqueness_of :name


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
  # This method returns a list of the active prefixes
  #
  # Parameters:
  # sort - specifies the field(s) and sort order
  #
  # Return value:
  # An array of active prefix records
  #
  ######################################################################
  #
  def DesignCenter.get_all_active(sort = 'name ASC')
    DesignCenter.find_all_by_active(1, sort)
  end
  

end
