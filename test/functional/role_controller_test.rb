########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: role_controller_test.rb
#
# This file contains the functional tests for the role controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'role_controller'

# Re-raise errors caught by the controller.
class RoleController; def rescue_action(e) raise e end; end

class RoleControllerTest < Test::Unit::TestCase
  def setup
    @controller = RoleController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:review_types_roles,
           :roles,
           :users)


  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the Role class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_list

    # Try editing from a non-Admin account.
    # VERIFY: The user is redirected.
    get(:list, {}, {})
    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    get(:list, { :page => 1 }, cathy_admin_session)
    assert_equal(Role.find_all_active.size, assigns(:roles).size)

  end


  ######################################################################
  #
  # test_list_review_roles
  #
  # Description:
  # This method does the functional testing of the list review roles method
  # from the Role class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_list_review_roles

    # Try editing from a non-Admin account.
    # VERIFY: The user is redirected.
    get(:list_review_roles, {}, rich_designer_session)
    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    get(:list_review_roles, {}, cathy_admin_session)

    review_roles = Role.find_all_active
    review_roles.delete_if { |r| !r.reviewer? || r.manager? }
    assert_equal(review_roles, assigns(:review_roles))
  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the Role class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_create

   role_count = Role.count

    new_role = {
      'active'       => '1',
      'name'         => 'HW_Engineer',
      'display_name' => 'Hardware Engineer',
      'reviewer'     => '1',
      'manager'      => '1'
    }

    admin_session = cathy_admin_session
    
    post(:create, {:role  => new_role}, admin_session);

    role_count += 1
    assert_equal(role_count, Role.count)
    assert_equal("Role #{new_role['display_name']} added", flash['notice'])
    assert_redirected_to(:action => 'list')

    post(:create, { :role => new_role}, admin_session);

    assert_equal(role_count, Role.count)
    #assert_equal("Name has already been taken", flash['notice'])
    assert_redirected_to(:action => 'add')

  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the edit method
  # from the Role class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_edit

    admin_session = cathy_admin_session
    
    # Try editing from an Admin account
    get(:edit, { :id => roles(:designer).id }, admin_session)

    assert_response 200
    assert_equal(roles(:designer).name, assigns(:role).name)

    assert_raise(ActiveRecord::RecordNotFound) {
      get(:edit, { :id => 1000000 }, admin_session)
    }
  end


  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update method
  # from the Role class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_update

    role = Role.find(roles(:designer).id)
    role.name = 'Mazda'

    get(:update, { :role => role.attributes }, cathy_admin_session)

    assert_equal('Role was successfully updated.', flash['notice'])
    assert_redirected_to(:action => 'edit', :id => role.id)
    assert_equal('Mazda', role.name)

  end


end
