########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: role.rb
#
# This file maintains the state for roles.
#
# $Id$
#
########################################################################

class Role < ActiveRecord::Base
#  has_and_belongs_to_many :permissions

  has_many :design_review_results

  has_and_belongs_to_many :review_types
  has_and_belongs_to_many :users


  validates_uniqueness_of :name
  
  
  ######################################################################
  #
  # active_users
  #
  # Description:
  # This method returns an alphabetized list of active users for
  # the role.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of User records.
  #
  ######################################################################
  #
  def active_users

    users = self.users
    users.delete_if { |u| !u.active? }

    return users.sort_by { |u| u.last_name}

  end


end
