########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: oi_instruction.rb
#
# This file maintains the state for oi_instructions.
#
# $Id$
#
########################################################################

class OiInstruction < ActiveRecord::Base

  belongs_to :design
  belongs_to :oi_category_section
  belongs_to :user
  
  has_many :oi_assignments


  ######################################################################
  #
  # assignment_count
  #
  # Description:
  # Returns the total number of assignments for the instruction.
  #
  # Parameters:
  # None
  #
  # Return value:
  # An integer representing the number of assignments for the
  # instruction.
  #
  ######################################################################
  #
  def assignment_count
    self.oi_assignments.size  
  end
  
  
  ######################################################################
  #
  # completed_assignment_count
  #
  # Description:
  # Returns the total number of completed assignments for the instruction.
  #
  # Parameters:
  # None
  #
  # Return value:
  # An integer representing the number of completed assignments for the
  # instruction.
  #
  ######################################################################
  #
  def completed_assignment_count
    total = 0
    #self.oi_assignments.each { |assignment| total += 1 if assignment.complete? }
    self.oi_assignments.each { |assignment| 
      total += 1 if assignment.complete ==OiAssignment.status_id("Completed") 
    }
    total
  end
  
  ######################################################################
  #
  # cancelled_assignment_count
  #
  # Description:
  # Returns the total number of cancelled assignments for the instruction.
  #
  # Parameters:
  # None
  #
  # Return value:
  # An integer representing the number of cancelled assignments for the
  # instruction.
  #
  ######################################################################
  #
  def cancelled_assignment_count
    total = 0
    self.oi_assignments.each { |assignment| 
      total += 1 if assignment.complete ==OiAssignment.status_id("Cancelled") 
    }
    total
  end
  
  
  ######################################################################
  #
  # report_card_count
  #
  # Description:
  # Returns the total number of completed report cards for the instruction.
  #
  # Parameters:
  # None
  #
  # Return value:
  # An integer representing the number of completed report cards for the
  # instruction.
  #
  ######################################################################
  #
  def report_card_count
    total = 0
    self.oi_assignments.each { |assignment| total += 1 if assignment.oi_assignment_report }
    total
  end
end
