########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: audit_teammates_test.rb
#
# This file contains the unit tests for the audit teammates model
#
# Revision History:
#   $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ ) 

class AuditTeammatesTest < ActiveSupport::TestCase

  def setup
  
    @audit_mx234b        = audits(:audit_mx234b)

    @bob_g   = users(:bob_g)
    @rich_m  = users(:rich_m)
    @scott_g = users(:scott_g)
    @siva_e  = users(:siva_e)
    @cathy_m = users(:cathy_m)

  end


  #############################################################################
  def test_add
    
    audit_mx234b_teammates = @audit_mx234b.audit_teammates
    audit_teammate_count = audit_mx234b_teammates.size
    
    audit_teammate = AuditTeammate.new_teammate(@audit_mx234b.id,
                                                4000, 
                                                @scott_g.id, 
                                                :self,
                                                false)
                             
    @audit_mx234b.reload
    assert_equal(audit_teammate_count, audit_mx234b_teammates.size)
    assert_equal(@audit_mx234b,        audit_teammate.audit)
    assert_equal(@scott_g.name,        audit_teammate.user.name)
    assert_equal(4000,                 audit_teammate.section_id)
    assert(audit_teammate.self?)
    
    audit_teammate = AuditTeammate.new_teammate(@audit_mx234b.id,
                                                4000, 
                                                @rich_m.id, 
                                                :peer)
                             
    @audit_mx234b.reload
    assert_equal(audit_teammate_count + 1, audit_mx234b_teammates.size)
    assert_equal(@audit_mx234b,            audit_teammate.audit)
    assert_equal(@rich_m.name,             audit_teammate.user.name)
    assert_equal(4000,                     audit_teammate.section_id)
    assert(!audit_teammate.self?)
    assert_equal(audit_teammate, audit_mx234b_teammates.pop)
    
  end
  
end
