########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: incoming_directory.rb
#
# This file maintains the state for incoming directories.
#
# $Id$
#
########################################################################

class IncomingDirectory < ActiveRecord::Base
  
  has_many :board_design_entries

  validates_uniqueness_of :name
  validates_presence_of :name

end
