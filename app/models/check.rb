########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: check.rb
#
# This file maintains the state for checks.
#
# $Id$
#
########################################################################

class Check < ActiveRecord::Base

  belongs_to(:subsection)
  acts_as_list(:scope => :subsection)

  has_one :design_check
  
  
  ######################################################################
  #
  # yes_no?
  #
  # Description:
  # This method looks at the check_type and returns TRUE if it is
  # set to 'yes_no'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the check is a 'Yes/No' check, FALSE otherwise.
  #
  ######################################################################
  #
  def yes_no?
    self.check_type == 'yes_no'
  end
  
  
  ######################################################################
  #
  # designer_only?
  #
  # Description:
  # This method looks at the check_type and returns TRUE if it is
  # set to 'designer_only'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the check is a 'designer_only' check, FALSE otherwise.
  #
  ######################################################################
  #
  def designer_only?
    self.check_type == 'designer_only'
  end
  
  
  ######################################################################
  #
  # designer_auditor?
  #
  # Description:
  # This method looks at the check_type and returns TRUE if it is
  # set to 'designer_auditor'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the check is a 'designer_auditor' check, FALSE otherwise.
  #
  ######################################################################
  #
  def designer_auditor?
    self.check_type == 'designer_auditor'
  end
  
  
  ######################################################################
  #
  # belongs_to?
  #
  # Description:
  # This method determines if a check should be included in a design's
  # audit checks.
  #
  # Parameters:
  # design - a design record.
  #
  # Return value:
  # TRUE if the check belongs, FALSE otherwise.
  #
  ######################################################################
  #
  def belongs_to?(design)
    design.new?                                  ||
    (design.date_code? && self.date_code_check?) ||
    (design.dot_rev?   && self.dot_rev_check?)
  end
  
  
  ######################################################################
  #
  # insert
  #
  # Description:
  # Inserts the object into the subsections list of checks.
  #
  # Parameters:
  # subsection_id - the subsection identifier
  # position      - The position in the list that the check is to be inserted at.
  #
  # Return value:
  # self.errors - if the check could not be stored in the database then
  #               this structure will contain errors.
  #
  ######################################################################
  #
  def insert(subsection_id, position)

    subsection = Subsection.find(subsection_id)

    self.subsection_id = subsection_id
    self.create
    
    if self.errors.empty?
      subsection.checks.last.insert_at(position)
      subsection.section.checklist.increment_checklist_counters(self, 1)
    end

  end


  ######################################################################
  #
  # remove
  #
  # Description:
  # Removed the object into the subsections list of checks and updates
  # the checklist counters..
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the object was successfully remove, otherwise FALSE
  #
  ######################################################################
  #
  def remove

    self.checklist.increment_checklist_counters(self, -1)
    self.destroy

  end


  ######################################################################
  #
  # locked?
  #
  # Description:
  # Reports whether or not the object is available for modification and
  # deletion.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the object can not be deleted or modified, otherwise FALSE.
  #
  ######################################################################
  #
  def locked?
    self.subsection.locked?
  end


  ######################################################################
  #
  # section
  #
  # Description:
  # This provides a short cut to access the parent (section) of the
  # check's parent (subsection).
  #
  # Parameters:
  # None
  #
  # Return value:
  # The section record if it exists.  Otherwise nil is returned
  #
  ######################################################################
  #
  def section
    self.subsection.section if (self.subsection && self.subsection.section)
  end
  
  
  ######################################################################
  #
  # checklist
  #
  # Description:
  # This provides a short cut to access the parent (checklist) of the 
  # parent (section) of the check's parent (subsection).
  #
  # Parameters:
  # None
  #
  # Return value:
  # The checklist record if it exists.  Otherwise nil is returned
  #
  ######################################################################
  #
  def checklist
    self.section.checklist if (self.section && self.section.checklist)
  end
  
  
end
