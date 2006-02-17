########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: tracker_controller_test.rb
#
# This file contains the functional tests for the tracker controller
#
# $Id$
#
########################################################################
#

require File.dirname(__FILE__) + '/../test_helper'
require 'tracker_controller'

# Re-raise errors caught by the controller.
class TrackerController; def rescue_action(e) raise e end; end

class TrackerControllerTest < Test::Unit::TestCase
  def setup
    @controller = TrackerController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end


  fixtures(:users)


  def test_1_id
    print ("\n*** Tracker Controller Test - NEEDS WORK!!!\n")
    print ("*** $Id$\n")
  end


  ######################################################################
  #
  # test_manager_home
  #
  # Description:
  # This method does the functional testing for the manager methods
  #
  ######################################################################
  #
  def test_manager_home
    print '?'
    assert true
  end
  
  
  ######################################################################
  #
  # test_index
  #
  # Description:
  # This method does the functional testing for the index method.
  #
  ######################################################################
  #
  def test_index

    # First verify the screen when not logged in.
    get :index
    assert_response 200
    assert_template 'tracker/index'

    set_admin()
    get :index
    assert_response 302
    assert_redirected_to :action => :admin_home

    set_designer()
    get :index
    assert_response 302
    assert_redirected_to :action => :designer_home

    set_manager()
    get :index
    assert_response 302
    assert_redirected_to :action => :manager_home

    set_reviewer()
    get :index
    assert_response 302
    assert_redirected_to :action => :reviewer_home

    
  end
  
  
  ######################################################################
  #
  # test_designer_home
  #
  # Description:
  # This method does the functional testing for the designer methods
  #
  ######################################################################
  #
  def test_designer_home
    print '?'
    assert true
  end
  

  ######################################################################
  #
  # test_reviewer_home
  #
  # Description:
  # This method does the functional testing for the reviewer methods
  #
  ######################################################################
  #
  def test_reviewer_home
    print '?'
    assert true
  end
  
  
  ######################################################################
  #
  # test_admin_home
  #
  # Description:
  # This method does the functional testing for the admin methods
  #
  ######################################################################
  #
  def test_admin_home
    print '?'
    assert true
  end
  
  
  ######################################################################
  #
  # test_get_design_reviews
  #
  # Description:
  # This method does the functional testing for the get_design_review
  # method
  #
  ######################################################################
  #
  def test_get_design_reviews
    print '?'
    assert true
  end
  
end
