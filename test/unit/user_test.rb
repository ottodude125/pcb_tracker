########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File_: user_test.rb
#
# This file contains the unit tests for the user model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

# Set salt to 'change-me' because thats what the fixtures assume. 
User.salt = 'change-me'

class UserTest < Test::Unit::TestCase
  
  fixtures :roles,
           :users
  
  
  def setup
    
    @scott_g   = users(:scott_g)
    @jim_l     = users(:jim_l)
    @cathy_m   = users(:cathy_m)
    @patrice_m = users(:patrice_m)
    
    @designer       = roles(:designer)
    @pcb_management = roles(:manager)
    @ops_manager    = roles(:operations_manager)
    @pcb_admin      = roles(:pcb_admin)
    @tracker_admin  = roles(:admin)
    @valor          = roles(:valor)
    
  end
  
  
  def test_in_role_methods
    
    new_user = User.new
    
    # is_manager?
    assert(!@scott_g.is_manager?)
    assert(@jim_l.is_manager?)
    assert(!new_user.is_manager?)
    new_user.roles << @ops_manager
    assert(new_user.is_manager?)
    new_user.roles.destroy_all
    assert(!new_user.is_manager?)
    
    # is_reviewer?
    assert(!@patrice_m.is_reviewer?)
    assert(@scott_g.is_reviewer?)
    assert(!new_user.is_reviewer?)
    new_user.roles << @valor
    assert(new_user.is_reviewer?)
    new_user.roles.destroy_all
    assert(!new_user.is_reviewer?)
    
    # is_designer?
    assert(!@patrice_m.is_designer?)
    assert(@scott_g.is_designer?)
    assert(!new_user.is_designer?)
    new_user.roles << @designer
    assert(new_user.is_designer?)
    new_user.roles.destroy_all
    assert(!new_user.is_designer?)
    
    # is_pcb_management?
    assert(!@scott_g.is_pcb_management?)
    assert(@jim_l.is_pcb_management?)
    assert(!new_user.is_pcb_management?)
    new_user.roles << @pcb_management
    assert(new_user.is_pcb_management?)
    new_user.roles.destroy_all
    assert(!new_user.is_pcb_management?)
    
    # is_tracker_admin?
    assert(@cathy_m.is_tracker_admin?)
    assert(!@scott_g.is_tracker_admin?)
    assert(!new_user.is_tracker_admin?)
    new_user.roles << @tracker_admin
    assert(new_user.is_tracker_admin?)
    new_user.roles.destroy_all
    assert(!new_user.is_tracker_admin?)
    
    # is_pcb_admin?
    assert(@patrice_m.is_pcb_admin?)
    assert(!@scott_g.is_pcb_admin?)
    assert(!new_user.is_pcb_admin?)
    new_user.roles << @pcb_admin
    assert(new_user.is_pcb_admin?)
    new_user.roles.destroy_all
    assert(!new_user.is_pcb_admin?)
    
  end
   
    
  def test_auth
    
    assert_equal  users(:bob), User.authenticate("bob", "test")    
    assert_nil    User.authenticate("nonbob", "test")
    
  end

  def test_disallowed_passwords
    
    u = User.new    
    u.login = "nonbob"

    u.password = u.password_confirmation = "tiny"
    assert !u.save     
    assert u.errors.invalid?('password')

    u.password = u.password_confirmation = "hugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehuge"
    assert !u.save     
    assert u.errors.invalid?('password')
        
    u.password = u.password_confirmation = ""
    assert !u.save    
    assert u.errors.invalid?('password')
        
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save     
    assert u.errors.empty?
        
  end
  
  def test_bad_logins

    u = User.new  
    u.password = u.password_confirmation = "bobs_secure_password"

    u.login = "x"
    assert !u.save     
    assert u.errors.invalid?('login')
    
    u.login = "hugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhug"
    assert !u.save     
    assert u.errors.invalid?('login')

    u.login = ""
    assert !u.save
    assert u.errors.invalid?('login')

    u.login = "okbob"
    assert u.save  
    assert u.errors.empty?
      
  end


  def test_accessors
    
    assert_equal('McLaren, Cathy', @cathy_m.last_name_first)
    assert_equal('m',              @cathy_m.alpha_char)
    
    assert(!@jim_l.has_access?(['Designer']))
    assert(@scott_g.has_access?(['Designer']))
    
  end


  def test_collision
    u = User.new
    u.login      = "existingbob"
    u.password = u.password_confirmation = "bobs_secure_password"
    assert !u.save
  end


  def test_create
    u = User.new
    u.login      = "nonexistingbob"
    u.password = u.password_confirmation = "bobs_secure_password"
      
    assert u.save  
    assert(u.employee?)
    
  end
  
  def test_sha1
    u = User.new
    u.login      = "nonexistingbob"
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save
        
    assert_equal('98740ff87bade6d895010bceebbd9f718e7856bb', u.password)
    
    u.password = ''
    u.login    = 'NonExistingBob'
    assert(u.password.empty?)
    assert(u.update)
    
    u.reload
    assert_equal('NonExistingBob',                           u.login)
    assert_equal('98740ff87bade6d895010bceebbd9f718e7856bb', u.password)
    
  end

  
end
