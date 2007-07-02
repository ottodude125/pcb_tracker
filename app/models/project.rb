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
  # get_projects
  #
  # Description:
  # This method returns a list of the project records
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of project records
  #
  ######################################################################
  #
  def self.get_projects
    self.find(:all, :order => 'name')
  end


  ######################################################################
  #
  # get_active_projects
  #
  # Description:
  # This method returns a list of the active project records
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of active project records
  #
  ######################################################################
  #
  def self.get_active_projects
    self.find(:all, :conditions => 'active=1', :order => 'name')
  end


end
