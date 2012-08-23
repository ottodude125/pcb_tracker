########################################################################
#
# Copyright 2012, by Teradyne, Inc., North Reading MA
#
# File: document_mailer.rb
#
# This file contains the methods to generate email for the document.
#
# $Id$
#
########################################################################

require 'mailer_methods'
class DocumentMailer < ActionMailer::Base

  default  :from  => Pcbtr::SENDER
  default  :bcc   => []

  ######################################################################
  #
  # attachment_update
  #
  # Description:
  # This method generates mail to indicate that a document has been
  # attached.
  #
  # Parameters:
  #   design_review_document - the design review document record
  #   user
  #   subject_text - added to the standard subject prefix
  #
  ######################################################################
  #
  def attachment_update(design_review_document, user, subject_text)

    design_users = design_review_document.design.get_associated_users()
    to_list = []
    to_list << design_users[:designer].email  if design_users[:designer]
    to_list << design_users[:peer].email      if design_users[:peer]
    to_list << design_users[:pcb_input].email if design_users[:pcb_input]
    to_list += design_users[:reviewers].collect { |reviewer| reviewer.email }
    to_list.uniq!

    cc_list = ( Role.add_role_members(['Manager', 'PCB Input Gate']) -
                to_list).uniq

    subject = MailerMethods.subject_prefix(design_review_document.design) + subject_text

    @document    = design_review_document
    @attached_by = user.name

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )   

  end

end
