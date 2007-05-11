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
NOT_SCORED = 256

REPORT_CARD_SCORING_TABLE = [ [   0, '0% Rework' ],
                              [  20, 'Approximately 20% Rework' ],
                              [  40, 'Approximately 40% Rework' ],
                              [  60, 'Approximately 60% Rework' ],
                              [  80, 'Approximately 80% Rework' ],
                              [ 100, '100% Rework'] ]
                              
                              
  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


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
  
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################


  ######################################################################
  #
  # score_value
  #
  # Description:
  # This method returns the textual value for the score.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def score_value
    REPORT_CARD_SCORING_TABLE[self.score/20][1]
  end


end
