########################################################################
#
# Copyright 2012, by Teradyne, Inc., North Reading MA
#
# File: application_mailer.rb
#
# This file contains the methods to generate email for the application.
#
# $Id$
#
########################################################################

class ApplicationMailer < ActionMailer::Base

  default  :from  => Pcbtr::SENDER
  default  :bcc   => []

  ######################################################################
  #
  # snapshot
  #
  # Description:
  # This method generates mail to DTG whenever a user encounters an 
  # application error.
  #
  # Parameters:
  #   exception - the exception record
  #   trace     - to provide the backtrace information
  #   session   - to provide a dump of the session record
  #   params    - the params passed to the action
  #   env       - the http environment
  #
  ######################################################################
  
  def snapshot(exception,
               trace,
               session,
               params,
               env)

    content_type "text/html"
    
    to_list = ['ron.dallas@teradyne.com','joyce.boehm@teradyne.com']
    cc_list = []
    subject = "[Error] exception in #{env['REQUEST_URI']}"

    @exception = exception
    @trace     = trace
    @session   = session
    @params    = params
    @env       = env

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )   

  end
end
