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
  # This method returns a list of the non-manager review roles
  #
  # Parameters:
  # None
  #
  # Return value:
  # An array of role records
  #
  ######################################################################
  #
  def self.get_review_roles
    self.find(:all, 
              :conditions => 'reviewer=1 AND active=1 AND manager=0',
              :order      => 'display_name')
  end


  ######################################################################
  #
  # get_defaulted_reviewer_roles
  #
  # Description:
  # This method returns a list of defaulted non-manager the review roles
  #
  # Parameters:
  # None
  #
  # Return value:
  # An array of role records
  #
  ######################################################################
  #
  def self.get_defaulted_reviewer_roles
    drr_list = self.get_review_roles
    drr_list.delete_if { |role| role.default_reviewer_id == 0 }
    drr_list
  end


  ######################################################################
  #
  # get_open_reviewer_roles
  #
  # Description:
  # This method returns a list of non-manager review roles that
  # do not have a default reviewer assigned
  #
  # Parameters:
  # None
  #
  # Return value:
  # An array of role records
  #
  ######################################################################
  #
  def self.get_open_reviewer_roles
    drr_list = self.get_review_roles
    #drr_list.delete_if { |role| role.default_reviewer_id != 0 }
    drr_list
  end


  ######################################################################
  #
  # get_manager_review_roles
  #
  # Description:
  # This method returns a list of the manager review roles
  #
  # Parameters:
  # None
  #
  # Return value:
  # An array of role records
  #
  ######################################################################
  #
  def self.get_manager_review_roles
    self.find(:all, 
              :conditions => 'reviewer=1 AND active=1 AND manager=1',
              :order      => 'display_name')
  end


  ######################################################################
  #
  # get_defaulted_manager reviewer_roles
  #
  # Description:
  # This method returns a list of defaulted manager the review roles
  #
  # Parameters:
  # None
  #
  # Return value:
  # An array of role records
  #
  ######################################################################
  #
  def self.get_defaulted_manager_reviewer_roles
    drr_list = self.get_manager_review_roles
    drr_list.delete_if { |role| role.default_reviewer_id == 0 }
    drr_list
  end


  ######################################################################
  #
  # get_open_manager_reviewer_roles
  #
  # Description:
  # This method returns a list of manager review roles that
  # do not have a default reviewer assigned
  #
  # Parameters:
  # None
  #
  # Return value:
  # An array of role records
  #
  ######################################################################
  #
  def self.get_open_manager_reviewer_roles
    drr_list = self.get_manager_review_roles
    drr_list.delete_if { |role| role.default_reviewer_id != 0 }
    drr_list
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
  
  
  ######################################################################
  #
  # included_in_design_review?
  #
  # Description:
  # Eetermines if the review role should be included in the design review.
  #
  # Parameters:
  # design - the record design for the design being reviewed
  #
  # Return value:
  # TRUE if the review role is included in the design review.  Otherwise
  # FALSE.
  #
  ######################################################################
  #
  def included_in_design_review?(design)
    (design.new?     && self.new_design_review_role?) ||
    (design.dot_rev? && self.bare_board_only_review_role?)
  end
  
  
  # Return a name that provides a general description for the role
  #
  # :call-seq:
  #   generalized_name() -> string
  #
  # Most roles will return the display name.  A class of roles, such as
  # the reviewer roles returns the classification name.
  def generalized_name
    self.reviewer? ? 'Reviewer' : self.display_name
  end

  
  # Return the user record for the default reviewer, if an active
  # default reviewer is set
  #
  # :call-seq:
  #   default_reviewer() -> record
  #
  # Reviewer roles with a default reviewer set return the reviewer's user
  # record.
  def default_reviewer
    if self.default_reviewer_id > 0
      default_reviewer = User.find(self.default_reviewer_id)
      return default_reviewer if default_reviewer.active?
    end
  end
  

end
