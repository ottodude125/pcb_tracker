########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: review_status_controller_test.rb
#
# This file contains the functional tests for the review status controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'review_status_controller'

# Re-raise errors caught by the controller.
class ReviewStatusController; def rescue_action(e) raise e end; end

class ReviewStatusControllerTest < Test::Unit::TestCase
  def setup
    @controller = ReviewStatusController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:review_statuses,
           :users)

  self.use_transactional_fixtures = false
  self.use_instantiated_fixtures  = true
  
  
  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the ReviewStatus class
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

    assert_equal(6, @review_statuses.size)
  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the edit method
  # from the ReviewStatus class
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
    get(:edit,
        :id => @review_complete.id)

    assert_equal(@review_complete.name,
                 assigns(:review_status).name)
    
  end

  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update method
  # from the ReviewStatus Controller class
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
    review_status      = ReviewStatus.find(review_statuses(:in_review).id)
    review_status.name = 'Test'

    get(:update,
        :review_status => review_status.attributes)

    assert_equal('Update recorded', flash['notice'])
    assert_redirected_to(:action => 'edit',
                         :id     => review_status.id)
    assert_equal('Test', review_status.name)
  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the ReviewStatus Controller class
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

    status_count = ReviewStatus.count

    set_admin
    new_review_status = { 'active' => '1',
                          'name'   => 'Yankee' }

    post(:create, :new_review_status => new_review_status)

    status_count += 1
    assert_equal(status_count,   ReviewStatus.count)
    assert_equal("Yankee added", flash['notice'])
    assert_redirected_to :action => 'list'

    post(:create, :new_review_status => new_review_status)
    assert_equal(status_count,                          ReviewStatus.count)
    assert_equal("Name already exists in the database", flash['notice'])
    assert_redirected_to :action => 'add'

  end

end
