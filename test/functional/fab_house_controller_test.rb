########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: fab_house_controller_test.rb
#
# This file contains the functional tests for the fab house controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'fab_house_controller'

# Re-raise errors caught by the controller.
class FabHouseController; def rescue_action(e) raise e end; end

class FabHouseControllerTest < Test::Unit::TestCase
  
  def setup
    @controller = FabHouseController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end


  fixtures(:fab_houses,
           :users)


  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the FabHouse class
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
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    get(:list, {:page => 1}, cathy_admin_session)
    assert_equal(8, assigns(:fab_houses).size)
    
  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the edit method
  # from the FabHouse class
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

    merix = fab_houses(:merix)
    get(:edit, {:id => merix.id}, cathy_admin_session)
    assert_equal(merix.name, assigns(:fab_house).name)
    
  end

  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update method
  # from the FabHouse Controller class
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

    admin_session = cathy_admin_session
    
    ibm = fab_houses(:ibm)
    fab_house      = FabHouse.find(ibm.id)
    fab_house.name = 'new_fab_house'

    post(:update, { :fab_house => fab_house.attributes }, admin_session)
    assert_redirected_to(:action => 'edit', :id => fab_house.id)
    assert_equal('Update recorded', flash['notice'])
    assert_equal('new_fab_house',   fab_house.name)
    
    post(:update, 
         { :fab_house => { :name   => fab_house.name, 
                           :id     => fab_house.id.to_s, 
                           :active => fab_house.active.to_s } }, 
         cathy_admin_session)
    assert_redirected_to(:action => 'edit', :id => fab_house.id)
    #assert_equal('Update recorded', flash['notice'])
    
  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the FabHouse Controller class
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

    fab_house_count = FabHouse.count
    new_fab_house   = { 'active' => '1', 'name'   => 'FabsRus' }

    admin_session = cathy_admin_session
    
    post(:create, { :new_fab_house => new_fab_house }, admin_session)
    fab_house_count += 1
    assert_equal(fab_house_count, FabHouse.count)
    assert_equal("FabsRus added", flash['notice'])
    assert_redirected_to(:action => 'list')

    post(:create, { :new_fab_house => new_fab_house }, admin_session)
    assert_equal(fab_house_count,               FabHouse.count)
    #assert_equal("Name has already been taken", flash['notice'])
    assert_redirected_to(:action => 'add')

  end


end
