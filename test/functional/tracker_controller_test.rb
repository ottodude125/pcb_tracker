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
  def test index
    print '?'
    assert true
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
