########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: admin_controller_test.rb
#
# This file contains the functional tests for the admin_controller
#
# $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'
require 'admin_controller'

# Re-raise errors caught by the controller.
class AdminController; def rescue_action(e) raise e end; end

class AdminControllerTest < Test::Unit::TestCase
  def setup
    @controller = AdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end


  def test_1_id
    print("\n*** Admin Controller Test\n")
    print("*** $Id$\n")
  end


  ######################################################################
  #
  # test_index
  #
  # Description:
  # This method does the functional testing of the index method
  # from the AdminController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: JPA - finish
  #
  ######################################################################
  #
  def test_index
    assert_response 0
  end
end
