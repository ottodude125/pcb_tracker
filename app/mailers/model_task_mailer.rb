########################################################################
#
# Copyright 2012, by Teradyne, Inc., North Reading MA
#
# File: model_task_mailer.rb
#
# This file contains the methods to generate email for the model task.
#
# $Id$
#
########################################################################

class ModelTaskMailer < ActionMailer::Base

  default  :from  => Pcbtr::SENDER
  default  :bcc   => []
  
  ######################################################################
  #
  # model_task_message
  #
  # Description:
  # This method generates mail for people requiring knowledge about 
  # the creation and updates of Model tasks.
  #
  # Parameters:
  #   model_task   - the Model Task record
  #   subject    - the mail subject
  #   new_task   - flag if this is a newly created task
  #
  ######################################################################
  #
  def model_task_message(model_task, subject, new_task=false)
    #puts "\n\n"
    #to_list  = (Role.lcr_designers.collect { |d| d.email }).uniq
    #puts to_list
    #puts "monkey"
    #cc_list  = (Role.add_role_members(['Manager', 'HCL Manager', 'ECO Admin']) -
    #           to_list).uniq

    @model_task = model_task

    to_list  = (Role.add_role_members(['Modeler'])  ).uniq 
    mg_list  = new_task ? Role.add_role_members(['Manager']).uniq : []
    cc_list  = (Role.add_role_members(['Modeler Admin']) +
                mg_list -
                to_list ).uniq
    
    subject    = "Model #{model_task.request_number}: #{subject}"
    
    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )   
    
  end

end
