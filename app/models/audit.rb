########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: audit.rb
#
# This file maintains the state for audits.
#
# $Id$
#
########################################################################

class Audit < ActiveRecord::Base

  belongs_to :checklist
  belongs_to :design
  belongs_to :revision

  has_many :audit_teammates
  has_many :design_checks


#
# Constants
# 
AUDIT_COMPLETE   = 0
SELF_AUDIT       = 1
PEER_AUDIT       = 2


  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


  ######################################################################
  #
  # find_incomplete_audits
  #
  # Description:
  # This method retrieves all of the audits that are not complete
  # and returns them in a list.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of incomplete audits
  #
  ######################################################################
  #
  def self.find_incomplete_audits
    self.find(:all,
              :conditions => "auditor_complete=0",
              :order      => "id")
  end
  
  
  ######################################################################
  #
  # active_audits
  #
  # Description:
  # This method retrieves a list of all the user's active audits
  #
  # Parameters:
  # user - a user record for the current user.
  #
  # Return value:
  # A list of active audits
  #
  ######################################################################
  #
  def self.active_audits(user)
  
    audits = self.find_incomplete_audits
    
    audits.delete_if do |a|
      if a.is_self_audit?
        !(a.audit_teammates.detect { |at|  at.user_id == user.id } || 
          a.design.peer == user)
      else
        !(a.audit_teammates.detect { |at| at.user_id == user.id && !at.self? } ||
          a.design.peer == user)
      end
    end
    
    audits.sort_by { |a| a.design.priority.value }
  
  end
  
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################

  
  ######################################################################
  #
  # audit_state
  #
  # Description:
  # This method reports that the audit is a self audit, a peer audit, or
  # is complete.
  #
  # Parameters:
  # None
  #
  # Return value:
  # SELF_AUDIT if the audit has not completed the self audit, 
  # PEER_AUDIT if the audit is in peer audit, or
  # AUDIT_COMPLETE if both the self and peer audits are complete.
  #
  ######################################################################
  #
  def audit_state
  
    return SELF_AUDIT     unless self.designer_complete?
    return PEER_AUDIT     unless self.auditor_complete?
    return AUDIT_COMPLETE

  end
  
  
  ######################################################################
  #
  # is_self_audit?
  #
  # Description:
  # This method determines if the audit is a self audit.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the audit is in the SELF_AUDIT state, FALSE otherwise.
  #
  ######################################################################
  #
  def is_self_audit?
    self.audit_state == SELF_AUDIT
  end
  
  
  ######################################################################
  #
  # is_peer_audit?
  #
  # Description:
  # This method determines if the audit is a peer audit.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the audit is in the PEER_AUDIT state, FALSE otherwise.
  #
  ######################################################################
  #
  def is_peer_audit?
    self.audit_state == PEER_AUDIT
  end
  
  
  ######################################################################
  #
  # is_complete?
  #
  # Description:
  # This method determines if the audit is complete.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the audit is in the AUDIT_COMPLETE state, FALSE otherwise.
  #
  ######################################################################
  #
  def is_complete?
    self.audit_state == AUDIT_COMPLETE
  end
  
  
  ######################################################################
  #
  # is_self_auditor?
  #
  # Description:
  # This method determines if the user is a self auditor.
  #
  # Parameters:
  # user - A User record for the person this method is checking to
  #        if the person is on the self audit team.
  #
  # Return value:
  # TRUE if the user is on the self audit team, FALSE otherwise.
  #
  ######################################################################
  #
  def is_self_auditor?(user)
    self.design.designer_id == user.id ||
    self.audit_teammates.detect { |teammate| teammate.user_id == user.id && teammate.self? }
  end


  ######################################################################
  #
  # is_peer_auditor?
  #
  # Description:
  # This method determines if the user is a peer auditor.
  #
  # Parameters:
  # user - A User record for the person this method is checking to
  #        if the person is on the peer audit team.
  #
  # Return value:
  # TRUE if the user is on the peer audit team, FALSE otherwise.
  #
  ######################################################################
  #
  def is_peer_auditor?(user)
    self.design.peer_id == user.id ||
    self.audit_teammates.detect { |t| t.user_id == user.id && !t.self? }
  end
  
  
  ######################################################################
  #
  # create_checklist
  #
  # Description:
  # This method creates a new checklist at the kick off of a 
  # Peer Audit Revew.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def create_checklist

    design    = self.design
    checklist = self.checklist

    checklist.sections.each do |section|
      section.subsections.each do |subsection|
        subsection.checks.each do |check|
          if ((design.new?)                                 ||
              (design.date_code? && check.date_code_check?) ||
              (design.dot_rev?   && check.dot_rev_check?))
            design_check = DesignCheck.new(:audit_id => self.id, :check_id => check.id)

            fail 'Design check not saved' unless design_check.save
          end
        end
      end
    end
    
  end
  
  
  ######################################################################
  #
  # check_count
  #
  # Description:
  # This method returns the number of checks for the designer and the
  # peer based on the design type.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def check_count

    count     = {}
    checklist = self.checklist

    case self.design.design_type
    when 'New'
      count[:designer] = checklist.designer_only_count +
                           checklist.designer_auditor_count
      count[:peer]     = checklist.designer_auditor_count
    when 'Date Code'
      count[:designer] = checklist.dc_designer_only_count +
                           checklist.dc_designer_auditor_count
      count[:peer]     = checklist.dc_designer_auditor_count
    when 'Dot Rev'
      count[:designer] = checklist.dr_designer_only_count +
                           checklist.dr_designer_auditor_count
      count[:peer]     = checklist.dr_designer_auditor_count
    end

    return count
    
  end
  
  
  ######################################################################
  #
  # peer_check_count
  #
  # Description:
  # This method returns the number of checks for the peer audit team
  # based on the design type.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def peer_check_count
  
    checklist = self.checklist

    case self.design.design_type
    when 'New'
      checklist.designer_auditor_count
    when 'Date Code'
      checklist.dc_designer_auditor_count
    when 'Dot Rev'
      checklist.dr_designer_auditor_count
    end

  end
  
  
  ######################################################################
  #
  # peer_percent_complete
  #
  # Description:
  # This method returns percent complete statistics for the 
  # peer audit team.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def peer_percent_complete
    self.auditor_completed_checks * 100.0 / self.peer_check_count
  end
  
  
  ######################################################################
  #
  # self_check_count
  #
  # Description:
  # This method returns the number of checks for the self audit team
  # based on the design type.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def self_check_count
  
    checklist = self.checklist

    case self.design.design_type
    when 'New'
      checklist.designer_only_count + checklist.designer_auditor_count
    when 'Date Code'
      checklist.dc_designer_only_count + checklist.dc_designer_auditor_count
    when 'Dot Rev'
      checklist.dr_designer_only_count + checklist.dr_designer_auditor_count
    end

  end
  
  
  ######################################################################
  #
  # self_percent_complete
  #
  # Description:
  # This method returns percent complete statistics for the 
  # self audit team.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def self_percent_complete
    self.designer_completed_checks * 100.0 / self.self_check_count
  end
  
  
  ######################################################################
  #
  # completion_stats
  #
  # Description:
  # This method returns percent complete statistics for the 
  # self and peer audit.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def completion_stats
  
    stats = { :self => 0.0, :peer => 0.0 }
    total_checks = self.check_count
    
    stats[:self] = self.designer_completed_checks * 100.0 / total_checks[:designer]
    stats[:peer] = self.auditor_completed_checks  * 100.0 / total_checks[:peer]

    stats
  
  end
  
  
  ######################################################################
  #
  # completed_self_audit_check_count
  #
  # Description:
  # This method provides the number of self audit design checks that
  # have been completed for the subsection.
  #
  # Parameters:
  # subsection - the subsection record that is used to group the design
  #              checks.
  #
  ######################################################################
  #
  def completed_self_audit_check_count(subsection)

    design_checks = []
    self.design_checks.each { |dc| design_checks << dc if dc.self_auditor_checked? }
    design_checks.delete_if { |dc| !subsection.checks.include?(dc.check) }

    design_checks.size

  end
  
  ######################################################################
  #
  # completed_peer_audit_check_count
  #
  # Description:
  # This method provides the number of peer audit design checks that
  # have been completed for the subsection.
  #
  # Parameters:
  # subsection - the subsection record that is used to group the design
  #              checks.
  #
  ######################################################################
  #
  def completed_peer_audit_check_count(subsection)

    design_checks = []
    self.design_checks.each { |dc| design_checks << dc if dc.peer_auditor_checked? }
    design_checks.delete_if { |dc| !subsection.checks.include?(dc.check) }

    design_checks.size

  end
  
  
  ######################################################################
  #
  # get_section_teammate
  #
  # Description:
  # Retrieves the teammate for the audit section.
  #
  # Parameters:
  # section - a record that identifies the section
  #
  # Return value:
  # A user record for the teammate, if one exists.  Otherwise a nil 
  # is returned.
  #
  ######################################################################
  #
  def get_section_teammate(section)
  
    teammate = self.audit_teammates.detect do |at| 
      at.section_id == section.id && at.self == (self.is_self_audit? ? 1 : 0)
    end
  
    # If a teammate was located, return the user record.
    teammate ? teammate.user : nil
    
  end
  
  
  ######################################################################
  #
  # section_auditor?
  #
  # Description:
  # Indicates that the user can perform the audit for the audit section.
  #
  # Parameters:
  # section - a record that identifies the section
  # user    - a record that identifies the user
  #
  # Return value:
  # TRUE  - the user can perform the audit for the section
  # FALSE - the user can not perform the audit for the section
  #
  ######################################################################
  #
  def section_auditor?(section, user)

    teammate = self.get_section_teammate(section)

    if self.is_self_audit?
      ((!teammate && user.id == self.design.designer_id) || ( teammate && user == teammate))
    else
      (!self.is_complete? &&
       ((!teammate && user.id == self.design.peer_id) || ( teammate && user == teammate)))
    end
    
  end


  ######################################################################
  #
  # filtered_checklist
  #
  # Description:
  # The method will removed sections and subsections based on whether
  # the audit is a full, date code, or dot rev audit
  #
  # Parameters:
  # user - a user record that identifies the person who is logged in.
  #
  # Return value:
  # The audit's checklist will be modified as described above.
  #
  ######################################################################
  #
  def filtered_checklist(user)

    sections = self.checklist.sections
    
    if self.design.date_code?
      sections.delete_if { |sec| !sec.date_code_check? }
      sections.each do |section|
        section.subsections.delete_if { |subsec| !subsec.date_code_check? }
      end
    elsif self.design.dot_rev?
      sections.delete_if { |sec| !sec.dot_rev_check? }
      sections.each do |section|
        section.subsections.delete_if { |subsec| !subsec.dot_rev_check? }
      end
    end
    
    if self.is_peer_audit? && self.is_peer_auditor?(user)
      sections.delete_if { |sec| sec.designer_auditor_checks == 0 }
      sections.each do |section|
        section.subsections.delete_if { |subsec| subsec.designer_auditor_checks == 0 }
      end
    end
    
  end
  
  
  ######################################################################
  #
  # update_type
  #
  # Description:
  # The method returns the update type based on the user and the state
  # of the audit (self audit vs. peer audit).
  #
  # Parameters:
  # user - a user record that identifies the person who is logged in.
  #
  # Return value:
  # A string that indicates the state of audit - self, peer, or none
  #
  ######################################################################
  #
  def update_type(user)
    if    (self.is_self_auditor?(user) && self.is_self_audit?)
      :self
    elsif (self.is_peer_auditor?(user) && self.is_peer_audit?)
      :peer
    else
      :none
    end
  end
  
  
end
