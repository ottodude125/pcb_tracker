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

  has_one    :design

  has_many   :design_reviews
  has_many   :ftp_notifications
  has_many   :users

  validates_uniqueness_of :name


  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


  @@h = @@h ||= Net::HTTP::new("boarddev.teradyne.com")

  
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
  def self.get_all_active(sort = 'name ASC')
    self.find_all_by_active(1, sort)
  end


  ##############################################################################
  #
  # Instance Methods
  #
  ##############################################################################


  def data_found?
    link     = "/surfboards/#{self.pcb_path}/#{self.design_review.design.directory_name}/"
    response = @@h.get(link)
    response.code == '200'
  end

  
end
