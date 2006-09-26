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
  
    if !self.designer_complete?
      return SELF_AUDIT
    elsif !self.auditor_complete?
      return PEER_AUDIT
    else
      return AUDIT_COMPLETE
    end
    
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
    self.audit_teammates.detect { |teammate| teammate.user_id == user.id && !teammate.self? }
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

    for section in checklist.sections
      for subsection in section.subsections
        for check in subsection.checks
          if ((design.new?)                          ||
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
  
  
end
