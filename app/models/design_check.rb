########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_check.rb
#
# This file maintains the state for design checks.
#
# $Id$
#
########################################################################

class DesignCheck < ActiveRecord::Base

  belongs_to :audit
  belongs_to :check
 

  has_many(:audit_comments, :order => 'created_on DESC')
  
  
  ######################################################################
  #
  # peer_auditor
  #
  # Description:
  # Provides a user record for the peer auditor
  #
  # Return value:
  # A user record
  #
  ######################################################################
  #
  def peer_auditor
    if self.auditor_id > 0 
      User.find(self.auditor_id)
    else
      User.new(:first_name => 'Not', :last_name => 'Assigned')
    end
  end
  
  
  ######################################################################
  #
  # self_auditor
  #
  # Description:
  # Provides a user record for the self auditor
  #
  # Return value:
  # A user record
  #
  ######################################################################
  #
  def self_auditor
    if self.designer_id > 0
      User.find(self.designer_id)
    else
      User.new(:first_name => 'Not', :last_name => 'Assigned')
    end
  end
  
end
