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
require 'design_center_controller'

# Re-raise errors caught by the controller.
class DesignCenterController; def rescue_action(e) raise e end; end

class DesignCenterControllerTest < Test::Unit::TestCase
  def setup
    @controller = DesignCenterController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end



  fixtures(:design_centers,
           :users)


  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the DesignCenter class
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

    # Try listing from a non-Admin account.
    # VERIFY: The user is redirected.
    set_non_admin
    post(:list)

    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    set_admin
    post(:list, :page => 1)

    assert_equal(3, assigns(:design_centers).size)

  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the edit method
  # from the DesignCenter class
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
    fridley = design_centers(:fridley)
    get(:edit,:id => fridley.id)

    assert_equal(fridley.name, assigns(:design_center).name)
    
  end

  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update method
  # from the DesignCenter Controller class
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

    design_center          = DesignCenter.find(design_centers(:fridley).id)
    design_center.name     = 'San Jose'
    design_center.pcb_path = '/hwnet/board_sj'
    design_center.hw_path  = '/hwnet/hw_sj'

    set_admin
    get(:update, :design_center => design_center.attributes)

    assert_equal('Update recorded', flash['notice'])
    assert_redirected_to(:action => 'edit', :id => design_center.id)
    assert_equal('San Jose', design_center.name)
  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the DesignCenter Controller class
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

    design_center_count = DesignCenter.count
    assert_equal(design_center_count, DesignCenter.count)

    new_design_center = {
      'active'   => '1',
      'name'     => 'Pembroke',
      'pcb_path' => '/hwnet/board_pem',
      'hw_path'  => '/hwnet/hw_pem'
    }

    set_admin
    post(:create, :new_design_center => new_design_center)

    design_center_count += 1
    assert_equal(design_center_count, DesignCenter.count)
    assert_equal("Pembroke added",    flash['notice'])
    assert_redirected_to(:action => 'list')

    post(:create, :new_design_center => new_design_center)
    assert_equal(design_center_count,           DesignCenter.count)
    assert_equal("Name has already been taken", flash['notice'])
    assert_redirected_to(:action => 'add')

  end


end
