########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: change_item.rb
#
# This file maintains the state for change item.
#
# $Id$
#
########################################################################

class ChangeItem < ActiveRecord::Base
  
  belongs_to :change_type
  acts_as_list(:scope => :change_type)
  
  has_many(:change_details, :order => :position)
  
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################
  
  
  # Add the instance to the list of change items
  #
  # :call-seq:
  #   add_to_list() -> boolean
  #
  # Updates the change item list with the instance
  def add_to_list

    # Keep a copy of position to set after the change itme is saved, 
    # because the entry will be put at the end of the list.
    position = self.position
    self.save
    if self.errors.empty?
      change_items = self.change_type.change_items.find(:all)
      position     = 1 if !position
      change_items.last.insert_at(position)
    end
  end
  
  
  # Update the existing instance in the list of change items
  #
  # :call-seq:
  #   update_list() -> boolean
  #
  # Updates the instance within the change item list
  def update_list(update)
    change_item_update = ChangeItem.new(update)
    
    # Update the editable fields and save
    self.name       = change_item_update.name
    self.active     = change_item_update.active
    self.definition = change_item_update.definition
    self.save
    
    if self.errors.empty?
      change_items = self.change_type.change_items.find(:all)
      index        = change_items.index(self)
      change_items[index].insert_at(update[:position].to_i)
    end
  end
  
  
end
