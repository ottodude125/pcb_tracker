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

  belongs_to(:section)
  acts_as_list(:scope => :section)
  
  has_many(:checks, :order => :position)
  
  
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
    self.checks.each { |check| total += 1 if check.designer_auditor? }
    
    total
    
  end


  ######################################################################
  #
  # insert
  #
  # Description:
  # Inserts the object into the section's list of subsections.
  #
  # Parameters:
  # section_id - the section identifier
  # position   - The position in the list that the check is to be inserted at.
  #
  # Return value:
  # self.errors - if the subsection could not be stored in the database then
  #               this structure will contain errors.
  #
  ######################################################################
  #
  def insert(section_id, position)

    section = Section.find(section_id)

    self.section_id   = section_id
    self.create
    
    if self.errors.empty?
      section.subsections.last.insert_at(position)
    end

  end


  ######################################################################
  #
  # remove
  #
  # Description:
  # Removes the subsection and all of its children (checks).
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the subsection and all of its checks were removed, FALSE
  # otherwise.
  #
  ######################################################################
  #
  def remove
    
     self.checklist.increment_checklist_counters(self.checks, -1)
     Check.destroy_all("subsection_id=#{self.id}")
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

    self.section.locked?

  end


  ######################################################################
  #
  # checklist
  #
  # Description:
  # This provides a short cut to access the parent (checklist) of the 
  # check's parent (section).
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
