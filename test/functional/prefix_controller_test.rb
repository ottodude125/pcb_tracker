########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: prefix_controller_test.rb
#
# This file contains the functional tests for the board number prefix
# controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'prefix_controller'

# Re-raise errors caught by the controller.
class PrefixController; def rescue_action(e) raise e end; end

class PrefixControllerTest < Test::Unit::TestCase
  def setup
    @controller = PrefixController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  fixtures(:prefixes,
           :users)
  
  
  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the Prefix class
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

    # Try editing from a non-Admin account.
    # VERIFY: The user is redirected.
    set_non_admin
    post :list

    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    set_admin
    post(:list, :page => 1)

    assert_equal(7, assigns(:prefixes).size)

  end


end
