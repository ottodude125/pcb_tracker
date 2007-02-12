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

require File.dirname(__FILE__) + '/../test_helper'

class OiAssignmentReportTest < Test::Unit::TestCase
  fixtures :oi_assignment_reports

  ######################################################################
  def test_report_card_scoring
  
    expected_scores = [[5, "0% Rework"],
                       [4, "Approximately 20% Rework"],
                       [3, "Approximately 40% Rework"],
                       [2, "Approximately 60% Rework"],
                       [1, "Approximately 80% Rework"],
                       [0, "100% Rework"]]
    report_card_scores = OiAssignmentReport.report_card_scoring
    
    assert_equal(expected_scores, report_card_scores)

  end


  ######################################################################
  def test_min_and_max_score

    assert_equal(0, OiAssignmentReport.min_score)
    assert_equal(5, OiAssignmentReport.max_score)

  end

  
end
