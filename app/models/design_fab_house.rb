########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_fab_house.rb
#
# This file maintains the state for board reviewers.
#
# $Id$
#
########################################################################

class DesignFabHouse < ActiveRecord::Base

  belongs_to :design
  belongs_to :fab_house

end
