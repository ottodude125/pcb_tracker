########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: oi_instruction.rb
#
# This file maintains the state for oi_instructions.
#
# $Id$
#
########################################################################

class OiInstruction < ActiveRecord::Base

  belongs_to :design
  belongs_to :oi_category_section
  belongs_to :user
  
  has_many :oi_assignments

end
