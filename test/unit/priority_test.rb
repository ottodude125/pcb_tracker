########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: priority_test.rb
#
# This file contains the unit tests for the priority model
#
# Revision History:
#   $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ ) 

class PrioritysTest < ActiveSupport::TestCase


  def setup
    @high   = priorities(:high)
    @medium = priorities(:medium)
    @low    = priorities(:low)
  end
  

  ######################################################################
  def test_get
    
    expected = [ @high, @medium, @low ]
    
    Priority.get_priorities.each_with_index do |priority, i|
      assert_equal(expected[i], priority)
    end
    
  end
  
end
