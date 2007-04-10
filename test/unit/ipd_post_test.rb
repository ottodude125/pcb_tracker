########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: ipd_post_test.rb
#
# This file contains the unit tests for the ipd post model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class IpdPostTest < Test::Unit::TestCase
  fixtures :ipd_posts

  # Replace this with your real tests.
  def test_truth
    assert_kind_of IpdPost, ipd_posts(:mx234a_thread_one)
  end
end
