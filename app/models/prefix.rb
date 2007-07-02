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
  
  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################

  
  ######################################################################
  #
  # get_prefixes
  #
  # Description:
  # This method returns a list of the prefixes
  #
  # Parameters:
  # None
  #
  # Return value:
  # An array of prefix records
  #
  ######################################################################
  #
  def self.get_prefixes
    self.find(:all, :order => 'pcb_mnemonic')
  end
  
  
  ######################################################################
  #
  # get_active_prefixes
  #
  # Description:
  # This method returns a list of the active prefixes
  #
  # Parameters:
  # None
  #
  # Return value:
  # An array of active prefix records
  #
  ######################################################################
  #
  def self.get_active_prefixes
    self.find(:all, :conditions => 'active=1', :order => 'pcb_mnemonic')
  end
  
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################

  
  ######################################################################
  #
  # pcb_number
  #
  # Description:
  # This method returns the pcb number associated with the prefix record.
  #
  # Parameters:
  # number           - the design's board number
  # revision         - the design's alphabetic revision
  # numeric_revision - the design's numeric revision
  #
  # Return value:
  # A string representing the pcb_number.
  #
  ######################################################################
  #
  def pcb_number(number,
                 revision, 
                 numeric_revision)
                 
    self.unloaded_prefix + '-' + number + '-' + revision + numeric_revision.to_s
    
  end


  ######################################################################
  #
  # pcb_a_part_number
  #
  # Description:
  # This method returns the pcba part number associated with the prefix
  # record.
  #
  # Parameters:
  # number           - the design's board number
  # revision         - the design's alphabetic revision
  # numeric_revision - the design's numeric revision
  #
  # Return value:
  # A string representing the pcba part number.
  #
  ######################################################################
  #
  def pcb_a_part_number(number,
                        revision, 
                        numeric_revision)
                       
    rev_table = ('a'..'z').collect
  
    self.loaded_prefix + '-' + number + '-' + rev_table.index(revision).to_s + numeric_revision.to_s
  
  end


end
