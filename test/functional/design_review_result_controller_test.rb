########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_review_result_controller_test.rb
#
# This file contains the functional tests for the design review
# result controller
#
# $Id$
#
########################################################################
#

require File.dirname(__FILE__) + '/../test_helper'
require 'design_review_result_controller'

# Re-raise errors caught by the controller.
class DesignReviewResultController; def rescue_action(e) raise e end; end

class DesignReviewResultControllerTest < Test::Unit::TestCase
  def setup
    @controller = DesignReviewResultController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_1_id
    print("\n*** Design Review Result Controller Test - NEEDS WORK!!!\n")
    print("*** $Id$\n")
  end


  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
