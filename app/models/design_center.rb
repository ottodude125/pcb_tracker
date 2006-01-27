########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_center.rb
#
# This file maintains the state for the design centers.
#
# $Id$
#
########################################################################

class DesignCenter < ActiveRecord::Base

  has_many :design_reviews
  has_many :users

  validates_uniqueness_of :name

end
