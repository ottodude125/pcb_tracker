########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: oi_assignment_comment.rb
#
# This file maintains the state for oi_assignment_comments.
#
# $Id$
#
########################################################################

class OiAssignmentComment < ActiveRecord::Base

  belongs_to :oi_assignment
  belongs_to :user

end
