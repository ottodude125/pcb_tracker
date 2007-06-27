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
  def self.get_review_roles
    self.find(:all, 
              :conditions => 'reviewer=1 AND active=1',
              :order      => 'display_name')
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
  def self.lcr_designers
  
    self.find(:first, 
              :conditions => "name='Designer'").active_users.delete_if { |d| d.employee? }
    
  end
  
  
  ######################################################################
  #
  # active_designers
  #
  # Description:
  # Provide a list of the active designers.
  #
  # Parameters:
  # None
  #
  # Return value:
  # An array of user records for the active designers
  #
  ######################################################################
  #
  def self.active_designers
    self.find(:first, :conditions => "name='Designer'").active_users
  end
  
  
  ######################################################################
  #
  # find_all_active
  #
  # Description:
  # This method returns a list of all active roles
  #
  # Parameters:
  # None
  #
  # Return value:
  # An array of review role records
  #
  ######################################################################
  #
  def self.find_all_active
    self.find(:all, :conditions => 'active=1', :order => 'display_name' )
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
    self.users.delete_if { |u| !u.active? }.sort_by { |usr| usr.last_name }
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
