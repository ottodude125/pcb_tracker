########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: project.rb
#
# This file maintains the state for projects.
#
# $Id$
#
########################################################################

class Project < ActiveRecord::Base

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
  # This method returns a list of the active projects
  #
  # Parameters:
  # sort - specifies the field(s) and sort order
  #
  # Return value:
  # An array of active project records
  #
  ######################################################################
  #
  def Project.get_all_active(sort = 'name ASC')
    Project.find_all_by_active(1, sort)
  end


end
