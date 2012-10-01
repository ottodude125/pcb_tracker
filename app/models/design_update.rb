########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_update.rb
#
# This file maintains the state for design updates
#
# $Id$
#
########################################################################

class DesignUpdate < ActiveRecord::Base

  belongs_to :design
  belongs_to :design_review
  belongs_to :user

end
