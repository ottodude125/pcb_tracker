########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: division_controller_test.rb
#
# This file contains the functional tests for division_controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'division_controller'

# Re-raise errors caught by the controller.
class DivisionController; def rescue_action(e) raise e end; end

class DivisionControllerTest < Test::Unit::TestCase
  def setup
    @controller = DivisionController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:divisions,
	       :users)


  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the Division class
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

    assert_equal(3, assigns(:divisions).size)
  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the test_edit method
  # from the Division class
  #
  ######################################################################
  #
  def test_edit
    
    # Try editing from an Admin account
    set_admin
    post(:edit, :id => divisions(:std).id)

    assert_response 200
    assert_equal(divisions(:std).name, assigns(:division).name)

    assert_raise(ActiveRecord::RecordNotFound) {
      post(:edit, :id => 1000000)
    }
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

    division = Division.find(divisions(:std).id)
    division.name = 'WD-40'

    set_admin
    get(:update, :division => division.attributes)

    assert_equal('Division ' + division.name + ' was successfully updated.',
                 flash['notice'])
    assert_redirected_to(:action => 'edit', :id => division.id)
    assert_equal('WD-40', division.name)
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

    assert_equal(3, Division.find_all.size)

    set_admin
    post(:create, :new_division => { 'active' => '1', 'name' => 'LTX' })

    assert_equal(4,	Division.find_all.size)
    assert_equal("Division LTX added", flash['notice'])
    assert_redirected_to(:action => 'list')
    
    post(:create, :new_division => { 'active' => '1', 'name' => 'LTX' })

    assert_equal(4,	Division.find_all.size)
    assert_equal("Name has already been taken", flash['notice'])
    assert_redirected_to(:action => 'add')


    post(:create,
	     :new_project => { 'active' => '1', 'name' => '' })
    
    assert_equal(4,	Division.find_all.size)
    assert_equal("Name can't be blank", flash['notice'])
    assert_redirected_to(:action => 'add')

  end


end
