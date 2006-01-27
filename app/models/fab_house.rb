########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: prefix.rb
#
# This file maintains the state for fab houses.
#
# $Id$
#
########################################################################

class FabHouse < ActiveRecord::Base

  has_and_belongs_to_many :boards
  has_and_belongs_to_many :designs

  validates_uniqueness_of :name
  validates_presence_of   :name

end
