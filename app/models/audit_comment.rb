########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: audit_comment.rb
#
# This file maintains the state for audit comments.
#
# $Id$
#
########################################################################

class AuditComment < ActiveRecord::Base

  belongs_to :design_check
  belongs_to :user

end
