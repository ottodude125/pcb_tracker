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

  has_many :board_reviewers

  has_many :board_design_entry_users
  has_many :design_review_results

  has_and_belongs_to_many :review_types
  has_and_belongs_to_many :users


  validates_uniqueness_of :name
  
  
  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################

  
  ######################################################################
  #
  # get_review_roles
  #
  # Description:
  # This method returns a list of the review roles
  #
  # Parameters:
  # None
  #
  # Return value:
  # An array of review role records
  #
  ######################################################################
  #
  def Role.get_review_roles
    Role.find_all_by_reviewer(1).sort_by { |r| r.display_name}
  end


  ######################################################################
  #
  # lcr_designers
  #
  # Description:
  # Provide a list of the LCR designers.
  #
  # Parameters:
  # None
  #
  # Return value:
  # An array of user records
  #
  ######################################################################
  #
  def Role.lcr_designers
  
    list = Role.find_by_name('Designer').users.delete_if { |d| !d.active? || d.employee? }
    list.sort_by { |d| d.last_name }
    
  end


  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################

  
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


  ######################################################################
  #
  # include?
  #
  # Description:
  # This method determines if the role should be included based on the 
  # entities design type.
  #
  # Parameters:
  # design_type - the entity's design type.
  #
  # Return value:
  # TRUE if the role is included in the entities design_type.  Otherwise
  # FALSE.
  #
  ######################################################################
  #
  def include?(design_type)

    #design_type = design_type.downcase.sub(/ /, '_')
    self.send(design_type.downcase.sub(/ /, '_') + '_design_type?')

  end
  
  
end
