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
  
end
