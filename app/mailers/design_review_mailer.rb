########################################################################
#
# Copyright 2012, by Teradyne, Inc., North Reading MA
#
# File: design_review_mailer.rb
#
# This file contains the methods to generate email for the design review.
#
# $Id$
#
########################################################################

require "mailer_methods"

class DesignReviewMailer < ActionMailer::Base

  default :from => Pcbtr::SENDER
  default  :bcc   => []
 
  ######################################################################
  #
  # design_review_posting_notification
  #
  # Description:
  # This method generates the mail to alert the reviewers that a design
  # review has been posted or reposted.
  #
  # Parameters:
  #   design_review  - the design review that was posted
  #   comment        - the comment entered by the designer when posting
  #   repost         - a flag that indicates that the design review is
  #                    being reposted when true
  #
  ######################################################################
  def design_review_posting_notification(design_review,
                                         comment,
                                         repost         = false)

    to_list  = [ design_review.reviewer_list]
    cc_list  = design_review.copy_to +
               design_review.design.board.copy_to_on_milestone
    if design_review.review_type.name == "Pre-Artwork"
      slm_notify = Role.find_by_name("SLM-Vendor Notify")
      cc_list += slm_notify.active_users.collect { |u| u.email }
    end
    if design_review.review_type.name == "Final"
      pcb_admin = Role.find_by_name("PCB Admin")
      cc_list += pcb_admin.active_users.collect { |u| u.email }
      slm_notify = Role.find_by_name("SLM-Vendor Notify")
      cc_list += slm_notify.active_users.collect { |u| u.email }
    end
   cc_list = (cc_list - to_list).uniq

    subject  = design_review.design.subject_prefix +
                "The #{design_review.review_name} design review has been "
    subject += repost ? "reposted" : "posted"

    @user          = design_review.designer
    @comment       = comment
    @design_review = design_review
    @repost        = repost

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
         )
  end


  ######################################################################
  #
  # design_review_update
  #
  # Description:
  # This method generates the mail indicate that an update has been
  # made to a review.
  #
  # Parameters:
  #   user           - the user making the update
  #   design_review  - the design review that was updated
  #   comment_update - a flag to indicate if new comments were added
  #   result_update  - a flag to indicate if a result was entered
  #
  # Additional information:
  #
  ######################################################################
  def design_review_update(user,
                           design_review,
                           comment_update,
                           result_update   = {})

    to_list  = design_review.reviewer_list
    cc_list  = ( design_review.copy_to - to_list ).uniq

    review_results = ''
    prefix = design_review.design.subject_prefix + design_review.review_name
    if comment_update && result_update == {}
      subject    = "#{prefix} - Comments added"
    elsif result_update

      results = DesignReviewResult.find(
                  :all,
                  :conditions => "design_review_id=#{design_review.id} AND " +
                                 "reviewer_id='#{user.id}'")

      0.upto(results.size-1) { |i|
        review_results += "#{results[i].role.name} - #{results[i].result}"
        review_results += ', ' if results.size > 1 && i < (results.size-1)
        }

        if comment_update
          subject    = "#{prefix}  #{review_results} - See comments"
        else
          subject    = "#{prefix}  #{review_results} - No comments"
        end

    end

    @comments  = design_review.design_review_comments[0..3] if comment_update
    @user             = user
    @result_update    = result_update
    @design_review_id = design_review.id

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list 
        )
  end


  ######################################################################
  #
  # design_review_complete_notification
  #
  # Description:
  # This method generates the mail indicate that a design review has
  # completed.
  #
  # Parameters:
  #   design_review  - the design review that was completed
  #
  # Additional information:
  #
  ######################################################################
  def design_review_complete_notification(design_review)

     subject    = design_review.design.subject_prefix  +
                  'The '                               +
                  design_review.review_name            +
                  ' design review is complete'

    to_list = design_review.reviewer_list

    cc = design_review.copy_to + design_review.design.board.copy_to_on_milestone

    case design_review.review_type.name
    when "Release"
      #cc.push("STD_DC_ECO_Inbox@notes.teradyne.com") if Rails.env.production?
    when "Final"
      pcb_admin = Role.find_by_name("PCB Admin")
      cc       += pcb_admin.active_users.collect { |u| u.email }
    when 'Pre-Artwork'
      cc.push(design_review.design.input_gate.email)
    end

    cc_list = (cc - to_list).uniq

    @design_review_id = design_review.id
    @message = subject
    
    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )
  end
  
  
  ######################################################################
  #
  # ftp_notification
  #
  # Description:
  # This method generates the mail to notify that the design data has
  # been ftp'd
  #
  # Parameters:
  #   message          - the user making the update
  #   ftp_notification - the record containing the ftp notification details
  #
  # Additional information:
  #
  ######################################################################
  def ftp_notification(message, ftp_notification)

    design_review = ftp_notification.design.get_design_review("Final")

    to_list       = MailerMethods.reviewer_list(design_review)
    cc_list       = (MailerMethods.copy_to(design_review) - to_list).uniq
    subject       = MailerMethods.subject_prefix(ftp_notification.design)      +
                      "Bare Board Files have been transmitted to " +
                      ftp_notification.fab_house.name

    @message = "recipents: " + to_list.join(", ") + "\n" +
               "cc       : " + cc_list.join(", ") + "\n" +
               "\n" + 
               message

    mail( :to       => to_list,
          :subject  => subject,
          :cc       => cc_list
         )

  end
  

  ######################################################################
  #
  # reassign_design_review_to_peer
  #
  # Description:
  # This method generates the mail to a reviewer's peer indicating that
  # the reviewer has assigned the review to the peer.
  #
  # Parameters:
  #   user          - the reviewer's user object
  #   peer          - the peer's user object
  #   designer      - the designer's user object
  #   design_review - the design object
  #   role          - the role object
  #
  ######################################################################
  def reassign_design_review_to_peer(user, 
                                     peer, 
                                     designer,
                                     design_review,
                                     role)

    to_list  = [peer.email]
    cc_list  = ([user.email] + 
                Role.add_role_members(['Manager', 'PCB Input Gate']) -
                to_list).uniq
    subject  = MailerMethods.subject_prefix(design_review.design)     +
                  'You have been assigned to perform the ' +
                  role.display_name                        + 
                  ' review'

    @user_name        = user.name
    @peer_name        = peer.name
    @role_name        = role.display_name
    @design_name      = design_review.design.directory_name
    @design_review_id = design_review.id  

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )

  end


  ######################################################################
  #
  # reassign_design_review_from_peer
  #
  # Description:
  # This method generates the mail to a reviewer's peer indicating that
  # the reviewer has take the review assignment from the review.
  #
  # Parameters:
  #   user          - the reviewer's user object
  #   peer          - the peer's user object
  #   designer      - the designer's user object
  #   design_review - the design object
  #   role          - the role object
  #
  ######################################################################
  def reassign_design_review_from_peer(user,
                                       peer,
                                       designer,
                                       design_review,
                                       role)
    to_list   = [peer.email]
    cc_list  = ([user.email] + 
                Role.add_role_members(['Manager', 'PCB Input Gate']) -
                to_list).uniq  
    subject    = MailerMethods.subject_prefix(design_review.design) + 
                 "The #{role.display_name} review has been reassigned to #{user.name}"

    @user_name        = user.name
    @peer_name        = peer.name
    @role_name        = role.display_name
    @design_name      = design_review.design.directory_name
    @design_review_id = design_review.id 

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )

  end


  ######################################################################
  #
  # notify_design_review_skipped
  #
  # Description:
  # This method generates the mail to notify the PCB Design team
  # that a design review has been skipped.
  #
  # Parameters:
  #   design_review - the design object
  #   user          - the user object, identifies the user who skipped
  #                   the review.
  #
  ######################################################################
  def notify_design_review_skipped(design_review, user)

    to_list   = Role.add_role_members(['Manager', 'PCB Input Gate'])
    cc_list   = ([design_review.design.designer.email] - to_list).uniq
    subject   = MailerMethods.subject_prefix(design_review.design) +
                  "The #{design_review.review_type.name} design review has been skipped"

    @user_name          = user.name
    @design_name        = design_review.design.name
    @design_review_name = design_review.review_type.name

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )

  end


  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.design_review_mail.reassign_to_peer.subject
  #
  def reassign_to_peer
    @greeting = "Hi"

    #mail to: "to@example.org"
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.design_review_mail.reassign_from_peer.subject
  #
  def reassign_from_peer
    @greeting = "Hi"

    #mail to: "to@example.org"
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.design_review_mail.skipped.subject
  #
  def skipped
    @greeting = "Hi"

    #mail to: "to@example.org"
  end

  

end
