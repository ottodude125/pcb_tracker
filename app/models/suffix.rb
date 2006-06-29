########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: suffix.rb
#
# This file maintains the state for suffixes.
#
# $Id$
#
########################################################################

class Suffix < ActiveRecord::Base

  has_one :audit

  has_many :designs
  
end
