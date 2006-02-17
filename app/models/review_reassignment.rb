########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: review_reassignment.rb
#
# This file contains the methods to generate email for reviewer reassignment.
#
# $Id$
#
########################################################################

class ReviewReassignment < ActionMailer::Base


  ######################################################################
  #
  # reassign_to_peer
  #
  # Description:
  # This method generates the mail to a reviewer's peer indicating that
  # the reviewer has assigned the review to the peer.
  #
  # Parameters from @params
  #   user     - the reviewer's user object
  #   peer     - the peer's user object
  #   designer - the designer's user object
  #   design   - the design object
  #   role     - the role object
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def reassign_to_peer( user, peer, designer, design, role )

    @subject    = "#{design.name}: You have been assigned to perform the #{role.name} review"
    @recipients = peer.email
    @from       = Pcbtr::SENDER
    @sent_on    = Time.now
    @headers    = {}
    
    peers     = role.users.sort_by { |u| user.last_name }
    peer_list = Array.new
    for reviewer_peer in peers
      peer_list << reviewer_peer.email
    end

    cc_list = peer_list + [designer.email]
    cc_list << Pcbtr::EAVESDROP
    cc_list.delete_if { |recipient| recipient == peer.email }

    @cc         = cc_list.uniq

    @body['user_name'] = user.name
    @body['peer_name'] = peer.name
    @body['role_name'] = role.name
    @body['design_name'] = design.name  

  end


  ######################################################################
  #
  # reassign_from_peer
  #
  # Description:
  # This method generates the mail to a reviewer's peer indicating that
  # the reviewer has take the review assignment from the review.
  #
  # Parameters from @params
  #   user     - the reviewer's user object
  #   peer     - the peer's user object
  #   designer - the designer's user object
  #   design   - the design object
  #   role     - the role object
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def reassign_from_peer( user, peer, designer, design, role )

    @subject    = "#{design.name}: The #{role.name} review has been reassigned to #{user.name}"
    @recipients = peer.email
    @from       = Pcbtr::SENDER
    @sent_on    = Time.now
    @headers    = {}

    peers     = role.users.sort_by { |u| user.last_name }
    peer_list = Array.new
    for reviewer_peer in peers
      peer_list << reviewer_peer.email
    end

    cc_list = peer_list + [designer.email]
    cc_list << Pcbtr::EAVESDROP
    cc_list.delete_if { |recipient| recipient == peer.email }

    @cc         = cc_list.uniq

    @body['user_name'] = user.name
    @body['peer_name'] = peer.name
    @body['role_name'] = role.name
    @body['design_name'] = design.name  

  end


end
