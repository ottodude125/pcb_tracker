########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: prefix.rb
#
# This file maintains the state for prefixes.
#
# $Id$
#
########################################################################

class Prefix < ActiveRecord::Base

  has_many :boards

  validates_uniqueness_of :pcb_mnemonic

end
