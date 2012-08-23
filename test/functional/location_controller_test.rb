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
require File.expand_path( "../../test_helper", __FILE__ )
require 'location_controller'

# Re-raise errors caught by the controller.
class LocationController; def rescue_action(e) raise e end; end

class LocationControllerTest < ActionController::TestCase
  
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
    post(:list, {}, rich_designer_session)
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    post(:list, { :page => 1 }, cathy_admin_session)
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
    
    admin_session = cathy_admin_session
    # Try editing from an Admin account
    post(:edit, {:id => locations(:fridley).id}, admin_session)
    assert_response 200
    assert_equal(locations(:fridley).name, assigns(:location).name)

    assert_raise(ActiveRecord::RecordNotFound) do
      post(:edit, {:id => 1000000}, admin_session) 
    end

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

    post(:update, { :location => location.attributes }, cathy_admin_session)
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

    location_count = Location.count

    admin_session = cathy_admin_session
    post(:create,
         { :new_location => { 'active' => '1', 'name' => 'Pittsburgh' } },
         admin_session)
    location_count += 1
    assert_equal(location_count,              Location.count)
    assert_equal("Location Pittsburgh added", flash['notice'])
    assert_redirected_to(:action => 'list')
    
    post(:create,
         { :new_location => { 'active' => '1', 'name' => 'Pittsburgh' } },
         admin_session)
    assert_equal(location_count,                Location.count)
    #assert_equal("Name has already been taken", flash['notice'])
    assert_redirected_to(:action => 'add')

    post(:create,
         { :new_location => { 'active' => '1', 'name' => ' ' } },
         admin_session)
    assert_equal(location_count,        Location.count)
    #assert_equal("Name can't be blank", flash['notice'])
    assert_redirected_to(:action => 'add')

  end


end
