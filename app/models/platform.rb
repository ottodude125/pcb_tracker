########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: platform.rb
#
# This file maintains the state for platforms.
#
# $Id$
#
########################################################################

class Platform < ActiveRecord::Base

  has_one :board
  
  has_many :board_design_entries

  validates_uniqueness_of :name
  validates_presence_of :name


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
  # This method returns a list of the active platforms
  #
  # Parameters:
  # sort - specifies the field(s) and sort order
  #
  # Return value:
  # An array of active platform records
  #
  ######################################################################
  #
  def Platform.get_all_active(sort = 'name ASC')
    Platform.find_all_by_active(1, sort)
  end
  
  
end
