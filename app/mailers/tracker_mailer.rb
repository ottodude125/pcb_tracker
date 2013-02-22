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
  
  ######################################################################
  #
  # part_num_update
  #
  # Description:
  # This method generates a email Jim Light, Jan Kasting, and Patrice Michaels
  # highlighting the PCB/PCBA's whose descriptions were auto updated from teamcenter data
  #
  # Parameters:
  #   part_numbers - the part numbers which were updated
  #   active_designs - current number of active designs
  #   total_part_nums - current number of part numbers associated with those active designs
  #   num_updated - number of those part numbers which got updated descriptions
  #
  ######################################################################  
  
  def part_num_update(part_numbers, active_designs, total_part_nums, num_updated)
    subject = 'Part Number Descriptions Have Been Auto Updated' 

    recipients = ""
    recipients += User.find_by_last_name("Kasting").email
    recipients += User.find_by_last_name("Light").email
    recipients += User.find_by_last_name("Michaels").email
    recipients += "dtg@teradyne.com"
    
    @part_numbers = part_numbers
    @active_designs = active_designs
    @total_part_nums = total_part_nums
    @num_updated_part_nums = num_updated
    
    mail(:to => recipients,
         :subject => subject 
        )
  end
       

 end
