########################################################################
#
# Copyright 2012, by Teradyne, Inc., North Reading MA
#
# File: tracker_mailer.rb
#
# This file contains the methods to generate email for the tracker.
#
# $Id$
#
########################################################################

class TrackerMailer < ActionMailer::Base

  default  :from  => Pcbtr::SENDER
  default  :bcc   => []

  ######################################################################
  #
  # broadcast_message
  #
  # Description:
  # This method generates a broadcast mail message to the users in the
  # recipient list.
  #
  # Parameters:
  #   subject    - the mail subject
  #   message    - the mail message
  #   recipients - a list of users to send the message too
  #
  ######################################################################
  
  def broadcast_message(subject,
                        message,
                        recipients,
                        send_to     = 'PCB_Design_Tracker_Users <dtg-noreply@lists.teradyne.com>')

    @message = message

    mail( :to      => send_to,
          :subject => subject,
          :cc      => recipients.uniq,
          :bcc     => []  #override default
        )   
   
  end   

 end
