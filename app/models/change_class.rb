########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: change_class.rb
#
# This file maintains the state for change_class.
#
# $Id$
#
########################################################################

class ChangeClass < ActiveRecord::Base
  
  acts_as_list
  has_many(:change_types, :order => :position)
  
  validates_presence_of(:name, :message => "can not be blank")
  
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################
  
  
  # Add the instance to the list of change classes
  #
  # :call-seq:
  #   add_to_list() -> boolean
  #
  # Updates the change class list with the instance
  def add_to_list

    # Keep a copy of position to set after the change class is saved, 
    # because the entry will be put at the end of the list.
    position = self.position
    self.save

    if self.errors.empty?
      change_classes = ChangeClass.find(:all, :order => :position)
      position       = 1 if !position 
      change_classes.last.insert_at(position)
    end
  end
  
  
  # Update the existing instance in the list of change classes
  #
  # :call-seq:
  #   update_list() -> boolean
  #
  # Updates the instance within the change class list
  def update_list(update)
    change_class_update = ChangeClass.new(update)
    
    # Update the editable fields and save
    self.name       = change_class_update.name
    self.active     = change_class_update.active
    self.definition = change_class_update.definition
    self.save
    
    if self.errors.empty?
      change_classes = ChangeClass.find(:all, :order => :position)
      index          = change_classes.index(self)
      change_classes[index].insert_at(update[:position].to_i)
    end
  end
  
  
  # Retrieve the active change types.
  #
  # :call-seq:
  #   get_active_change_types() -> [change_type(s)]
  #
  # A list of active change types is returned ordered by position.
  def get_active_change_types
    self.change_types.find(:all, :conditions => { :active => true })
  end
  
  
end
