########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: section.rb
#
# This file maintains the state for sections.
#
# $Id$
#
########################################################################

class Section < ActiveRecord::Base

  belongs_to :checklist
  
  has_many   :audit_teammates
  has_many   :checks
  has_many(:subsections,         :order => 'sort_order ASC')  


  ######################################################################
  #
  # designer_auditor_checks
  #
  # Description:
  # This method returns the number of designer/auditor checks.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def designer_auditor_checks
    
    total = 0
    
    for subsection in self.subsections
      total += subsection.designer_auditor_checks
    end
    
    total
    
  end
end
