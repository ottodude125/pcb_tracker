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

  has_many :design_checks


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
