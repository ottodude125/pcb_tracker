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

  def test_create

    assert_kind_of Role,  @role

    admin = roles(:admin)
    assert_equal(admin.id,     @role.id)
    assert_equal(admin.name,   @role.name)
    assert_equal(admin.active, @role.active)

  end

  def test_update
    
    @role.name   = "Administrator"
    @role.active = 0

    assert @role.save
    @role.reload

    assert_equal("Administrator", @role.name)
    assert_equal(0,               @role.active)

  end

  def test_destroy
    @role.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Role.find(@role.id) }
  end
  
  
  ######################################################################
  #
  # test_users
  #
  # Description:
  # Validates the behaviour of the following methods.
  #
  #   active_users()
  #
  ######################################################################
  #
  def test_users

    all_designers = Role.find_by_name('Designer').users
    assert_equal(4, all_designers.size)
    all_designers.delete_if  { |u| !u.active? }
    assert_equal(3, all_designers.size)
    all_designers = all_designers.sort_by { |u| u.last_name }
    
    active_designers = Role.find_by_name('Designer').active_users
    assert_equal(all_designers, active_designers)
    
  end

end
