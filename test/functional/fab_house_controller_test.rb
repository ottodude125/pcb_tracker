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

    set_admin
    merix = fab_houses(:merix)
    get(:edit,
        :id => merix.id)

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

    set_admin
    ibm = fab_houses(:ibm)
    fab_house      = FabHouse.find(ibm.id)
    fab_house.name = 'new_fab_house'

    get(:update,
        :fab_house => fab_house.attributes)

    assert_equal('Update recorded', flash['notice'])
    assert_redirected_to(:action => 'edit',
                         :id     => fab_house.id)
    assert_equal('new_fab_house', fab_house.name)
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

    assert_equal(8, FabHouse.find_all.size)

    new_fab_house = {
      'active' => '1',
      'name'   => 'FabsRus'
    }

    set_admin
    post(:create,
         :new_fab_house => new_fab_house)

    assert_equal(9,               FabHouse.find_all.size)
    assert_equal("FabsRus added", flash['notice'])
    assert_redirected_to :action => 'list'

    post(:create,
         :new_fab_house => new_fab_house)
    assert_equal(9,                             FabHouse.find_all.size)
    assert_equal("Name has already been taken", flash['notice'])
    assert_redirected_to :action => 'add'

  end


end
