########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: audit_teammates.rb
#
# This file maintains the state for audit teammates.
#
# $Id$
#
########################################################################

class AuditTeammate < ActiveRecord::Base

  belongs_to :audit
  belongs_to :section
  belongs_to :user
  
  
  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################

  
  ######################################################################
  #
  # new_teammate
  #
  # Description:
  # 
  #
  # Parameters:
  # None
  #
  # Return value:
  # The teammate record that was created
  #
  ######################################################################
  #
  def self.new_teammate(audit_id, section_id, user_id, auditor, save = true)
    
    # Create a new teammate and save it in the database.
    teammate = AuditTeammate.new( :audit_id   => audit_id,
                                  :section_id => section_id,
                                  :user_id    => user_id,
                                  :self       => auditor == :self ? 1 : 0)
    teammate.save if save
    teammate
    
  end


end
