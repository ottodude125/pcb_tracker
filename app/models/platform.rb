########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: platform.rb
#
# This file maintains the state for platforms.
#
# $Id$
#
########################################################################

class Platform < ActiveRecord::Base

  has_one :board

  validates_uniqueness_of :name
  validates_presence_of :name

end
