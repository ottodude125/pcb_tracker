########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: change_type.rb
#
# This file maintains the state for change type.
#
# $Id$
#
########################################################################

class ChangeType < ActiveRecord::Base
  
  belongs_to :change_class
  acts_as_list(:scope => :change_class)
  has_many(:change_items, :order => :position)
  
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################
  
  
  # Add the instance to the list of change types
  #
  # :call-seq:
  #   add_to_list() -> boolean
  #
  # Updates the change type list with the instance
  def add_to_list

    # Keep a copy of position to set after the change type is saved, 
    # because the entry will be put at the end of the list.
    position = self.position
    self.save

    if self.errors.empty?
      change_types = ChangeType.find(:all, :order => :position)
      position     = 1 if !position
      change_types.last.insert_at(position)
    end
  end
  
  
  # Update the existing instance in the list of change types
  #
  # :call-seq:
  #   update_list() -> boolean
  #
  # Updates the instance within the change type list
  def update_list(update)
    change_type_update = ChangeType.new(update)
    
    # Update the editable fields and save
    self.name       = change_type_update.name
    self.active     = change_type_update.active
    self.definition = change_type_update.definition
    self.save
    
    if self.errors.empty?
      change_types = ChangeType.find(:all, :order => :position)
      index        = change_types.index(self)
      change_types[index].insert_at(update[:position].to_i)
    end
  end
  
  
end
