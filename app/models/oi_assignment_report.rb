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
REPORT_CARD_SCORING_TABLE = [ [ 5,  '0% to 10% Rework'  ],
                              [ 4, '11% to 33% Rework'  ],
                              [ 3, '34% to 63% Rework'  ],
                              [ 2, '64% to 89% Rework'  ],
                              [ 1, '90% to 100% Rework' ] ]
                              
                              
  ######################################################################
  #
  # report_card_scoring
  #
  # Description:
  # This method returns the REPORT_CARD_SCORING_TABLEk.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
def OiAssignmentReport.report_card_scoring
  REPORT_CARD_SCORING_TABLE
end


end
