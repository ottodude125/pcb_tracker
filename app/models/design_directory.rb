########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_directoryrb
#
# This file maintains the state for design_directories.
#
# $Id$
#
########################################################################

class DesignDirectory < ActiveRecord::Base
  
  has_many :board_design_entries

  validates_uniqueness_of :name
  validates_presence_of :name

end
