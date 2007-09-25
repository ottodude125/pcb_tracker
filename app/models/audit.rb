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
    self.find(:all, :conditions => "auditor_complete=0", :order => "id")
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

    self.checklist.each_check do |check|
      if check.belongs_to? self.design
        design_check = DesignCheck.new(:audit_id => self.id, :check_id => check.id)
        fail 'Design check not saved' unless design_check.save        
      end
    end
    
  end
  
  
  ######################################################################
  #
  # update_checklist_type
  #
  # Description:
  # This method creates or destroys design checks based on the type of
  # design the audit is tied to.  This is used when the type of design
  # is changed.
  #
  # Parameters:
  # None
  #
  # Returns:
  # The number of design checks added or deleted.
  #
  ######################################################################
  #
  def update_checklist_type

    design_checks = DesignCheck.find(:all, :conditions => "audit_id=#{self.id}")
    delta = 0
    
    # Keep track of the completed checks that are deleted to update the
    # audit counts of the completed checks.
    completed_self_check_delta = 0
    completed_peer_audit_delta = 0
    self.checklist.each_check do |check|
      design_check = design_checks.detect { |dc| dc.check_id == check.id }  
      if check.belongs_to? self.design
        if !design_check
          design_check = DesignCheck.new(:audit_id => self.id, :check_id => check.id)
          fail 'Design check not saved' unless design_check.save  
          delta += 1
        end
      else
        # Keep track of the adjustments that need to be made for the totals
        completed_self_check_delta += 1 if design_check.self_auditor_checked?
        completed_peer_audit_delta += 1 if design_check.peer_auditor_checked?
        design_check.destroy if design_check
        delta -= 1
      end
    end
    
    # If any of the deleted design checks were complete then the audit record needs to
    # be updated.
    if (completed_self_check_delta + completed_peer_audit_delta > 0)
      if completed_self_check_delta > 0
        completed_checks = self.designer_completed_checks - completed_self_check_delta
        self.designer_completed_checks = completed_checks
        self.designer_complete         = (completed_checks == self.self_check_count)
      end
      if completed_peer_audit_delta > 0
        completed_checks = self.auditor_completed_checks - completed_peer_audit_delta
        self.auditor_completed_checks = completed_checks
        self.auditor_complete         = (completed_checks == self.peer_check_count)
      end
      self.update
    end
    
    delta
    
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
  # completed_check_count
  #
  # Description:
  # Returns the number of design checks that are completed for
  # both the self and peer audit.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def completed_check_count
    
    count = { :self => 0, :peer => 0 }
    
    self.design_checks.each do |dc|
      count[:self] += 1 if dc.self_auditor_checked?
      count[:peer] += 1 if dc.peer_auditor_checked?
    end
    
    count
    
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
  
  
  ######################################################################
  #
  # self_update?
  #
  # Description:
  # The method determines if the update that is being processed is a
  # self audit update.
  #
  # Parameters:
  # user - a user record that identifies the person who is logged in.
  #
  # Return value:
  # True if the update is to the self audit.  Otherwise, false
  #
  ######################################################################
  #
  def self_update?(user)
    self.is_self_audit? && self.is_self_auditor?(user)
  end
  
  
  ######################################################################
  #
  # peer_update?
  #
  # Description:
  # The method determines if the update that is being processed is a
  # peer audit update.
  #
  # Parameters:
  # user - a user record that identifies the person who is logged in.
  #
  # Return value:
  # True if the update is to the peer audit.  Otherwise, false
  #
  ######################################################################
  #
  def peer_update?(user)
    self.is_peer_audit? && self.is_peer_auditor?(user)
  end
  
  
  ######################################################################
  #
  # process_self_audit_update
  #
  # Description:
  # The method processes self audit input.  If the result is anything
  # than "None" then the designer completed checks is incremented and 
  # the design_check.designer_result is updated with the new result.
  # If the self audit is complete then email is sent indicating that
  # the self audit is complete and another is sent to indicate that the
  # final review will be posted shortly.
  #
  # Parameters:
  # result_update - the result for the design check entered by the user
  # design_check  - the design check that is being updated
  # user          - a user record that identifies the person who is 
  #                 logged in.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def process_self_audit_update(result_update, design_check, user)

    if design_check.designer_result == "None"

      begin
        completed_checks = self.designer_completed_checks + 1
        self.update_attributes(
          :designer_completed_checks => completed_checks,
          :designer_complete         => (completed_checks == self.self_check_count))
      rescue ActiveRecord::StaleObjectError
        self.reload
        retry
      end

      if self.designer_complete?
        TrackerMailer.deliver_self_audit_complete(self)
        TrackerMailer.deliver_final_review_warning(self.design)
      end
      
      self.reload
      
    end

    design_check.update_attributes(:designer_result     => result_update,
                                   :designer_checked_on => Time.now,
                                   :designer_id         => user.id)
  end
  
  
  ######################################################################
  #
  # process_peer_audit_update
  #
  # Description:
  # The method processes peer audit input.  If the result is anything
  # than "None" or "Comment then the auditor completed checks is 
  # incremented and the design_check.auditor_result is updated with the 
  # new result.  If the peer audit is complete then email is sent indicating 
  # that the peer audit is complete.
  #
  # Parameters:
  # result_update - the result for the design check entered by the user
  # comment       - the optional comment entered by the reviewer
  # design_check  - the design check that is being updated
  # user          - a user record that identifies the person who is 
  #                 logged in.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def process_peer_audit_update(result_update, comment, design_check, user)
  
    return if design_check.check.check_type != 'designer_auditor'

    complete   = ['Verified', 'N/A', 'Waived']
    incomplete = ['None', 'Comment']

    incr = 0
    incr = -1 if result_update == 'Comment'       && complete.include?(design_check.auditor_result)
    incr = 1  if complete.include?(result_update) && incomplete.include?(design_check.auditor_result)

    if incr != 0
      begin
        completed_checks = self.auditor_completed_checks + incr
        self.update_attributes(
          :auditor_completed_checks => completed_checks,
          :auditor_complete         => (completed_checks == self.peer_check_count))
      rescue ActiveRecord::StaleObjectError
        self.reload
        retry
      end

      if self.auditor_complete?
        TrackerMailer.deliver_peer_audit_complete(self)
        #TODO - candidate for an audit method .delete_audit_teammates
        AuditTeammate.delete_all(["audit_id = ?", self.id])
      end
    end

    design_check.update_attributes(:auditor_result     => result_update,
                                   :auditor_checked_on => Time.now,
                                   :auditor_id         => user.id)
                     
    TrackerMailer::deliver_audit_update(design_check,
                                        comment,
                                        self.design.designer,
                                        user) if result_update == 'Comment'
   end


  ######################################################################
  #
  # manage_auditor_list
  #
  # Description:
  # The method processes updates to the audit team.  Audit Teammate 
  # records are added and removed from the database based on the user's
  # input.
  #
  # Parameters:
  # self_auditor_list - a hash of self audit assignments.  The hash
  #                     is accessed by section ids (key) to provide
  #                     the user of id of the self auditor
  # peer_auditor_list - a hash of peer audit assignments.  The hash
  #                     is accessed by section ids (key) to provide
  #                     the user of id of the peer auditor
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def manage_auditor_list(self_auditor_list, peer_auditor_list, user)

    lead_designer_assignments = {}
    self_auditor_list.each do |key, auditor|
      lead_designer_assignments[key] = (self.design.designer_id == auditor.to_i)
    end

    lead_peer_assignments = {}
    peer_auditor_list.each do |key, auditor|
      lead_peer_assignments[key] = (self.design.peer_id == auditor.to_i)
    end


    self_auditor_list.delete_if { |k,v| v.to_i == self.design.designer_id }
    peer_auditor_list.delete_if { |k,v| v.to_i == self.design.peer_id }

    audit_teammates = self.audit_teammates
    
    # Remove any teammates if the section has been reassign back to the lead
    teammate_list_updates = { 'self' => [], 'peer' => [] }
    audit_teammates.each do |audit_teammate|
      if ((audit_teammate.self? &&
           lead_designer_assignments[audit_teammate.section_id]) ||
          (!audit_teammate.self? &&
           lead_peer_assignments[audit_teammate.section_id]))

        key = audit_teammate.self? ? 'self' : 'peer'

        teammate_list_updates[key] << { :action   => 'Removed ',
                                        :teammate => audit_teammate }
        audit_teammate.destroy
      end
    end

    # Go through the assignments and make sure the same person has
    # not been assigned to the same section for peer and self audits.
    self.clear_message
    self_auditor_list.each do |section_id, self_auditor|

      next if self_auditor == ''

      if ((self_auditor == peer_auditor_list[section_id]) ||
          (!peer_auditor_list[section_id] && self_auditor.to_i == self.design.peer_id))
        self.set_message('WARNING: Assignments not made <br />') if !self.message
        section = Section.find(section_id)
        auditor = User.find(self_auditor)
        self.set_message('         ' + auditor.name + ' can not be both ' +
                         'self and peer auditor for ' + section.name + '<br />',
                         'append')
        self_auditor_list[section_id] = ''
        peer_auditor_list[section_id] = ''
      end

    end

    self_auditor_list.each do |section_id, self_auditor|
    
      next if self_auditor == ''
      audit_teammate = audit_teammates.detect do |t|
        t.self? && t.section_id.to_i == section_id.to_i
      end

     if !audit_teammate
        audit_teammate = AuditTeammate.new(:audit_id   => self.id,
                                           :section_id => section_id,
                                           :user_id    => self_auditor,
                                           :self       => 1)
        audit_teammate.save
        teammate_list_updates['self'] << { :action   => 'Added ',
                                           :teammate => audit_teammate }
      elsif audit_teammate.user_id != self_auditor.to_i
        #old_teammate = audit_teammate.dup
        old_teammate = AuditTeammate.new(:audit_id   => self.id,
                                         :section_id => section_id,
                                         :user_id    => audit_teammate.user_id,
                                         :self       => 1)
        teammate_list_updates['self'] << { :action   => 'Removed ',
                                           :teammate => old_teammate }
        audit_teammate.update_attribute(:user_id, self_auditor)

        teammate_list_updates['self'] << { :action   => 'Added ',
                                           :teammate => audit_teammate }
      end

    end

    peer_auditor_list.each do |section_id, peer_auditor|
    
      next if peer_auditor == ''
      audit_teammate = audit_teammates.detect do |t|
        !t.self? && t.section_id.to_i == section_id.to_i
      end 

      if !audit_teammate
        audit_teammate = AuditTeammate.new(:audit_id   => self.id,
                                           :section_id => section_id,
                                           :user_id    => peer_auditor,
                                           :self       => 0)
        audit_teammate.save
        teammate_list_updates['peer'] << { :action   => 'Added ',
                                           :teammate => audit_teammate }
      elsif audit_teammate.user_id != peer_auditor.to_i
        #old_teammate = audit_teammate.dup
        old_teammate = AuditTeammate.new(:audit_id   => self.id,
                                         :section_id => section_id,
                                         :user_id    => audit_teammate.user_id,
                                         :self       => 0)
        teammate_list_updates['peer'] << { :action   => 'Removed ',
                                           :teammate => old_teammate }
        audit_teammate.update_attribute(:user_id, peer_auditor)

        teammate_list_updates['peer'] << { :action   => 'Added ',
                                           :teammate => audit_teammate }    
      end
    end

    if (teammate_list_updates['self'].size + teammate_list_updates['peer'].size) > 0
    
      self.set_message('Updates to the audit team for the ' +
                       self.design.part_number.pcb_display_name +
                       ' have been recorded - mail was sent',
                       'append')
    
      self.reload
      TrackerMailer::deliver_audit_team_updates(user,
                                                self,
                                                teammate_list_updates)
    end

   end


  ######################################################################
  #
  # process_design_checks
  #
  # Description:
  # Processes a list of design check updates.  Processing is done for 
  # both the self and peer updates.
  #
  # Parameters:
  # design_check_list - a list of self or peer design check updates
  # user              - the record for the user making the update
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def process_design_checks(design_check_list, user)

    # Go through the paramater list and pull out the checks.
    design_check_list.each { |design_check_update|

      design_check = DesignCheck.find(design_check_update[:design_check_id])

      if self.self_update?(user)
        result        = design_check.designer_result
        result_update = design_check_update[:designer_result]
      elsif self.peer_update?(user)
        result        = design_check.auditor_result
        result_update = design_check_update[:auditor_result]
      end

      comment = design_check_update[:comment].strip
      
      if result_update && result_update != result

        # Make sure that the required comment has been added.
        if comment.size == 0 &&
           design_check.comment_required?(design_check_update[:designer_result], 
                                          design_check_update[:auditor_result])
         
          flash[design_check.id] = 'A comment is required for a ' + result_update +
                                   ' response.'
          flash['notice']        = 'Not all checks were updated - please review ' +
                                   'the form for errors.'
          next
        end

        if !self.designer_complete? && self.self_update?(user)
          self.process_self_audit_update(result_update, design_check, user)
        elsif !self.auditor_complete? && self.peer_update?(user)
          self.process_peer_audit_update(result_update, 
                                         design_check_update[:comment], 
                                         design_check, 
                                         user)
        end

      end

      # If the user entered a comment, update the database.
      if comment.size > 0
        AuditComment.new(:comment => comment, :user_id => user.id,
                         :design_check_id => design_check.id).create
      end
    }

    redirect_to(:action        => 'perform_checks',
                :audit_id      => params[:audit][:id],
                :subsection_id => params[:subsection][:id])
    
  end

  
  ######################################################################
  #
  # clear_message
  #
  # Description:
  # The method clears all of the  error messages
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
   def clear_message
     errors.clear
   end
   
   
  ######################################################################
  #
  # message?
  #
  # Description:
  # The method indicates if there is an error message available for the
  # object
  #
  # Parameters:
  # None
  #
  # Return value:
  # True if an error message exists.  Otherwise False
  #
  ######################################################################
  #
   def message?
     errors.on(:message) != nil
   end
   
   
  ######################################################################
  #
  # set_message
  #
  # Description:
  # Creates or appends the message to the error message depending on the
  # append flag
  #
  # Parameters:
  # append - a flag that indicates the message should be appended to any
  # existing error message when True
  #
  # Return value:
  # None
  #
  ######################################################################
  #
   def set_message(message, append=false)
     errors.clear if !append
     errors.add(:message, message)
   end
   
   
  ######################################################################
  #
  # set_message
  #
  # Description:
  # Returns the error message that is stored with the object
  #
  # Parameters:
  # None
  #
  # Return value:
  # A string representing the store error message.
  #
  ######################################################################
  #
   def message
     message = errors.on(:message)
     if message.class == String
       message
     elsif message.class == Array
       message.join
     end
   end

  
end
