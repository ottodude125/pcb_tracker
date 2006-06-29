########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: subsection.rb
#
# This file maintains the state for subsections.
#
# $Id$
#
########################################################################

class Subsection < ActiveRecord::Base

  belongs_to :checklist
  belongs_to :section
  
  has_many(:checks,     :order => 'sort_order ASC')
  
  
  ######################################################################
  #
  # designer_auditor_checks
  #
  # Description:
  # This method returns the number of checks in the subsection.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def designer_auditor_checks
    
    total = 0
    
    for check in self.checks
      total += 1 if check.check_type == 'designer_auditor'
    end
    
    total
    
  end

end
