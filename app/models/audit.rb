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


  # Find incomplete audits
  # 
  # :call-seq:
  #   Audit.find_incomplete_audits() -> array
  #
  # Returns a list of incomplete audits as an array.
  def self.find_incomplete_audits
    self.find(:all, :conditions => "auditor_complete=0", :order => "id")
  end
  
  
  # Find active audits for a designer
  #
  # :call-seq:
  #   Audit.active_audits(user) -> array
  #
  # Returns a list of active audits for the designer (user) as an array
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
  
  
  # Report the statu of the audit.
  #
  # :call-seq:
  #   audit_state() -> integer
  #
  # Returns one of the following values that indicate the state of the
  # audit.
  #    Audit::SELF_AUDIT::  the audit is in the self audit state
  #    Audit::PEER_AUDIT::  the audit is in the peer audit state
  #    Audit::AUDIT_COMPLETE:: the audit is complete  
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
    (self.design.designer_id == user.id ||
     self.audit_teammates.detect { |t| t.user_id == user.id && t.self? })
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
    (self.design.peer_id == user.id ||
     self.audit_teammates.detect { |t| t.user_id == user.id && !t.self? })
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
      DesignCheck.add(self, check) if check.belongs_to?(self.design)
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
      if check.belongs_to?(self.design)
        if !design_check
          DesignCheck.add(self, check)
          delta += 1
        end
      else
        # Keep track of the adjustments that need to be made for the totals
        completed_self_check_delta -= 1 if design_check.self_auditor_checked?
        completed_peer_audit_delta -= 1 if design_check.peer_auditor_checked?
        if design_check
          design_check.destroy
          delta -= 1
        end
      end
    end
    
    # If any of the deleted design checks were complete then the audit record needs to
    # be updated.
    self.update_self_check_count(completed_self_check_delta) if completed_self_check_delta < 0
    self.update_peer_check_count(completed_peer_audit_delta) if completed_peer_audit_delta < 0
    
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

    count     = { :designer => 0, :peer => 0 }
    checklist = self.checklist

    case self.design.design_type
    when 'New'
      count[:designer] = checklist.new_design_self_check_count
      count[:peer]     = checklist.new_design_peer_check_count
    when 'Dot Rev'
      count[:designer] = checklist.bareboard_design_self_check_count
      count[:peer]     = checklist.bareboard_design_peer_check_count
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
      checklist.new_design_peer_check_count
    when 'Dot Rev'
      checklist.bareboard_design_peer_check_count
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
    if self.auditor_completed_checks <= self.peer_check_count
      self.auditor_completed_checks * 100.0 / self.peer_check_count
    else
      100.0
    end
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
      checklist.new_design_self_check_count
    when 'Dot Rev'
      checklist.bareboard_design_self_check_count
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
    if self.designer_completed_checks <= self.self_check_count
      self.designer_completed_checks * 100.0 / self.self_check_count
    else
      100.0
    end
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
  
    stats = { :self => "0.0", :peer => "0.0" }
    total_checks = self.check_count
    
    if total_checks[:designer] > 0
      stats[:self] = self.designer_completed_checks * 100.0 / total_checks[:designer]
    end
    if total_checks[:peer] > 0
      stats[:peer] = self.auditor_completed_checks  * 100.0 / total_checks[:peer]
    end

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
    design_checks.delete_if do |dc| 
      check = Check.find(dc.check_id)
      !subsection.checks.include?(check)
    end

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
    design_checks.delete_if do |dc| 
      check = Check.find(dc.check_id)
      !subsection.checks.include?(check) 
    end

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
      sections.delete_if { |sec| sec.designer_auditor_check_count == 0 }
      sections.each do |section|
        section.subsections.delete_if { |subsec| subsec.designer_auditor_check_count == 0 }
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

      self.update_self_check_count
 
      if self.designer_complete?
        TrackerMailer.deliver_self_audit_complete(self)
        TrackerMailer.deliver_final_review_warning(self.design)
      end
      
      self.reload
      
    end

    design_check.update_designer_result(result_update, user)
    
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

    check = Check.find(design_check.check_id)
    return if check.check_type != 'designer_auditor'

    incr = design_check.update_auditor_result(result_update, user)

    if incr != 0
      self.update_peer_check_count(incr)
      TrackerMailer.deliver_peer_audit_complete(self) if self.auditor_complete?
    end

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
        audit_teammate = 
          AuditTeammate.new_teammate(self.id, section_id, self_auditor, :self)
        teammate_list_updates['self'] << { :action => 'Added ',:teammate => audit_teammate }
      elsif audit_teammate.user_id != self_auditor.to_i
        old_teammate = 
          AuditTeammate.new_teammate(self.id, section_id, audit_teammate.user_id, :self, false)
        audit_teammate.user_id = self_auditor
        audit_teammate.save
        audit_teammate.reload

        teammate_list_updates['self'] << { :action => 'Removed ', :teammate => old_teammate }
        teammate_list_updates['self'] << { :action => 'Added ',   :teammate => audit_teammate }
      end

    end

    peer_auditor_list.each do |section_id, peer_auditor|
    
      next if peer_auditor == ''
      audit_teammate = audit_teammates.detect do |t|
        !t.self? && t.section_id.to_i == section_id.to_i
      end 

      if !audit_teammate
        audit_teammate = 
          AuditTeammate.new_teammate(self.id, section_id, peer_auditor, :peer)
        teammate_list_updates['peer'] << { :action   => 'Added ',
                                           :teammate => audit_teammate }
      elsif audit_teammate.user_id != peer_auditor.to_i
        old_teammate =
          AuditTeammate.new_teammate(self.id, section_id, audit_teammate.user_id, :peer, false)
        audit_teammate.user_id = peer_auditor
        audit_teammate.save
        audit_teammate.reload
        
        teammate_list_updates['peer'] << { :action => 'Removed ', :teammate => old_teammate }
        teammate_list_updates['peer'] << { :action => 'Added ',   :teammate => audit_teammate }    
      end
    end

    if (teammate_list_updates['self'].size + teammate_list_updates['peer'].size) > 0
    
      self.set_message('Updates to the audit team for the ' +
                       self.design.directory_name +
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


  ######################################################################
  #
  # update_self_check_count
  #
  # Description:
  # Increments the designer (self) completed check count by count.  If
  # the caller does not specify the count then the increment is by 1.
  # If another user has updated the record,  the exception handler code
  # is executed.  The audit record is reloaded and the work is redone.
  #
  # Parameters:
  # count - provides the increment value
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update_self_check_count(count = 1)
    begin
      completed_checks = self.designer_completed_checks + count
      self.designer_completed_checks = completed_checks
      self.designer_complete         = (completed_checks == self.self_check_count)
      self.save
    rescue ActiveRecord::StaleObjectError
      self.reload
      retry
    end
  end


  ######################################################################
  #
  # update_peer_check_count
  #
  # Description:
  # Increments the auditor (peer) completed check count by count.  If
  # the caller does not specify the count then the increment is by 1.
  # If another user has updated the record,  the exception handler code
  # is executed.  The audit record is reloaded and the work is redone.
  #
  # Parameters:
  # count - provides the increment value
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update_peer_check_count(count = 1)
    begin
      completed_checks = self.auditor_completed_checks + count
      self.auditor_completed_checks = completed_checks
      self.auditor_complete         = (completed_checks == self.peer_check_count)
      self.save
    rescue ActiveRecord::StaleObjectError
      self.reload
      retry
    end
  end
  
  
  # Retrieve a list of designers eligible to perform a self audit.
  #
  # :call-seq:
  #   self_audtor_list() -> array
  #
  #  The array returned contains a list of active designers.
  def self_auditor_list
    @self_auditor_list ||= Role.active_designers
  end
  
  
  # Retrieve a list of designers eligible to perform a peer audit.
  #
  # :call-seq:
  #   peer_audtor_list() -> array
  #
  # The array returned contains a list of active designers with the record
  # for the lead designer removed.
  def peer_auditor_list
    @peer_auditor_list ||= (self.self_auditor_list - [self.design.designer])
  end
  
  
  # Trim sections, subsections, and checks from the audit that do not apply.
  # 
  # :call-seq:
  #   trim_checklist_for_design_type() -> audit
  #
  # The resulting audit checklist contains only the sections, subsection, and
  # checks that apply to the audit.
  def trim_checklist_for_design_type
    
    design = self.design
    
    # Remove the sections that are not used in the audit.
    self.checklist.sections.delete_if { |section| !design.belongs_to(section) }
    
     self.checklist.sections.each do |section|
       
      # Remove the subsections that are not used in the audit.
      section.subsections.delete_if { |subsection| !design.belongs_to(subsection) }
      
      section.subsections.each do |subsection|
        # Remove the checks that are not used in the audit.
        subsection.checks.delete_if { |check| !design.belongs_to(check) }
      end
    end
    
  end
  
  
  # Trim checks that do no apply to a self audit.
  # 
  # :call-seq:
  #   trim_checklist_for_self_audit() -> audit
  #
  # The resulting audit checklist contains only the checks that apply to a 
  # self audit.
 def trim_checklist_for_self_audit
    
   self.trim_checklist_for_design_type
   self.checklist.sections.each do |section|
     section.subsections.each do |subsection|
       subsection.checks.delete_if { |check| !check.is_self_check? }
     end
   end
    
   # Lop off any empty sections and subsections
   self.checklist.sections.delete_if { |section| section.check_count == 0 }
   self.checklist.sections.each do |section|
     section.subsections.delete_if { |subsection| subsection.check_count == 0 }
   end
    
 end
  

  # Trim checks that do no apply to a peer audit.
  # 
  # :call-seq:
  #   trim_checklist_for_peer_audit() -> audit
  #
  # The resulting audit checklist contains only the checks that apply to a 
  # peer audit.
  def trim_checklist_for_peer_audit
    
    self.trim_checklist_for_design_type
    
    self.checklist.sections.each do |section|
      section.subsections.each do |subsection|
        subsection.checks.delete_if { |check| !check.is_peer_check? }
      end
    end
    
   # Lop off any empty sections and subsections
    self.checklist.sections.delete_if { |section| section.check_count == 0 }
    self.checklist.sections.each do |section|
      section.subsections.delete_if { |subsection| subsection.check_count == 0 }
    end
    
  end
  
  
  # Retrieve and load the associated design checks
  #
  # :call-seq:
  #   get_design_checks() -> audit
  #
  # Go through all of the checks in the check list and attach the associated
  # design checks.
  def get_design_checks
    
    design_checks = DesignCheck.find(:all, :conditions => "audit_id=#{self.id}")
    
    self.checklist.each_check do |check|
      design_check       = design_checks.detect { |dc| dc.check_id == check.id }
      check.design_check = design_check if design_check
    end
    
  end
  
  
  # Provide the user record of the self of peer auditor depending on
  # the state of the audit (self or peer)
  #
  # :call-seq:
  #   auditor(section) -> user
  #
  # Returns the user record of the auditor assigned to perform the self or
  # peer audit depending on the state of the audit.
  def auditor(section)
    if self.is_self_audit?
      self.self_auditor(section)
    elsif self.is_peer_audit?
      self.peer_auditor(section)
    end
   end
   
  
  # Retrieve the self auditor for the section.
  #
  # :call-seq:
  #   self_audtor(section) -> user
  #
  #  If a self auditor for the section is assigned then the user record is returned.
  #  Otherwise the user record for the design's lead designer is returned.
  #  A nil is returned if none of the above conditions apply.
  def self_auditor(section)
    
    auditor = self.audit_teammates.detect { |tmate| tmate.section_id == section.id && tmate.self? }

    if auditor
      auditor.user
    elsif self.design.designer_id > 0 
      self.design.designer
    else
      nil
    end
    
  end
  
  
  # Retrieve the peer auditor for the section.
  #
  # :call-seq:
  #   peer_audtor(section) -> user
  #
  #  If a peer auditor for the section is assigned then the user record is returned.
  #  Otherwise the user record for the design's lead peer auditor is returned.
  #  A nil is returned if none of the above conditions apply.
  def peer_auditor(section)
    
    auditor = self.audit_teammates.detect { |tmate| tmate.section_id == section.id && !tmate.self? }
    auditor = self.design.auditor if !auditor
    if auditor 
      return auditor.user
    elsif self.design.peer_id > 0
      return self.design.peer
    else
      nil
    end
    
  end
  
  
  # Retrieve the next subsection in the audit.
  #
  # :call-seq:
  #   next_subsection(subsection) -> subsection
  #
  #  Returns the next subsection in the current section.  If the current subsection
  #  is the last subsection in the section then the first subsection in the
  #  next section is returned.  If there is no section following the current
  #  section then a nil is returned.
  def next_subsection(subsection)

    section = self.checklist.sections.detect { |s| s.id == subsection.section_id}
    i = section.subsections.index(subsection)
    if i < section.subsections.size - 1
      return section.subsections[i+1]
    else
      j = self.checklist.sections.index(section)
      if j < self.checklist.sections.size - 1
        return self.checklist.sections[j+1].subsections.first
      else
        return nil
      end
    end
  end
  
  
  # Retrieve the previous subsection in the audit.
  #
  # :call-seq:
  #   previous_subsection(subsection) -> subsection
  #
  #  Returns the previous subsection in the current section.  If the current subsection
  #  is the first subsection in the section then the last subsection in the
  #  previous section is returned.  If there is no section preceeding the current
  #  section then a nil is returned.
  def previous_subsection(subsection)

    section = self.checklist.sections.detect { |s| s.id == subsection.section_id}
    i = section.subsections.index(subsection)
    if i > 0
      return section.subsections[i-1]
    else
      j = self.checklist.sections.index(section)
      if j > 0
        return self.checklist.sections[j-1].subsections.last
      else
        return nil
      end
    end
  end
  
  
  # Update the audit's design check.
  #
  # :call-seq:
  #   update_design_check(design_check_update, user) -> nil
  #
  #  Determine the type of update that was passed in, self or peer, and 
  #  use the information to make the update to the stored design check.  Also
  #  make sure that any update that requires a comment includes the comment.
  #  If a required comment is not provided, the objects errors structure is
  #  updated.  The caller is responsible for checking for errors.
  #
  #  If a comment is included in the update then an Audit Comment record is 
  #  created and stored.
  def update_design_check(design_check_update, user)

    self.errors.clear
    
    self_audit_result = design_check_update[:designer_result]
    peer_audit_result = design_check_update[:auditor_result]

    updated = false
    design_check = DesignCheck.find(design_check_update[:design_check_id])
    if self_audit_result && self.self_update?(user)
      result  = self_audit_result
      updated = result != design_check.designer_result
    elsif peer_audit_result && self.peer_update?(user)
      result  = peer_audit_result
      updated = result != design_check.auditor_result
    end
    
    comment = design_check_update[:comment]
    if updated
      
      # Make sure that the required comment has been included.
      if (comment.strip.empty? && 
          design_check.comment_required?(self_audit_result, peer_audit_result))
        self.errors.add(:comment_required, "A comment is required for a #{result} response.")
      end
      
      if !self.designer_complete? && self.self_update?(user)
        self.process_self_audit_update(self_audit_result, design_check, user)
      elsif !self.auditor_complete? && self.peer_update?(user)
        self.process_peer_audit_update(peer_audit_result, comment, design_check, user)
      end
      
    end
    
    # If the user entered a comment, add the record to the database.
    if !comment.strip.empty?
      AuditComment.new( :comment         => comment,
                        :user_id         => user.id,
                        :design_check_id => design_check.id ).save
    end
      
  end
    
  
  ##############################################################################
  #
  # Private Methods
  # 
  ##############################################################################
  
  private
  

end
