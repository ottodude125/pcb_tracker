########################################################################
#
# Copyright 2012, by Teradyne, Inc., North Reading MA
#
# File: oi_instruction_mailer.rb
#
# This file contains the methods to generate email for the oi instruction.
#
# $Id$
#
########################################################################

require 'mailer_methods'

class OiInstructionMailer < ActionMailer::Base
  
  default  :from  => Pcbtr::SENDER
  default  :bcc   => []
 
  ######################################################################
  #
  # oi_assignment_notification
  #
  # Description:
  # This method generates mail to indicate that an outsource instruction
  # has been assigned.
  #
  # Parameters:
  #   oi_assignment_list - the outsource assignment list 
  #
  ######################################################################
  
  def oi_assignment_notification(oi_assignment_list)
  
    design = oi_assignment_list[0].oi_instruction.design   
    to_list = [oi_assignment_list[0].user.email]
    cc_list = Role.add_role_members(['PCB Input Gate', 'Manager', 'HCL Manager']) +
              [oi_assignment_list[0].oi_instruction.user.email]
    if oi_assignment_list[0].cc_hw_engineer?
      cc_list += design.get_role_reviewers('HWENG').map { |u| u.email }
    end
    cc_list -= to_list
    cc_list.uniq!

    assignment  = oi_assignment_list.size == 1 ? 'Assignment' : 'Assignments'
    subject    = MailerMethods.subject_prefix(design) + "Work #{assignment} created"

    @lead_designer      = oi_assignment_list[0].user
    @design              = design
    @oi_assignment_list = oi_assignment_list

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )   
  
  end
  
  
  ######################################################################
  #
  # oi_task_update
  #
  # Description:
  # This method generates mail to indicate that an outsource instruction
  # assignment has been updated.
  #
  # Parameters:
  #   assignment - the assignment record that was just updated
  #   originator - the user record of the person who made the update
  #   completed  - a flag to indicate that the assignment has been set
  #                to complete when true
  #   reset      - a flag to indicate that the assignment has been reset
  #                when true
  #
  ######################################################################
  
  def oi_task_update(assignment, originator, completed, reset)
  
    subject    = MailerMethods.subject_prefix(assignment.oi_instruction.design) +
                  'Work Assignment Update'
    subject += completed ? " - Completed" : (reset ? " - Reopened" : '')

    cc_list = []
    # If the user making the update is the designer assigned to perform the
    # task
    if assignment.user_id == originator.id
      # The recipient is the designer who made the original assignment 
      to_list = [assignment.oi_instruction.user.email, ]
      # If the designer has been changed since the assignment was created,
      # add the new designer to the recipient list.
      if originator.id != assignment.oi_instruction.design.designer_id
        to_list << assignment.oi_instruction.design.designer.email
      end
    else
      # The recipient is the designer assigned to perform the task
      to_list = [assignment.user.email]
      # If the designer has been changed since the assignment was created,
      # add the new designer to the recipient list.
      if originator.id != assignment.oi_instruction.design.designer_id
        cc_list << assignment.oi_instruction.design.designer.email
      end
    end

    cc_list     += Role.add_role_members(['PCB Input Gate', 'Manager', 'HCL Manager']) +
               [assignment.oi_instruction.user.email, originator.email]
    if assignment.cc_hw_engineer?
      cc_list += assignment.oi_instruction.design.get_role_reviewers('HWENG').map { |u| u.email }
    end
    
    # Remove duplicates from the CC list.
    cc_list = (cc_list - to_list).uniq

    @assignment = assignment

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )   
        
  end
 
end
