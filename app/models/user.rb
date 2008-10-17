########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: user.rb
#
# This file maintains the state for users.
#
# $Id$
#
########################################################################

require 'digest/sha1'

# this model expects a certain database layout and its based on the name/login pattern. 
class User < ActiveRecord::Base

  belongs_to :design_center
  belongs_to :division
  belongs_to :location
  
  has_many :audit_comments
  has_many :audit_teammates
  has_many :board_design_entries
  has_many :board_design_entry_users
  has_many :design_review_comments
  has_many :design_update
  has_many :eco_comments
  has_many :eco_documents
  has_many :oi_assignments
  has_many :oi_assignment_comments
  has_many :oi_assignment_reports
  has_many :oi_instructions

  has_and_belongs_to_many :boards
  has_and_belongs_to_many :eco_tasks
  has_and_belongs_to_many :ipd_posts
  has_and_belongs_to_many :roles


  # Please change the salt to something else, 
  # Every application should use a different one 
  @@salt = 'GO_PIRATES!!!'
  cattr_accessor :salt

  # Authenticate a user. 
  #
  # Example:
  #   @user = User.authenticate('bob', 'bobpass')
  #
  def self.authenticate(login, pass)
    #logger.info "********** AUTHENTICATE ************"
    #logger.info "    Login:            #{login}"
    #logger.info "    Password:         #{pass}"
    #logger.info "    Password(salted): #{sha1(pass)}"
    find_by_login_and_password(login, sha1(pass))
  end
  
  
  ######################################################################
  #
  # is_manager?
  #
  # Description:
  # Determines if the user is manager reviewer.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the user is manager reviewer,  Otherwise FALSE.
  #
  ######################################################################
  #
  def is_manager?
    self.roles.detect { |r| r.manager? } != nil
  end
  
  
  ######################################################################
  #
  # is_reviewer?
  #
  # Description:
  # Determines if the user is a reviewer.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the user is a reviewer,  Otherwise FALSE.
  #
  ######################################################################
  #
  def is_reviewer?
     self.reviewer_role != nil
  end
  
  
  # Set the user's active role.
  #
  # :call-seq:
  #   active_role=(role) -> boolean
  #
  #  Set the user's active role to the role passed in.
  def active_role=(role)
    self.active_role_id        = role.id
    self.password              = self.passwd
    self.password_confirmation = self.passwd
    self.update_attribute(:active_role_id, role.id)
  end

  # Retrieve the user's active role.
  #
  # :call-seq:
  #   active_role(role) -> role
  #
  #  Retrieve the user's active role to the role passed in.
  def active_role
    Role.find(self.active_role_id)
  end
  
  
  # Retrieve the first reviewer role record from the user's list of role
  # records.
  #
  # :call-seq:
  #   reviewer_role() -> role
  #
  #  Look through the user's list of roles for a reviewer role record.  
  #  If a reviewer role record is detected then the it is returned.
  #  Otherwise a Nil is returned.
  def reviewer_role
    self.roles.detect { |r| r.reviewer? }
  end
  
  
  # Indicate if the user is assigned to the role identified by the role name.
  #
  # :call-seq:
  #   is_a_role_member?() -> boolean
  #
  #  Returns TRUE if the user is assigned to the role.
  def is_a_role_member?(role_name)
    self.roles.detect { |r| r.name == role_name } != nil
  end
  
  
  # Indicate if the user is designer from a low cost region.
  #
  # :call-seq:
  #   is_an_lcr_designer?() -> boolean
  #
  #  Returns TRUE if the user is a designer from a low cost region.
  def is_an_lcr_designer?
    designer = self.roles.detect { |r| r.name == 'Designer'}
    designer && !self.employee?
  end
  
  ######################################################################
  #
  # is_designer?
  #
  # Description:
  # Determines if the user is in PCB designer.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the user is a pcb designer,  Otherwise FALSE.
  #
  ######################################################################
  #
  def is_designer?
    self.designer_role != nil
  end
  
  
  # Retrieve the designer role record from the user's list of roles
  # records.
  #
  # :call-seq:
  #   designer_role() -> role
  #
  #  Look through the user's list of roles for a designer role record.  
  #  If a designer role record is detected then it is returned.
  #  Otherwise a Nil is returned.
 def designer_role
    self.roles.detect { |r| r.name == 'Designer'}
  end
  
  
  ######################################################################
  #
  # is_pcb_management?
  #
  # Description:
  # Determines if the user is in PCB management.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the user is in pcb management,  Otherwise FALSE.
  #
  ######################################################################
  #
  def is_pcb_management?
    self.pcb_management_role != nil
  end
  
  
  # Retrieve the PCB management role record from the user's list of roles
  # records.
  #
  # :call-seq:
  #   pcb_management_role() -> role
  #
  #  Look through the user's list of roles for a PCB management role record.  
  #  If a PCB management role record is detected then it is returned.
  #  Otherwise a Nil is returned.
  def pcb_management_role
    self.roles.detect { |r| r.name == 'Manager' }
  end
  
  
  ######################################################################
  #
  # is_tracker_admin?
  #
  # Description:
  # Determines if the user is a tracker administrator.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the user is a tracker administrator,  Otherwise FALSE.
  #
  ######################################################################
  #
  def is_tracker_admin?
    self.tracker_admin_role != nil
  end
  
  
  # Retrieve the tracker admin role record from the user's list of roles
  # records.
  #
  # :call-seq:
  #   tracker_admin_role() -> role
  #
  #  Look through the user's list of roles for a tracker admin role record.  
  #  If a tracker admin role record is detected then it is returned.
  #  Otherwise a Nil is returned.
  def tracker_admin_role
    self.roles.detect { |r| r.name == 'Admin'}
  end
  
  
  ######################################################################
  #
  # is_pcb_admin?
  #
  # Description:
  # Determines if the user is a pcb admin.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the user is a pcb administrator,  Otherwise FALSE.
  #
  ######################################################################
  #
  def is_pcb_admin?
    self.pcb_admin_role != nil
  end
  
  
  # Retrieve the PCB admin role record from the user's list of roles
  # records.
  #
  # :call-seq:
  #   pcb_admin_role() -> role
  #
  #  Look through the user's list of roles for a PCB admin role record.  
  #  If a PCB admin role record is detected then it is returned.
  #  Otherwise a Nil is returned.
  def pcb_admin_role
    self.roles.detect { |r| r.name == 'PCB Admin' }
  end
  

  ######################################################################
  #
  # name
  #
  # Description:
  # This method returns the user's name.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A string containing the user's name (last name first).
  #
  ######################################################################
  #
  def name 
    self.first_name + ' ' + self.last_name
  end
  
  
  ######################################################################
  #
  # last_name_first
  #
  # Description:
  # This method returns the user's name, last name first.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A string containing the user's name (last name first).
  #
  ######################################################################
  #
  def last_name_first
    self.last_name + ', ' + self.first_name
  end
  
  
  ######################################################################
  #
  # alpha_char
  #
  # Description:
  # Provides the downcased first character of the user's last name.
  #
  # Return value:
  # The lowercase first character of the user's last name.
  #
  ######################################################################
  #
  def alpha_char
    self.last_name[0..0].downcase
  end
  
  
  ######################################################################
  #
  # has_access?
  #
  # Description:
  # Indicates that the user has access based on role.
  # 
  # Parameters:
  # required_roles - an array of roles that are permitted access to the 
  # resource.
  #
  # Return value:
  # A boolean value that indicates that the user has access to the 
  # resource if set to TRUE.
  #
  ######################################################################
  #
  def has_access?(required_roles)
    (self.roles.collect { |r| r.name } & required_roles).size > 0
  end


  protected

  # Apply SHA1 encryption to the supplied password. 
  # We will additionally surround the password with a salt 
  # for additional security. 
  def self.sha1(pass)
    Digest::SHA1.hexdigest("#{salt}--#{pass}--")
  end
    
  before_create :crypt_password
  
  # Before saving the record to database we will crypt the password 
  # using SHA1. 
  # We never store the actual password in the DB.
  def crypt_password
    write_attribute "password", self.class.sha1(password)
  end
  
  before_update :crypt_unless_empty
  
  # If the record is updated we will check if the password is empty.
  # If its empty we assume that the user didn't want to change his
  # password and just reset it to the old value.
  def crypt_unless_empty
    if password.empty?   
      user = self.class.find(self.id)
      self.password = user.password
    else
      write_attribute "password", self.class.sha1(password)
    end        
  end  
  
  validates_uniqueness_of :login, :on => :create

  validates_confirmation_of :password
  validates_length_of :login, :within => 3..40
  validates_length_of :password, :within => 5..40
  validates_presence_of :login, :password, :password_confirmation
end
