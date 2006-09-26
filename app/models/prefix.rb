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
  has_many :board_design_entries

  validates_uniqueness_of :pcb_mnemonic
  
  
  def pcb_number(number,
                 revision, 
                 numeric_revision)
  
    self.unloaded_prefix + '-' + number + '-' + revision + numeric_revision.to_s
  
  end


  def pcb_a_part_number(number,
                       revision, 
                       numeric_revision)
                       
    rev_table = ('a'..'z').collect
  
    self.loaded_prefix + '-' + number + '-' + rev_table.index(revision).to_s + numeric_revision.to_s
  
  end


end
