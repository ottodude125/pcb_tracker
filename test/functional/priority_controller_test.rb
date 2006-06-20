########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: priority_controller_test.rb
#
# This file contains the functional tests for the priority controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'priority_controller'

# Re-raise errors caught by the controller.
class PriorityController; def rescue_action(e) raise e end; end

class PriorityControllerTest < Test::Unit::TestCase
  def setup
    @controller = PriorityController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:priorities,
           :users)


  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the Priority class
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
    post :list
    set_non_admin
    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal('You are not authorized to view or modify priority information - check your role',
                 flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    set_admin
    post(:list,
         :page => 1)

    assert_equal(2, assigns(:priorities).size)
  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the edit method
  # from the Priority class
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
    low = priorities(:low)
    get(:edit,
        :id => low.id)

    assert_equal(low.name, assigns(:priority).name)
    
  end

  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update method
  # from the Priority Controller class
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

    priority      = Priority.find(priorities(:high).id)
    priority.name = '1'

    get(:update,
        :priority => priority.attributes)

    assert_equal('Update recorded', flash['notice'])
    assert_redirected_to(:action => 'edit',
                         :id     => priority.id)
    assert_equal('1', priority.name)
  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the Priority Controller class
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

    assert_equal(2, Priority.find_all.size)

    new_priority = {
      'value'  => 2,
      'name'   => 'Medium',
    }

    post(:create,
         :new_priority => new_priority)

    assert_equal(3, Priority.find_all.size)
    assert_equal("Medium added", flash['notice'])
    assert_redirected_to :action => 'list'

    post(:create,
         :new_priority => new_priority)
    assert_equal(3, Priority.find_all.size)
    assert_equal("Value must be unique", flash['notice'])
    assert_redirected_to :action => 'add'

    new_priority['value'] = 55
    post(:create,
         :new_priority => new_priority)
    assert_equal(3, Priority.find_all.size)
    assert_equal("Name already exists in the database", flash['notice'])
    assert_redirected_to :action => 'add'

    new_priority['value'] = 45.55
    post(:create,
         :new_priority => new_priority)
    assert_equal(3, Priority.find_all.size)
    assert_equal("Value - Review Priority must be an integer greater than 0",
                 flash['notice'])
    assert_redirected_to :action => 'add'

  end

end
