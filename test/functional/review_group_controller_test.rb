########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: review_group_controller_test.rb
#
# This file contains the functional tests for the review group controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'review_group_controller'

# Re-raise errors caught by the controller.
class ReviewGroupController; def rescue_action(e) raise e end; end

class ReviewGroupControllerTest < Test::Unit::TestCase
  def setup
    @controller = ReviewGroupController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:review_groups,
           :users)


  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the ReviewGroup class
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
    post :list

    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal('Administrators only!  Check your role.',
                 flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    set_admin
    post(:list,
         :page => 1)

    assert_equal(3, assigns(:review_groups).size)
  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the edit method
  # from the ReviewGroup class
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
    planning = review_groups(:planning)
    get(:edit,
        :id => planning.id)

    assert_equal(planning.name, assigns(:review_group).name)
    
  end

  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update method
  # from the ReviewGroup Controller class
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
    review_group      = ReviewGroup.find(review_groups(:valor).id)
    review_group.name = 'Test'

    get(:update,
        :review_group => review_group.attributes)

    assert_equal('Update recorded', flash['notice'])
    assert_redirected_to(:action => 'edit',
                         :id     => review_group.id)
    assert_equal('Test', review_group.name)
  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the ReviewGroup Controller class
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

    group_count = ReviewGroup.count
    
    set_admin
    new_review_group = { 'active'   => '1',
                         'cc_peers' => '1',
                         'name'     => 'Yankee' }

    post(:create, :new_review_group => new_review_group)

    group_count += 1
    assert_equal(group_count,    ReviewGroup.count)
    assert_equal("Yankee added", flash['notice'])
    assert_redirected_to(:action => 'list')

    post(:create, :new_review_group => new_review_group)
    assert_equal(group_count,                           ReviewGroup.count)
    assert_equal("Name already exists in the database", flash['notice'])
    assert_redirected_to(:action => 'add')

  end

end
