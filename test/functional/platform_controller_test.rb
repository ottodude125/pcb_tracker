########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: platform_controller_test.rb
#
# This file contains the functional tests for the platform controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'platform_controller'

# Re-raise errors caught by the controller.
class PlatformController; def rescue_action(e) raise e end; end

class PlatformControllerTest < Test::Unit::TestCase
  
  
  def setup
    @controller = PlatformController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:platforms,
           :roles_users,
           :roles,
           :users)


  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the Platform class
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
    get(:list, {}, rich_designer_session)
    assert_redirected_to(:controller => 'tracker',  :action => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The platform list data is retrieved
    post(:list, { :page => 1 }, cathy_admin_session)
    assert_equal(5, assigns(:platforms).size)

  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the edit method
  # from the Platform class
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
    get(:edit, { :id => platforms(:panther).id }, admin_session)
    assert_response 200
    assert_equal(platforms(:panther).name, assigns(:platform).name)

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
  # from the Platform Controller class
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

    platform = Platform.find(platforms(:flex).id)
    platform.name = 'Yugo'

    get(:update, { :platform => platform.attributes }, cathy_admin_session)
    assert_equal('Platform was successfully updated.', flash['notice'])
    assert_redirected_to(:action => 'edit', :id => platform.id)
    assert_equal('Yugo', platform.name)
  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the Platform Controller class
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

    admin_session = cathy_admin_session
    # Verify that a platform can be added.  The number of platforms will
    # increase by one.
    assert_equal(5, Platform.count)

    new_platform = { 'active' => '1', 'name'   => 'Thunderbird' }

    post(:create, { :new_platform => new_platform }, admin_session)
    assert_equal(6, Platform.count)
    assert_equal("Platform #{new_platform['name']} added", flash['notice'])
    assert_redirected_to(:action => 'list')
    
    # Try to add a second platform with the same name.
    # It should not get added.
    post(:create, { :new_platform => new_platform }, admin_session)
    assert_equal(6, Platform.count)
    #assert_equal("Name has already been taken", flash['notice'])
    assert_redirected_to(:action => 'add')


    # Try to add a platform withhout a name.
    # It should not get added.
    post(:create, { :new_platform => { 'active' => '1', 'name' => '' } }, admin_session)
    assert_equal(6, Platform.count)
    #assert_equal("Name can't be blank", flash['notice'])
    assert_redirected_to(:action => 'add')

  end


end
