########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: project.rb
#
# This file maintains the state for projects.
#
# $Id$
#
########################################################################

class Project < ActiveRecord::Base

  has_one :board
  
  has_many :board_design_entries

  validates_uniqueness_of :name
  validates_presence_of :name

end
