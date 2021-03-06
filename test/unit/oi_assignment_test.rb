########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: oi_assignment_test.rb
#
# This file contains the unit tests for the outsource instruction
# assignment model
#
# Revision History:
#   $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ ) 

class OiAssignmentsTest < ActiveSupport::TestCase

  def setup
    @first_assignment = oi_assignments(:first)
    @second_assignment = oi_assignments(:second)  
  end

  ######################################################################
  def test_complexity_list
  
    expected_complexity_list = [ ['High', 1], ['Medium', 2], ['Low', 3] ]
    assert_equal(expected_complexity_list, OiAssignment.complexity_list)
    
  end


  ######################################################################
  def test_complexity_name
  
    assert_equal('High',      OiAssignment.complexity_name(1))
    assert_equal('Medium',    OiAssignment.complexity_name(2))
    assert_equal('Low',       OiAssignment.complexity_name(3))
    assert_equal('Undefined', OiAssignment.complexity_name(33))
    
  end


  ######################################################################
  def test_complexity_id
  
    assert_equal(1, OiAssignment.complexity_id('High'))
    assert_equal(2, OiAssignment.complexity_id('Medium'))
    assert_equal(3, OiAssignment.complexity_id('Low'))
    assert_equal(0, OiAssignment.complexity_id('Zero Expected'))
    
  end


  ######################################################################
  def test_complexity_name_instance
  
    assert_equal('High',   @first_assignment.complexity_name)
    assert_equal('Medium', @second_assignment.complexity_name)
    
  end


  ######################################################################
  def test_task_duration
  
    assert_equal('0',    @first_assignment.task_duration)
    assert_equal('21.2', @second_assignment.task_duration)
    
  end


  ######################################################################
  def test_task_email_update_header
  
    date_assigned = Time.utc(2007, 'feb', 15, 13, 16).format_dd_mon_yy('timestamp')
    assert_equal("------------------------------------------------------------------------\n" +
                 "         Design : pcb252_234_a0_g\n"                                        +
                 "       Category : Placement\n"                                              +
                 "           Step : Place components per instructions\n"                      +
                 "      Team Lead : Scott Glover\n"                                           +
                 "       Designer : Siva Esakky\n"                                            +
                 "  Date Assigned : #{date_assigned}\n"                                       +
                 "       Complete : No\n"                                                     +
                 "------------------------------------------------------------------------\n",
                 @first_assignment.email_update_header)
 
    date_assigned  = Time.utc(2007, 'feb', 16, 11, 20).format_dd_mon_yy('timestamp')
    date_completed = Time.utc(2007, 'mar',  9, 16, 45).format_dd_mon_yy('timestamp')
    assert_equal("------------------------------------------------------------------------\n" +
                 "         Design : pcb252_234_a0_g\n"                                        +
                 "       Category : Placement\n"                                              +
                 "           Step : Place components per instructions\n"                      +
                 "      Team Lead : Scott Glover\n"                                           +
                 "       Designer : Mathi Nagarajan\n"                                        +
                 "  Date Assigned : #{date_assigned}\n"                                       +
                 "       Complete : Yes\n"                                                    +
                 "   Completed On : #{date_completed}\n"                                      +
                 "------------------------------------------------------------------------\n",
                 @second_assignment.email_update_header)
    
  end


end
