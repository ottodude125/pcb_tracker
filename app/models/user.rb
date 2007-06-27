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
  has_many :board_design_entry_users
  has_many :design_review_comments
  has_many :design_update
  has_many :oi_assignments
  has_many :oi_assignment_comments
  has_many :oi_assignment_reports
  has_many :oi_instructions

  has_and_belongs_to_many :boards
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
