########################################################################
#
# Copyright 2012, by Teradyne, Inc., North Reading MA
#
# File: board_design_entry_mailer.rb
#
# This file contains the methods to generate email for the board design entry.
#
# $Id$
#
########################################################################

class BoardDesignEntryMailer < ActionMailer::Base

  default  :from  => Pcbtr::SENDER
  default  :bcc   => []

  ######################################################################
  #
  # originator_board_design_entry_deletion
  #
  # Description:
  # This method generates mail to indicate that the peer auditor has entered
  # a comment that the designer needs to respond to.
  #
  # Parameters:
  #   board_design_entry_name - the name of the board design entry
  #   originator              - the user record for the originator
  #
  ######################################################################
  
  def originator_board_design_entry_deletion(board_design_entry_name,
                                             originator)

    to_list  = Role.add_role_members(['PCB Input Gate']).uniq
    cc_list  = ([originator.email] + 
                 Role.add_role_members(['Manager']) -
                 to_list).uniq
    subject  = 'The ' + board_design_entry_name + 
                  ' has been removed from the PCB Engineering Entry list'
                  
    @entry_name = board_design_entry_name
    @originator = originator

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )   
  end
  
  
  ######################################################################
  #
  # board_design_entry_return_to_originator
  #
  # Description:
  # This method generates mail to indicate that the processor returned
  # the board design entry to the originator.
  #
  # Parameters:
  #   board_design_entry - the board design entry
  #   processor          - the user record for the PCB input gate
  #
  ######################################################################
  
  def board_design_entry_return_to_originator(board_design_entry,
                                              processor)

    to_list  = [board_design_entry.user.email]
    cc_list  = (Role.add_role_members(['PCB Input Gate', 'Manager']) - 
                to_list).uniq
    subject  = 'The ' +
                board_design_entry.pcb_number +
                ' design entry has been returned by PCB'
              
    @board_design_entry = board_design_entry
    @processor          = processor

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )   
  end
  
  
  ######################################################################
  #
  # board_design_entry_submission
  #
  # Description:
  # This method generates mail to indicate that a board design entry has 
  # been submitted to PCB Design.
  #
  # Parameters:
  #   board_design_entry - the board design entry
  #
  ######################################################################
  
  def board_design_entry_submission(board_design_entry)

    to_list   = Role.add_role_members(['PCB Input Gate', 'Manager']).uniq
    cc_list   = ([board_design_entry.user.email] - to_list).uniq
    subject   = 'The ' +
                board_design_entry.pcb_number +
                ' design entry has been submitted for entry to PCB Design'
                  

    @board_design_entry = board_design_entry
    @originator         = board_design_entry.user

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )   
  end


end
