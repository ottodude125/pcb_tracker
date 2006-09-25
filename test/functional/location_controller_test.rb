########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: location_controller_test.rb
#
# This file contains the functional tests for location_controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'location_controller'

# Re-raise errors caught by the controller.
class LocationController; def rescue_action(e) raise e end; end

class LocationControllerTest < Test::Unit::TestCase
  def setup
    @controller = LocationController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:locations,
	       :users)


  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the Location class
  #
  ######################################################################
  #
  def test_list

    # Try editing from a non-Admin account.
    # VERIFY: The user is redirected.
    set_non_admin
    post :list

    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    set_admin
    post(:list, :page => 1)

    assert_equal(5, assigns(:locations).size)
  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the test_edit method
  # from the Location class
  #
  ######################################################################
  #
  def test_edit
    
    # Try editing from an Admin account
    set_admin
    post(:edit, :id => locations(:fridley).id)

    assert_response 200
    assert_equal(locations(:fridley).name, assigns(:location).name)

    assert_raise(ActiveRecord::RecordNotFound) { post(:edit, :id => 1000000) }

  end


  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update method
  # from the Division Controller class
  #
  ######################################################################
  #
  def test_update

    location = Location.find(locations(:fridley).id)
    location.name = 'Chicago'

    set_admin
    get(:update, :location => location.attributes)

    assert_equal('Location ' + location.name + ' was successfully updated.',
                 flash['notice'])
    assert_redirected_to(:action => 'edit', :id => location.id)
    assert_equal('Chicago', assigns(:location).name)
  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the Project Controller class
  #
  ######################################################################
  #
  def test_create

    assert_equal(5, Location.find_all.size)

    set_admin
    post(:create, :new_location => { 'active' => '1', 'name' => 'Pittsburgh' })

    assert_equal(6,	Location.find_all.size)
    assert_equal("Location Pittsburgh added", flash['notice'])
    assert_redirected_to(:action => 'list')
    
    post(:create, :new_location => { 'active' => '1', 'name' => 'Pittsburgh' })

    assert_equal(6,	Location.find_all.size)
    assert_equal("Name has already been taken", flash['notice'])
    assert_redirected_to(:action => 'add')


    post(:create, :new_location => { 'active' => '1', 'name' => '' })
    
    assert_equal(6,	Location.find_all.size)
    assert_equal("Name can't be blank", flash['notice'])
    assert_redirected_to(:action => 'add')

  end


end
