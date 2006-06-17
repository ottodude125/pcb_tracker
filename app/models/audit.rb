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
  belongs_to :suffix

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
  # This method determines if the audit is a self audit.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the audit has not completed the self audit, FALSE otherwise.
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
  
  
  private

  ######################################################################
  #
  # create_checklist
  #
  # Description:
  # This method creates a new checklist at the kick off of a 
  # Peer Audit Revew.
  #
  # Parameters:
  # audit_id - Identifies the audit that the checklist will use
  #            as a template
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def self.create_checklist(audit_id)

    audit = Audit.find(audit_id)

    checklist = Checklist.find(audit.checklist_id)

    for section in checklist.sections
      for subsection in section.subsections
        for check in subsection.checks

          if ((audit.design.design_type == 'New') ||
              ((audit.design.design_type == 'Date Code') &&
               check.date_code_check?)    ||
              ((audit.design.design_type == 'Dot Rev') &&
               check.dot_rev_check?))
            new_design_check = DesignCheck.new
            new_design_check.audit_id = audit_id
            new_design_check.check_id = check.id

            fail 'Design check not saved' unless new_design_check.save

          end
        end
      end
    end
    
  end # create_checklist method


  ######################################################################
  #
  # check_count
  #
  # Description:
  # This method returns the number of checks for the designer and the
  # peer based on the design type.
  #
  # Parameters:
  # audit_id - Identifies the audit
  #
  # Return value:
  # check_count - a hash containing a value for the designer and the peer.
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def self.check_count(audit_id)

    audit = Audit.find(audit_id)

    count = Hash.new
    checklist = audit.checklist

    case audit.design.design_type
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
  end # check_count
  
  
end
