########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: location.rb
#
# This file maintains the state for locations.
#
# $Id$
#
########################################################################

class Location < ActiveRecord::Base

  validates_uniqueness_of :name
  validates_presence_of :name
  
  
  has_many :users

end
