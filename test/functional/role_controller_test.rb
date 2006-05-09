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


  def test_1_id
    print ("\n*** Role Controller Test\n")
    print ("*** $Id$\n")
  end

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
    set_non_admin
    post :list

    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    set_admin
    post(:list, 
         :page => 1)

    assert_equal(21, assigns(:roles).size)

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

   assert_equal(21, Role.find_all.size)

    new_role = {
      'active' => '1',
      'name'   => 'HW_Engineer'
    }

    set_admin
    post(:create,
         :new_role  => new_role);

    assert_equal(22, Role.find_all.size)
    assert_equal("Role #{new_role['name']} added", flash['notice'])
    assert_redirected_to(:action => 'list')

    post(:create,
         :new_role => new_role);

    assert_equal(22, Role.find_all.size)
    assert_equal("Name has already been taken", flash['notice'])
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

    # Try editing from an Admin account
    set_admin
    post(:edit,
         :id     => roles(:designer).id)

    assert_response 200
    assert_equal(roles(:designer).name, assigns(:role).name)

    assert_raise(ActiveRecord::RecordNotFound) {
      post(:edit, :id     => 1000000)
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

    set_admin
    get(:update,
        :role => role.attributes)

    assert_equal('Role was successfully updated.', flash['notice'])
    assert_redirected_to(:action => 'edit',
                         :id     => role.id)
    assert_equal('Mazda', role.name)

  end


end
