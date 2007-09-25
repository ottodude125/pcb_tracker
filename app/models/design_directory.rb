########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_directoryrb
#
# This file maintains the state for design_directories.
#
# $Id$
#
########################################################################

class DesignDirectory < ActiveRecord::Base
  
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
  # get_active_design_directories
  #
  # Description:
  # This method returns a list of the active design directory records
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of active design directory records
  #
  ######################################################################
  #
  def self.get_active_design_directories
    self.find(:all, :conditions => 'active=1', :order => 'name')
  end


end
