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

require File.expand_path( "../../test_helper", __FILE__ )
require 'admin_controller'

# Re-raise errors caught by the controller.
class AdminController; def rescue_action(e) raise e end; end

class AdminControllerTest < ActionController::TestCase
  def setup
    @controller = AdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end


  ######################################################################
  #
  # test_index
  #
  # Description:
  # This method does the functional testing of the index method
  # from the AdminController class
  #
  ######################################################################
  #
  def test_index
    assert_response 200
  end
end
