########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: role_test.rb
#
# This file contains the unit tests for the role model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'


class RoleTest < Test::Unit::TestCase


  fixtures(:review_types_roles,
           :roles,
           :roles_users,
           :users)


  def setup
    @role = Role.find(roles(:admin).id)
  end


  ######################################################################
  def test_create

    assert_kind_of Role,  @role

    admin = roles(:admin)
    assert_equal(admin.id,     @role.id)
    assert_equal(admin.name,   @role.name)
    assert_equal(admin.active, @role.active)

  end


  ######################################################################
  def test_update
    
    @role.name   = "Administrator"
    @role.active = 0

    assert @role.save
    @role.reload

    assert_equal("Administrator", @role.name)
    assert_equal(0,               @role.active)

  end


  ######################################################################
  def test_destroy
    @role.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Role.find(@role.id) }
  end
  
  
  ######################################################################
  def test_users

    all_designers = Role.find_by_name('Designer').users
    assert_equal(6, all_designers.size)
    all_designers.delete_if  { |u| !u.active? }
    assert_equal(5, all_designers.size)
    all_designers = all_designers.sort_by { |u| u.last_name }
    
    active_designers = Role.find_by_name('Designer').active_users
    assert_equal(all_designers, active_designers)
    
  end
  
  
  ######################################################################
  def test_include
  
    role = Role.new
    
    assert(!role.include?('Date Code'))
    assert(!role.include?('date_code'))
    assert(!role.include?('Dot Rev'))
    assert(!role.include?('dot_rev'))
    assert(!role.include?('New'))
    assert(!role.include?('new'))
    
    role.new_design_type       = 1
    role.date_code_design_type = 1
    role.dot_rev_design_type   = 1
  
    assert(role.include?('Date Code'))
    assert(role.include?('date_code'))
    assert(role.include?('Dot Rev'))
    assert(role.include?('dot_rev'))
    assert(role.include?('New'))
    assert(role.include?('new'))
    
  end


  ######################################################################
  def test_find_all_active
  
    all_roles = Role.find(:all, :order => 'display_name')
    
    # Set the first 5 roles to inactive
    0.upto(4) do |i|
      all_roles[i].active = 0
      all_roles[i].update
    end
    
    active_roles = Role.find_all_active
    
    assert(all_roles.size > active_roles.size)
    
    role_name = ""
    active_roles.each do |role| 
      assert(role.active?)
      assert(role.display_name >= role_name)
      role_name = role.display_name
    end
    
    all_roles.delete_if { |r| !r.active? }
    
    assert_equal(all_roles.size, active_roles.size)
    assert_equal(all_roles, active_roles)
    
  end


  ######################################################################
  def test_get_review_roles
  
    all_roles      = Role.find(:all, :order => 'display_name')
    reviewer_roles = Role.get_review_roles
    
    assert(all_roles.size > reviewer_roles.size)
    
    # Remove all of the non-reviewer roles from the original list, 
    # all _roles, and verify that the remaining list matches the one
    # returned by get_review_roles()
    all_roles.delete_if { |r| !r.reviewer? }
    assert(all_roles == reviewer_roles)
    
    role_name = ''
    reviewer_roles.each do |role|
      assert(role.active?)
      assert(role.reviewer?)
      assert(role.display_name >= role_name)
      role_name = role.display_name
    end 
   
  end


  ######################################################################
  def test_lcr_designers
  
    all_designers = Role.find_by_name('Designer').users.sort_by { |u| u.last_name }
    lcr_designers = Role.lcr_designers
    
    assert(all_designers.size > lcr_designers.size)
    
    # Remove all of the non-reviewer roles from the original list, 
    # all _roles, and verify that the remaining list matches the one
    # returned by get_review_roles()
    all_designers.delete_if { |r| r.employee? }
    assert(all_designers == lcr_designers)    
   
  end


end
