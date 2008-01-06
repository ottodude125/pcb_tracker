########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: prefix.rb
#
# This file maintains the state for fab houses.
#
# $Id$
#
########################################################################

class FabHouse < ActiveRecord::Base

  has_many :ftp_notifications

  has_and_belongs_to_many :boards
  has_and_belongs_to_many :designs

  validates_uniqueness_of :name
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
  # This method returns a list of the active fab houses
  #
  # Parameters:
  # sort - specifies the field(s) and sort order
  #
  # Return value:
  # An array of active fab house records
  #
  ######################################################################
  #
  def FabHouse.get_all_active(sort = 'name ASC')
    FabHouse.find(:all, :conditions => 'active=1', :order => sort)
  end


end
