########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: location.rb
#
# This file maintains the state for locations.
#
# $Id$
#
########################################################################

class Location < ActiveRecord::Base

  validates_uniqueness_of :name
  validates_presence_of :name
  
  
  has_many :users


  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################

  
  ######################################################################
  #
  # get_active_locations
  #
  # Description:
  # This method returns a list of the active location records
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of active location records
  #
  ######################################################################
  #
  def self.get_active_locations
    self.find(:all, :conditions => 'active=1', :order => 'name')
  end


end
