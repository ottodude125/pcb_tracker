########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: change_detail.rb
#
# This file maintains the state for change detail.
#
# $Id$
#
########################################################################

class ChangeDetail < ActiveRecord::Base
  
  belongs_to :change_item
  acts_as_list(:scope => :change_item)
  
  has_many(:design_changes)
  
  validates_presence_of(:name, :message => "can not be blank")
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################
  
  
  # Add the instance to the list of change details
  #
  # :call-seq:
  #   add_to_list() -> boolean
  #
  # Updates the change detail list with the instance
  def add_to_list

    # Keep a copy of position to set after the change detail is saved, 
    # because the entry will be put at the end of the list.
    position = self.position
    self.save

    if self.errors.empty?
      change_details = self.change_item.change_details.find(:all)
      position       = 1 if !position
      change_details.last.insert_at(position)
    end
  end
  
  
  # Update the existing instance in the list of change details
  #
  # :call-seq:
  #   update_list() -> boolean
  #
  # Updates the instance within the change detail list
  def update_list(update)
    change_detail_update = ChangeDetail.new(update)
    
    # Update the editable fields and save
    self.name       = change_detail_update.name
    self.active     = change_detail_update.active
    self.definition = change_detail_update.definition
    self.save
    
    if self.errors.empty?
      change_details = self.change_item.change_details.find(:all)
      index          = change_details.index(self)
      change_details[index].insert_at(update[:position].to_i)
    end
  end
  
  
end
