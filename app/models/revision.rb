########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: revision.rb
#
# This file maintains the state for revisions.
#
# $Id$
#
########################################################################

class Revision < ActiveRecord::Base

  has_one :audit
  
  has_many :board_design_entries
  has_many :designs
  
end
