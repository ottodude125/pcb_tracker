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

  belongs_to(:checklist)
  acts_as_list(:scope => :checklist)
  
  has_many(:audit_teammates)

  has_many(:subsections, :order => :position)  


  ######################################################################
  #
  # designer_auditor_check_count
  #
  # Description:
  # This method returns the number of designer/auditor checks.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def designer_auditor_check_count
    
    total = 0
    self.subsections.each { |ss| total += ss.designer_auditor_check_count }
    
    total
    
  end
  
  
  ######################################################################
  #
  # insert
  #
  # Description:
  # Inserts the object into the checklist's list of sections.
  #
  # Parameters:
  # checklist_id - the checklist identifier
  # position     - The position in the list that the section is to be 
  #                inserted at.
  #
  # Return value:
  # self.errors - if the checklist could not be stored in the database then
  #               this structure will contain errors.
  #
  ######################################################################
  #
  def insert(checklist_id, position)

    self.checklist_id = checklist_id
    self.save
    
    self.checklist.sections.last.insert_at(position) if self.errors.empty?

  end


  ######################################################################
  #
  # remove
  #
  # Description:
  # Removes the section and all of its children (subsections).
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the section and all of its subsections were removed, FALSE
  # otherwise.
  #
  ######################################################################
  #
  def remove

   removed = true
   self.subsections.each do |subsection|
     removed = subsection.remove
     break if !removed
   end

   return removed && self.destroy
    
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
    self.checklist.locked?
  end


  # Report on the number of checks contained in the section.
  #
  # :call-seq:
  #   check_count() -> integer
  #
  # The number of checks contained in the section.
  def check_count
    check_count = 0
    self.subsections.each { |subsection| check_count += subsection.check_count}
    check_count
  end
  
  
  # Report on the number of issues raised by the peer auditor in the section
  #
  # :call-seq:
  #   issue_count() -> integer
  #
  # The number of issues raised by the peer auditor in the section.
  def issue_count
    issue_count = 0
    self.subsections.each { | subsection| issue_count += subsection.issue_count }
    issue_count
  end


end
