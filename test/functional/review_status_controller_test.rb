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
require File.expand_path( "../../test_helper", __FILE__ )
require 'review_status_controller'

# Re-raise errors caught by the controller.
class ReviewStatusController; def rescue_action(e) raise e end; end

class ReviewStatusControllerTest < ActionController::TestCase
  
  def setup
    @controller = ReviewStatusController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:review_statuses,
           :users)

  #self.use_transactional_fixtures = false
  #self.use_instantiated_fixtures  = true
  
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
    get :list, {}, rich_designer_session
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal('Administrators only!  Check your role.', flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    get(:list, { :page => 1 }, cathy_admin_session)
    assert_equal(ReviewStatus.count, assigns(:review_statuses).count )
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
    review_complete = review_statuses(:review_complete)
    get(:edit, { :id => review_complete.id }, cathy_admin_session)
    assert_equal(review_complete.name, assigns(:review_status).name)
    
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

    review_status      = ReviewStatus.find(review_statuses(:in_review).id)
    review_status.name = 'Test'

    get(:update,
        { :review_status => review_status.attributes },
        cathy_admin_session)
    assert_equal('Update recorded', flash['notice'])
    assert_redirected_to(:action => 'edit', :id => review_status.id)
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

    admin_session = cathy_admin_session
    new_review_status = { 'active' => '1', 'name' => 'Yankee' }

    post(:create, { :new_review_status => new_review_status }, admin_session)
    status_count += 1
    assert_equal(status_count,   ReviewStatus.count)
    assert_equal("Yankee added", flash['notice'])
    assert_redirected_to :action => 'list'

    post(:create, { :new_review_status => new_review_status }, admin_session)
    assert_equal(status_count,                          ReviewStatus.count)
    #assert_equal("Name already exists in the database", flash['notice'])
    assert_redirected_to :action => 'add'

  end

end
