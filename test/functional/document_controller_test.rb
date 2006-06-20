########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: document_controller_test.rb
#
# This file contains the functional tests for the document controller
#
# $Id$
#
########################################################################
#

require File.dirname(__FILE__) + '/../test_helper'
require 'document_controller'

# Re-raise errors caught by the controller.
class DocumentController; def rescue_action(e) raise e end; end

class DocumentControllerTest < Test::Unit::TestCase
  def setup
    @controller = DocumentController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end


  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
