########################################################################
#
# Copyright 2012, by Teradyne, Inc., North Reading MA
#
# File: ping_mailer.rb
#
# This file contains the methods to generate email for the ping.
#
# $Id$
#
########################################################################

class PingMailer < ActionMailer::Base
  helper :time
  default  :from  => Pcbtr::SENDER
  default  :bcc   => []

  ######################################################################
  #
  # ping_summary
  #
  # Description:
  # This method generates a summary of the reviewers that were pinged for
  # outstanding reviews.
  #
  # Parameters:
  #   reviewers      - the list of reviewers who were pinged.
  #   active_reviews - the list of design reviews that have outstanding 
  #                    review results.
  #
  ######################################################################
  #
  def ping_summary(reviews, active_reviews)
  

    to_list  = (Role.add_role_members(['Manager', 'PCB Input Gate'])).uniq
    cc_list  = []
    subject  = 'Summary of reviewers who have not approved/waived design reviews'

    @reviews = reviews
    @active_reviews = active_reviews
    
    mail( :to      => "jonathan.katon@teradyne.com",#to_list,
          :subject => subject,
          :cc      => cc_list
        )
  end


  def ping_design_center_summary(design_center_summary)

    to_list  = (Role.add_role_members(['Manager', 'PCB Input Gate'])).uniq
    cc_list  = []
    subject    = 'Summary of design center setttings'

    @summary = design_center_summary

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )
 
  end



  ######################################################################
  #
  # ping_reviewer
  #
  # Description:
  # This method generates a summary of the reviewers that were pinged for
  # outstanding reviews.
  #
  # Parameters:
  #   reviewer - A record for a reviewer with a list of the 
  #              outstanding reviews.
  #
  ######################################################################
  #
  def ping_reviewer(review)

    to_list  = [review[:user].email]
    cc_list  = []
    subject    = 'Your unresolved Design Review(s)'

    @user = review[:user]
    @result = review[:results]

    mail( :to      => "jonathan.katon@teradyne.com",#to_list,
          :subject => subject,
          :cc      => cc_list
        )  
  end

 ######################################################################
  #
  # ping_test
  #
  # Description:
  # This method generates a test message to the specifed e-mail addresses
  #
  # Parameters:
  #   addresses - an array of email addresses
  #
  ######################################################################
  #
  def send_test(addresses)

    to_list  = addresses
    cc_list  = []
    subject    = 'Test from PCB Tracker'

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )  
  end

end
