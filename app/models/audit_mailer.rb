########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: audit_mailer.rb
#
# This file contains the methods to generate email for audit.
#
# $Id$
#
########################################################################

class AuditMailer < ActionMailer::Base

  ######################################################################
  #
  # alert_designer
  #
  # Description:
  # This method generates the mail to the designer that indicates that
  # the peer has completed the audit.
  #
  # Parameters from @params
  #   audit - the audit that is being processed
  #
  ######################################################################
  #
  def alert_designer(audit)
    
    @subject    = "#{audit.design.name}: The peer auditor has completed the audit"

    designer = User.find(audit.design.designer_id)
    peer     = User.find(audit.design.peer_id)
    @recipients = designer.email
    @from       = Pcbtr::SENDER
    @sent_on    = Time.now
    @headers    = {}

    cc_list = [peer.email]
    pcb_manager = Role.find_by_name('Manager')
    for manager in pcb_manager.users
      cc_list << manager.email
    end
    @cc         = cc_list.uniq

    @body       = { :audit    => audit,
                    :designer => designer,
                    :peer     => peer }
    
  end

  ######################################################################
  #
  # alert_peer
  #
  # Description:
  # This method generates the mail to the peer that indicates that
  # the designer has completed the self audit.
  #
  # Parameters from @params
  #   audit - the audit that is being processed
  #
  ######################################################################
  #
  def alert_peer(audit)
    @subject    = "#{audit.design.name}: The designer has completed the self-audit"

    designer = User.find(audit.design.designer_id)
    peer     = User.find(audit.design.peer_id)
    @recipients = peer.email
    @from       = Pcbtr::SENDER
    @sent_on    = Time.now
    @headers    = {}

    cc_list = [designer.email]
    pcb_manager = Role.find_by_name('Manager')
    for manager in pcb_manager.users
      cc_list << manager.email
    end
    @cc         = cc_list.uniq

    @body       = { :audit    => audit,
                    :designer => designer,
                    :peer     => peer }
    
  end
end
