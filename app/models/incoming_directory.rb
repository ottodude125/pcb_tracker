########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: incoming_directory.rb
#
# This file maintains the state for incoming directories.
#
# $Id$
#
########################################################################

class IncomingDirectory < ActiveRecord::Base
  
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
  # get_active_incoming_directories
  #
  # Description:
  # This method returns a list of the active incoming directory records
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of active incoming directory records
  #
  ######################################################################
  #
  def self.get_active_incoming_directories
    self.find(:all, :conditions => 'active=1', :order => 'name')
  end


end
