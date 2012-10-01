########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: board_reviewers.rb
#
# This file maintains the state for board reviewers.
#
# $Id$
#
########################################################################

class BoardReviewer < ActiveRecord::Base

  belongs_to :board
  belongs_to :role

end
