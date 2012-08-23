########################################################################
#
# Copyright 2012, by Teradyne, Inc., North Reading MA
#
# File: audit_mailer.rb
#
# This file contains the methods to generate email for the audit.
#
# $Id$
#
########################################################################

require 'mailer_methods'

class AuditMailer < ActionMailer::Base
  
  default  :from  => Pcbtr::SENDER
  default  :bcc   => []
  
  ######################################################################
  #
  # peer_audit_complete
  #
  # Description:
  # This method generates the mail to the designer that indicates that
  # the peer has completed the audit.
  #
  # Parameters:
  #   audit   - the audit that is being processed
  #
  ######################################################################
  #
  def peer_audit_complete(audit)
    
    designer = audit.design.designer
    peer     = audit.design.peer
    
    to_list  = [designer.email]
    cc_list  = ([peer.email] + 
                  Role.add_role_members(['Manager', 'PCB Input Gate']) -
                  to_list ).uniq
    subject  = MailerMethods.subject_prefix(audit.design) + "The peer audit is complete"

    @peer = peer
    @designer = designer
    @audit = audit

    mail(:to      => to_list,
         :subject => subject,
         :cc      => cc_list
         )
    
  end
  
  
  ######################################################################
  #
  # self_audit_complete
  #
  # Description:
  # This method generates the mail to the peer that indicates that
  # the designer has completed the self audit.
  #
  # Parameters:
  #   audit   - the audit that is being processed
  #
  ######################################################################
  #
  def self_audit_complete(audit)
    
    designer = audit.design.designer
    peer     = audit.design.peer

    to_list  = [peer.email]
    cc_list  = ([designer.email] + 
                  Role.add_role_members(['Manager', 'PCB Input Gate']) -
                  to_list).uniq
    subject  = MailerMethods.subject_prefix(audit.design) + 
                  "The designer's self audit is complete"

    @peer = peer
    @designer = designer
    @audit = audit

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
         )

  end


  ######################################################################
  #
  # final_review_warning
  #
  # Description:
  # This method generates the mail to alert the review community that the
  # final review will be posted soon.
  #
  # Parameters:
  #   design  - the design for which the final review will soon be posted.
  #
  # Additional information:
  #
  ######################################################################
  #
  def final_review_warning(design)

    final_review = design.design_reviews.detect { |dr| dr.review_type.name == "Final" }

    to_list   = final_review.design_review_results.collect { |rr|
                     User.find(rr.reviewer_id).email }.uniq
    cc_list   = (MailerMethods.copy_to(final_review) + 
                 MailerMethods.copy_to_on_milestone(final_review.design.board) -
                 to_list).uniq
    subject    = MailerMethods.subject_prefix(design) + 'Notification of upcoming Final Review'

    
    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )

  end


  ######################################################################
  #
  # audit_team_updates
  #
  # Description:
  # This method generates the mail to let people know that they have 
  # been added or removed from an audit team.
  #
  # Parameters:
  #   updated_by       - The user who made the updates.
  #   audit            - The record for the audit.  
  #   team_update_list - A list of users who have either been added or 
  #                      removed from the audit team.
  #
  ######################################################################
  #
  def audit_team_updates(updated_by,
                         audit,
                         team_update_lists)


    to_list = []
    team_update_lists.each do |key, list|
      team_update_lists[key] = list.sort_by { |t| t[:teammate].section.position }
      to_list += list.collect { |teammate| teammate[:teammate].user.email }
    end
    
    audit_team_lists = { 'self' => [], 'peer' => [] }
    audit.audit_teammates.each do |member|
      key = member.self? ? 'self' : 'peer'
      audit_team_lists[key] << member
    end

    audit_team_lists.each do |key, list|

      audit_team_lists[key] = list.sort_by { |t| t.section.position }

      #for teammate in list
      #  recipients.push(teammate.user.email)
      #end
      to_list += list.collect { |teammate| teammate.user.email }
    
    end

    cc_list = ([updated_by.email] + 
               Role.add_role_members(['Manager', 'PCB Input Gate']) -
               to_list).uniq
    
    subject = MailerMethods.subject_prefix(audit.design) + "The audit team has been updated"

    @updated_by = updated_by
    @audit      = audit
    @updates    = team_update_lists
    @audit_team = audit_team_lists

    mail( :to      => to_list.uniq,
          :subject => subject,
          :cc      => cc_list
        )

  end


  ######################################################################
  #
  # audit_update
  #
  # Description:
  # This method generates mail to indicate that the peer auditor has entered
  # a comment that the designer needs to respond to.
  #
  # Parameters:
  #   design_review_document - the design review document record
  #
  ######################################################################
  #
  def audit_update(design_check,
                   comment,
                   designer,
                   peer)

    to_list  = [designer.email]
    cc_list  = [peer.email]
    subject    = MailerMethods.subject_prefix(design_check.audit.design)                +
                  'PEER AUDIT - A comment has been entered that requires ' +
                  'your attention'

    @design_check = design_check
    @check        = Check.find(design_check.check_id)
    @comment      = comment

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )   

  end

end