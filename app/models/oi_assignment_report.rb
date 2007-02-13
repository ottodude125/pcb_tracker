########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: oi_assignment_report.rb
#
# This file maintains the state for oi_assignment_reports.
#
# $Id$
#
########################################################################

class OiAssignmentReport < ActiveRecord::Base

  belongs_to :oi_assignment
  belongs_to :user


#
# Constants
# 
REPORT_CARD_SCORING_TABLE = [ [ 5,  '0% Rework' ],
                              [ 4, 'Approximately 20% Rework' ],
                              [ 3, 'Approximately 40% Rework' ],
                              [ 2, 'Approximately 60% Rework' ],
                              [ 1, 'Approximately 80% Rework' ],
                              [ 0, '100% Rework'] ]
                              
                              
  ######################################################################
  #
  # report_card_scoring
  #
  # Description:
  # This method returns the REPORT_CARD_SCORING_TABLE.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def OiAssignmentReport.report_card_scoring
    REPORT_CARD_SCORING_TABLE
  end


  ######################################################################
  #
  # min_score
  #
  # Description:
  # This method returns minimum score in the REPORT_CARD_SCORING_TABLE.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def OiAssignmentReport.min_score
    REPORT_CARD_SCORING_TABLE.collect { |score| score[0] }.min
  end


  ######################################################################
  #
  # max_score
  #
  # Description:
  # This method returns maximum score in the REPORT_CARD_SCORING_TABLE.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def OiAssignmentReport.max_score
    REPORT_CARD_SCORING_TABLE.collect { |score| score[0] }.max
  end


end
