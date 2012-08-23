########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: revision_test.rb
#
# This file contains the unit tests for the revision model
#
# Revision History:
#   $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ ) 

class RevisionsTest < ActiveSupport::TestCase


  def setup
    @revisions = [ revisions(:rev_a),   revisions(:rev_b),
                   revisions(:rev_c),   revisions(:rev_d),
                   revisions(:rev_e),   revisions(:rev_f),
                   revisions(:rev_g) ]
  end

  ######################################################################
  def test_get
  
    revision_list = Revision.get_revisions
    
    assert_equal(@revisions, revision_list)
    
    revision_list.each_with_index do |rev, i|
      assert_equal(@revisions[i], rev)
    end
    
  end
  
  
end
