########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: oi_assignment_report_test.rb
#
# This file contains the unit tests for the oi_assignment report model
#
# Revision History:
#   $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ ) 

class OiAssignmentReportsTest < ActiveSupport::TestCase

  ######################################################################
  def test_report_card_scoring
  
    expected_scores = [[0,   "0% Rework"],
                       [20,  "Approximately 20% Rework"],
                       [40,  "Approximately 40% Rework"],
                       [60,  "Approximately 60% Rework"],
                       [80,  "Approximately 80% Rework"],
                       [100, "100% Rework"]]
    report_card_scores = OiAssignmentReport.report_card_scoring
    
    assert_equal(expected_scores, report_card_scores)

  end


  ######################################################################
  def test_min_and_max_score

    assert_equal(0,   OiAssignmentReport.min_score)
    assert_equal(100, OiAssignmentReport.max_score)

  end
  
  
  ######################################################################
  def test_score_value
  
    assignment_report = OiAssignmentReport.new
    
    assignment_report.score = 0
    assert_equal("0% Rework", assignment_report.score_value)
    assignment_report.score = 20
    assert_equal("Approximately 20% Rework", assignment_report.score_value)
    assignment_report.score = 40
    assert_equal("Approximately 40% Rework", assignment_report.score_value)
    assignment_report.score = 60
    assert_equal("Approximately 60% Rework", assignment_report.score_value)
    assignment_report.score = 80
    assert_equal("Approximately 80% Rework", assignment_report.score_value)
    assignment_report.score = 100
    assert_equal("100% Rework", assignment_report.score_value)

  
  end

  
end
