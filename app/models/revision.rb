########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: revision.rb
#
# This file maintains the state for revisions.
#
# $Id$
#
########################################################################

class Revision < ActiveRecord::Base

  has_one :audit
  
  has_many :board_design_entries
  has_many :designs

  
  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################

  
  ######################################################################
  #
  # get_revisions
  #
  # Description:
  # This method returns a list of revisions
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of all revision records in the database.
  #
  ######################################################################
  #
  def self.get_revisions
    self.find(:all, :order => 'name')
  end


end
