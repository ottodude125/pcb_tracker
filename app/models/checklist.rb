########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: checklist.rb
#
# This file maintains the state for checklists.
#
# $Id$
#
########################################################################

class Checklist < ActiveRecord::Base

  has_many(:sections,     :order => 'sort_order ASC')
  has_many :subsections
  has_many :audits


  ######################################################################
  #
  # increment_checklist_counters
  #
  # Description:
  # This method is called to update the checklist counters when any
  # changes are made to a check or when a check is added or destroyed.
  #
  # Parameters:
  # new_check       - The check that is being added or destroyed.
  # increment_value - Either 1 or -1 depending on whether a check is 
  #                   being added or destroyed.
  #
  ######################################################################
  #
  def increment_checklist_counters(check, increment)

    if check.designer_auditor?
      self.designer_auditor_count    += increment if check.full_review?
      self.dc_designer_auditor_count += increment if check.date_code_check?
      self.dr_designer_auditor_count += increment if check.dot_rev_check?
    else
      self.designer_only_count       += increment if check.full_review?
      self.dc_designer_only_count    +=	increment if check.date_code_check?
      self.dr_designer_only_count    += increment if check.dot_rev_check?
    end

    self.update

  end


end
