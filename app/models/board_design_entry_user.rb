########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: board_design_entry_user.rb
#
# This file maintains the state for board design entry users.
#
# $Id$
#
########################################################################

class BoardDesignEntryUser < ActiveRecord::Base

  belongs_to :board_design_entry
  belongs_to :role
  belongs_to :user
  
  
end
