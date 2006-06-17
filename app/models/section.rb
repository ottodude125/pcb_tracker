########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: section.rb
#
# This file maintains the state for sections.
#
# $Id$
#
########################################################################

class Section < ActiveRecord::Base

  belongs_to :checklist
  
  has_many   :audit_teammates
  has_many   :checks
  has_many   :subsections
  
end
