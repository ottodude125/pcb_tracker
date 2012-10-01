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
require File.expand_path( "../../test_helper", __FILE__ )
require 'division_controller'

# Re-raise errors caught by the controller.
class DivisionController; def rescue_action(e) raise e end; end

class DivisionControllerTest < ActionController::TestCase
  
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
    get(:list, {}, rich_designer_session)
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    get(:list, {:page => 1}, cathy_admin_session)
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
    
    admin_session = cathy_admin_session
    
    # Try editing from an Admin account
    get(:edit, {:id => divisions(:std).id}, admin_session)
    assert_response 200
    assert_equal(divisions(:std).name, assigns(:division).name)

    assert_raise(ActiveRecord::RecordNotFound) { post(:edit, {:id => 1000000}, admin_session) }
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

    put(:update, {:division => division.attributes}, cathy_admin_session)
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

    division_count = Division.count

    admin_session = cathy_admin_session
    
    put(:create,
        { :new_division => { 'active' => '1', 'name' => 'LTX' } },
        admin_session)
    division_count += 1
    assert_equal(division_count,       Division.count)
    assert_equal("Division LTX added", flash['notice'])
    assert_redirected_to(:action => 'list')
    
    put(:create, 
        { :new_division => { 'active' => '1', 'name' => 'LTX' } },
        admin_session)
    assert_equal(division_count,                Division.count)
    #assert_equal("Name has already been taken", flash['notice'])
    assert_redirected_to(:action => 'add')


    put(:create,
        { :new_project => { 'active' => '1', 'name' => '' } },
        admin_session)
    assert_equal(division_count,        Division.count)
    #assert_equal("Name can't be blank", flash['notice'])
    assert_redirected_to(:action => 'add')

  end


end
