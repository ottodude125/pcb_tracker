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

  has_many(:sections,     :order => :position)
  has_many :audits


  ######################################################################
  #
  # latest_release
  #
  # Description:
  # This method locates the most recently released checklist.
  #
  # Parameters:
  # None
  #
  # Return:
  # A checklist record.  If there are released checklists then the 
  # latest released checklist is returned.  Otherwise a new checklist
  # is returned.
  #
  ######################################################################
  #
  def self.latest_release
    
    checklist = Checklist.find(:first,
                               :conditions => "released=1",
                               :order      => 'major_rev_number DESC')

    return checklist ? checklist : Checklist.new

  end

  
  ######################################################################
  #
  # increment_checklist_counters
  #
  # Description:
  # This method is called to update the checklist counters when any
  # changes are made to a check or when a check is added or destroyed.
  #
  # Parameters:
  # checklist       - A list of checks that are being added or destroyed.
  # increment_value - Either 1 or -1 depending on whether the check(s) are
  #                   being added or destroyed.
  #
  ######################################################################
  #
  def increment_checklist_counters(checklist, increment)

    checklist = [checklist] if checklist.class == Check

    checklist.each do |check|

      if check.designer_auditor?
        self.designer_auditor_count    += increment if check.full_review?
        self.dc_designer_auditor_count += increment if check.date_code_check?
        self.dr_designer_auditor_count += increment if check.dot_rev_check?
      else
        self.designer_only_count       += increment if check.full_review?
        self.dc_designer_only_count    +=	increment if check.date_code_check?
        self.dr_designer_only_count    += increment if check.dot_rev_check?
      end

    end
    
    self.save

  end
  
  
  ######################################################################
  #
  # revision
  #
  # Description:
  # This method returns the revision of the checklist.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def revision
    self.major_rev_number.to_s + '.' + self.minor_rev_number.to_s
  end
  
  
  ######################################################################
  #
  # each_check
  #
  # Description:
  # This method iterates over all of the checks associates with this
  # checklist.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def each_check
    self.sections.each do |section|
      section.subsections.each do |subsection|
        subsection.checks.each { |check| yield check }
      end
    end
  end
  
  
  ######################################################################
  #
  # full_review_self_check_count
  #
  # Description:
  # Computes the number of self audit checks in a full review.
  #
  # Parameters:
  # None
  #
  # Return:
  # The number of self audit checks in a full review.
  #
  ######################################################################
  #
  def full_review_self_check_count
    check_count = 0
    self.sections.each do |s|
      next if !s.full_review?
      s.subsections.each do |ss|
        next if !ss.full_review?
        ss.checks.each { |c| check_count += 1 if c.new_design_check? && c.is_self_check? }
      end
    end
    check_count
  end

  
  ######################################################################
  #
  # full_review_peer_check_count
  #
  # Description:
  # Computes the number of peer audit checks in a full review.
  #
  # Parameters:
  # None
  #
  # Return:
  # The number of peer audit checks in a full review.
  #
  ######################################################################
  #
  def full_review_peer_check_count
    check_count = 0
    self.sections.each do |s|
      next if !s.full_review?
      s.subsections.each do |ss|
        next if !ss.full_review?
        ss.checks.each { |c| check_count += 1 if c.new_design_check? && c.is_peer_check? }
      end
    end
    check_count
  end

  
  ######################################################################
  #
  # partial_review_self_check_count
  #
  # Description:
  # Computes the number of self audit checks in a partial review.
  #
  # Parameters:
  # None
  #
  # Return:
  # The number of self audit checks in a partial review.
  #
  ######################################################################
  #
  def partial_review_self_check_count
    check_count = 0
    self.sections.each do |s|
      next if !s.dot_rev_check?
      s.subsections.each do |ss|
        next if !ss.dot_rev_check?
        ss.checks.each { |c| check_count += 1 if c.bare_board_design_check? && c.is_self_check? }
      end
    end
    check_count
  end
  
  
  ######################################################################
  #
  # partial_review_peer_check_count
  #
  # Description:
  # Computes the number of peer audit checks in a partial review.
  #
  # Parameters:
  # None
  #
  # Return:
  # The number of peer audit checks in a partial review.
  #
  ######################################################################
  #
  def partial_review_peer_check_count
    check_count = 0
    self.sections.each do |s|
      next if !s.dot_rev_check?
      s.subsections.each do |ss|
        next if !ss.dot_rev_check?
        ss.checks.each { |c| check_count += 1 if c.bare_board_design_check? && c.is_peer_check? }
      end
    end
    check_count
  end

  
  ######################################################################
  #
  # release
  #
  # Description:
  # This method sets the release field to indicate that the checklist
  # has been released.
  #
  # Parameters:
  # None
  #
  # Return:
  # A message indicating the result of the update.
  #
  ######################################################################
  #
  def release
    
    latest_release = Checklist.latest_release

    self.minor_rev_number = 0
    self.major_rev_number = latest_release.major_rev_number + 1
    self.released         = 1
    self.released_on      = ''

    if self.save
      return 'Checklist successfully released'
    else
      return 'Checklist release failed - Contact DTG.'
    end

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
    self.released?
  end


  # Remove the checklist and its associated sections, subsections, and checks.
  #
  # :call-seq:
  #   remove() -> boolean
  #
  # Go through the entire checklist to remove the sections, the remove self.
  def remove

   removed = true
   self.sections.each do |section|
     removed = section.remove
     break if !removed
   end

   return removed && self.destroy
    
  end


  # Calculate the number of each of new design and bareboard design checks for 
  # both the self and peer audits and store the results in the database.
  #
  # :call-seq:
  #   compute_check_counts() -> boolean
  #
  # Go through the entire checklist to calculate the number of self audit and 
  # peer audit checks for both new designs and bare board designs.  The results
  # are stored in the database.
  def compute_check_counts
    
    self.new_design_self_check_count       = 0
    self.new_design_peer_check_count       = 0
    self.bareboard_design_self_check_count = 0
    self.bareboard_design_peer_check_count = 0
    
    self.each_check do |check|
 
      if check.new_design_check?
        self.new_design_self_check_count += 1 if check.is_self_check?
        self.new_design_peer_check_count += 1 if check.is_peer_check?
      end
      
      if check.bare_board_design_check?
        self.bareboard_design_self_check_count += 1 if check.is_self_check?
        self.bareboard_design_peer_check_count += 1 if check.is_peer_check?
      end
      
    end
    
    self.save
    
  end
  
  
  # Report on the number of issues raised by the peer auditor in the checklist
  #
  # :call-seq:
  #   issue_count() -> integer
  #
  # The number of issues raised by the peer auditor in the checklist.
  def issue_count
    issue_count = 0
    self.sections.each { | section| issue_count += section.issue_count }
    issue_count
  end


end
