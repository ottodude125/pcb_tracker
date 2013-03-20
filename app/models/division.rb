########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: division.rb
#
# This file maintains the state for divisions.
#
# $Id$
#
########################################################################

class Division < ActiveRecord::Base

  validates_uniqueness_of :name
  validates_presence_of :name


  has_many :ftp_notifications
  has_many :users


  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################

  
  ######################################################################
  #
  # get_active_divisions
  #
  # Description:
  # This method returns a list of the active division records
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of active division records
  #
  ######################################################################
  #
  def self.get_active_divisions
    self.find(:all, :conditions => 'active=1', :order => 'name')
  end


end
