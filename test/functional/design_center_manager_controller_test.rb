########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_center_manager_controller_test.rb
#
# This file contains the functional tests for the design center
# manager controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'design_center_manager_controller'

# Re-raise errors caught by the controller.
class DesignCenterManagerController; def rescue_action(e) raise e end; end

class DesignCenterManagerControllerTest < Test::Unit::TestCase
  def setup
    @controller = DesignCenterManagerController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:design_centers,
           :users)


  def test_1_id
    print ("\n*** Design Center Mananager Controller Test\n")
    print ("*** $Id$\n")
  end


  ######################################################################
  #
  # test_design_center_assignment
  #
  # Description:
  # This method does the functional testing of the 
  # design_center_assignment method  from the DesignCenterManager class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #
  ######################################################################
  #
  def test_design_center_assignment

    # Verify response when not logged in.
    post :design_center_assignment

    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])


    # Verify response when logged in as a non-admin
    set_non_admin
    post :design_center_assignment

    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Verify response when logged in as an admin
    set_admin
    post :design_center_assignment

    assert_response :success

    designers      = assigns(designers)['designers']
    design_centers = assigns(design_centers)['design_centers']

    assert_equal(3,  designers.size)
    assert_equal(2,  design_centers.size)

  end


  ######################################################################
  #
  # test_assign_designers_to_centers
  #
  # Description:
  # This method does the functional testing of the 
  # assign_desingers_to_centers method  from the DesignCenterManager
  # class.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #
  ######################################################################
  #
  def test_assign_designers_to_centers

    designers = Role.find_by_name("Designer").users
    designers.delete_if { |designer| ! designer.active? }

    for designer in designers
      # They all start off based in Boston.
      assert_equal(design_centers(:boston_harrison).id,
                   designer.design_center_id)
    end

    fridley = design_centers(:fridley)
    set_admin
    post(:assign_designers_to_centers,
         users(:scott_g).id.to_s => {'id' => fridley.id},
         users(:rich_m).id.to_s  => {'id' => fridley.id},
         users(:bob_g).id.to_s   => {'id' => fridley.id})

    # Verify the update.
    designers = Role.find_by_name("Designer").users
    designers.delete_if { |designer| ! designer.active? }

    for designer in designers
      assert_equal(fridley.id, designer.design_center_id)
    end

  end


end
