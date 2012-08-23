########################################################################
#
# Copyright 2012, by Teradyne, Inc., North Reading MA
#
# File: design_mailer.rb
#
# This file contains the methods to generate email for the design.
#
# $Id$
#
########################################################################

require "mailer_methods"

class DesignMailer < ActionMailer::Base
  default  :from  => Pcbtr::SENDER
  default  :bcc   => []

  ######################################################################
  #
  # design_modifications
  #
  # Description:
  # This method generates the mail indicate that a design has been 
  # modifed
  #
  # Parameters:
  #   user    - the user making the update
  #   cc_list - contains the email addresses for the designer and the 
  #             peer auditor
  #   design  - the record for the design that has been modified   
  #
  ######################################################################
  def design_modification(user,
                          design,
                          comment,
                          cc_list = [])

    if !design.complete?
      design_review = design.get_phase_design_review
    else
      design_review = design.design_reviews.last
    end
    subject     = MailerMethods.subject_prefix(design)                  +
                   'The '                                 +
                   design_review.review_type.name         +
                   ' design review has been modified by ' +
                   user.name

    design  = design_review.design
    to_list = design_review.active_reviewers.collect { |r| r.email }
    to_list << design.designer.email   if design.designer_id  > 0
    to_list << design.peer.email       if design.peer_id      > 0
    to_list << design.input_gate.email if design.pcb_input_id > 0
    to_list.uniq!

    cc_list = ( MailerMethods.copy_to(design_review) + cc_list - to_list ).uniq

    @user             = user
    @comment          = comment
    @design_review_id = design_review.id

    mail(:to      => to_list,
         :subject => subject,
         :cc      => cc_list
         )
  end
  
  ######################################################################
  #
  # reviewer_modification_notification
  #
  # Description:
  # This method generates mail to let both the new review and the old
  # reviewer know that they design review has been reassigned.
  #
  # Parameters:
  #   design_review - the design review record
  #   role          - the role record
  #   old_reviewer  - the user record for the old reviewer
  #   new_reviewer  - the user record for the new reviewer
  #
  ######################################################################
  #
  def reviewer_modification_notification(design_review, 
                                         role, 
                                         old_reviewer, 
                                         new_reviewer,
                                         user)
  
    to_list  = [new_reviewer.email]
    cc_list  = ([old_reviewer.email] + 
                Role.add_role_members(['PCB Input Gate', 'Manager']) -
                to_list).uniq
    subject  = MailerMethods.subject_prefix(design_review.design) + 
               role.display_name                    +
               ' reviewer changed for the '         +
               design_review.review_type.name       +
               ' design review'
    
    @new_reviewer  = new_reviewer.name
    @old_reviewer  = old_reviewer.name
    @design_review = design_review
    @user          = user
    @role          = role

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
          )
  end

  ######################################################################
  #
  # review_role_creation_notification
  #
  # Description:
  # This method generates mail to indicate that a review role has been
  # added to a review
  #
  # Parameters:
  #   designer_review - the design review
  #   role            - the role added
  #   reviewer        - the person assigned to the review
  ######################################################################

  def review_role_creation_notification(
      design,
      role,
      reviewer )

    to_list  = [reviewer.email,'dtg@teradyne.com']
    cc_list  = []
    subject  = MailerMethods.subject_prefix(design) +
               role.display_name      +
               ' added'

    @design    = design
    @role      = role
    @reviewer  = reviewer

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )   
    
  end

end
