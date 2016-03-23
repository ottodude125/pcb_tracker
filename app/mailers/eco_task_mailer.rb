########################################################################
#
# Copyright 2012, by Teradyne, Inc., North Reading MA
#
# File: eco_task_mailer.rb
#
# This file contains the methods to generate email for the eco task.
#
# $Id$
#
########################################################################

class EcoTaskMailer < ActionMailer::Base

  default  :from  => Pcbtr::SENDER
  default  :bcc   => []
  
  ######################################################################
  #
  # eco_task_message
  #
  # Description:
  # This method generates mail for people requiring knowlege about 
  # the creation and updates of ECO CAD tasks.
  #
  # Parameters:
  #   eco_task   - the ECO CAD Task record
  #   subject    - the mail subject
  #
  ######################################################################
  #
  def eco_task_message(eco_task, subject)
    
    to_list  = (Role.lcr_designers.collect { |d| d.email }).uniq
    mg_list  = ["james_light@notes.teradyne.com"]
    cc_list  = (Role.add_role_members(['HCL Manager', 'ECO Admin']) +
               mg_list + 
               eco_task.users.sort_by{ |u| u.last_name }.map(&:email) -
               to_list).uniq
    subject    = "ECO #{eco_task.number}: #{subject}"

    @eco_task = eco_task

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )   
    
  end
  
  
  ######################################################################
  #
  # eco_task_closed_notification
  #
  # Description:
  # This method generates mail to indicate that the ECO Task has been 
  # closed
  #
  # Parameters:
  #   eco_task   - the ECO CAD Task record
  #
  ######################################################################
  #
  def eco_task_closed_notification(eco_task)
    
    to_list   = []
    doc_control = Role.find(:first, :conditions => "name='doc_control'")
    if doc_control
      to_list = (doc_control.users.map(&:email)).uniq
    end
    mg_list  = ["james_light@notes.teradyne.com"]
    cc_list   = (Role.add_role_members(['HCL Manager', 'ECO Admin']) +
                mg_list + 
                (eco_task.users + Role.lcr_designers).map(&:email)).uniq

    subject    = "ECO #{eco_task.number} is complete"
    
    @eco_task = eco_task

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )   

  end
  

end
