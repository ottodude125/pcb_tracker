########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_change.rb
#
# This file maintains the state for design change
#
# $Id$
#
########################################################################

class DesignChange < ActiveRecord::Base

  
  belongs_to :design
  
  belongs_to :change_detail
  belongs_to :change_item
  belongs_to :change_type
  belongs_to :change_class

  validates_numericality_of :hours
  
  ##############################################################################
  #
  # Call Backs
  # 
  ##############################################################################
  
  
  # Round hours to the half hour
  before_save :round_hours  
  
  
  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################
  
  
  # Indicate if there are any design changes that have not been approved.
  # 
  # :call-seq:
  #   DesignChange.pending_approval? -> Boolean
  #
  # Returns true if there is one or more design change records that have 
  # not been approved.
  def self.pending_approval?
    self.find(:first, :conditions => '!approved') != nil
  end
  
  
  # Retrieve a list of design changes that have not been approved.
  # 
  # :call-seq:
  #   DesignChange.find_pending -> [DesignChange]
  #
  # Returns an array of design change records sorted by their creation dates.
  def self.find_pending
    self.find(:all, :conditions => '!approved', :order => 'created_at')
  end
  
  
  # Retrieve the number of design changes that have not been approved.
  # 
  # :call-seq:
  #   DesignChange.pending_count -> Integer
  #
  # Returns the number of design change records that have not been approved.
  def self.pending_count
    self.find_pending.size
  end
  
  
  # Retrieve a list of design changes that have been approved.
  # 
  # :call-seq:
  #   DesignChange.find_approved -> [DesignChange]
  #
  # Returns an array of design change records sorted by their creation dates.
  def self.find_approved
    self.find(:all, :conditions => 'approved', :order => 'created_at')
  end
  
  
  # Retrieve the number of design changes that have been approved.
  # 
  # :call-seq:
  #   DesignChange.approved_count -> Integer
  #
  # Returns the number of design change records that have been approved.
  def self.approved_count
    self.find_approved.size
  end
  
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################


  # Indicate the status of the approval for the design change.
  # 
  # :call-seq:
  #   approval_status(User) -> String
  #
  # Returns 'Approved ' if the approvied field is set, otherwise, 'Pending ' is
  # returned.
  def approval_status
    self.approved? ? 'Approved ' : 'Pending '
  end
  
  
  # Update the record to indicate that the change has been approved.
  # 
  # :call-seq:
  #   approve(User) -> Time
  #
  # Updates the design change record, if it has not already been approved, with 
  # the following information
  #
  #   the approver (manager)
  #   the time of the approval
  #   the approved flag is set to true
  #
  # The database is not updated
  def approve(user)
    if !self.approved?
      self.approved    = true
      self.manager     = user
      self.approved_at = Time.now
    end
  end
  
  
  # Indicate if the update is approving the change.
  # 
  # :call-seq:
  #   approving_change?(approving) -> boolean
  #
  # Returns true if the design change will be approved with the update.
  def approving_change?(approving)
    saved_instance = DesignChange.find(self.id) if self.id
    approving && (!saved_instance || !saved_instance.approved?)
  end
  
  
  # Determine if the change class has been set.
  # 
  # :call-seq:
  #   change_class_set?() -> boolean
  #
  # Returns true if the change_class is set for the design change record.
  def change_class_set?
    self.change_class
  end
  
  
  # Determine if the change detail needs to be identified.
  # 
  # :call-seq:
  #   change_detail_required?() -> boolean
  #
  # Returns true if the change_class, change_type, and change_item are set 
  # and no change detail has been specified.
  def change_detail_required?
    self.change_class_set? && 
    self.change_type_set?  &&
    self.change_item_set?  &&
    self.change_item.change_details.size > 0
  end
  
  
  # Determine if the change detail has been set.
  # 
  # :call-seq:
  #   change_detail_set?() -> boolean
  #
  # Returns true if the change_detail is set for the design change record.
  def change_detail_set?
    self.change_detail
  end


  # Determine if the change item needs to be identified.
  # 
  # :call-seq:
  #   change_item_required?() -> boolean
  #
  # Returns true if the change_class and change_type are set and no change item
  #  has been specified.
  def change_item_required?
    self.change_class_set? && 
    self.change_type_set?  &&
    self.change_type.change_items.size > 0
  end


  # Determine if the change item has been set.
  # 
  # :call-seq:
  #   change_item_set?() -> boolean
  #
  # Returns true if the change_item is set for the design change record.
  def change_item_set?
    self.change_item
  end


  # Determine if the change type needs to be identified.
  # 
  # :call-seq:
  #   change_type_required?() -> boolean
  #
  # Returns true if the change_class is set and no change type has been 
  # specified.
  def change_type_required?
    self.change_class_set? && self.change_class.change_types.size > 0
  end
  
  
  # Determine if the change type has been set.
  # 
  # :call-seq:
  #   change_type_set?() -> boolean
  #
  # Returns true if the change_type is set for the design change record.
  def change_type_set?
    self.change_type
  end 
  
  
  # Indicate the designer (submitter) of the change.
  # 
  # :call-seq:
  #   designer() -> User
  #
  # Returns a user record with the designer's name.  If the designer is not 
  # set, the name in the user record is 'Not Assigned'.
  def designer
    if self.designer_id > 0
      User.find(self.designer_id)
    else
      User.new( :first_name => 'Not', :last_name => 'Assigned')
    end
  end


  # Set the designer (submitter) of the change.
  # 
  # :call-seq:
  #   designer=(User) -> User
  #
  # Returns a user record with the designer's name.
  def designer=(user)
    self.designer_id = user.id
  end


  # Indicate the manager (approver) of the change.
  # 
  # :call-seq:
  #   manager() -> User
  #
  # Returns a user record with the manager's name.  If the manager is not 
  # set, the name in the user record is 'Not Assigned'.
  def manager
    if self.manager_id > 0
      User.find(self.manager_id)
    else
      User.new( :first_name => 'Not', :last_name => 'Assigned')
    end
  end
  
  
  # Set the manager (approver) of the change.
  # 
  # :call-seq:
  #   manager=(User) -> User
  #
  # Returns a user record with the manager's name.
  def manager=(user)
    self.manager_id = user.id
  end
  
  
  # Indicate the impact of the schedule change in hours.
  # 
  # :call-seq:
  #   schedule_impact() -> float
  #
  # Returns the number of hours added to, positive result, or removed from, 
  # negative result, the schedule 
   def schedule_impact
    if self.time_added?
      self.hours
    elsif time_removed?
      self.hours * -1.0
    else
      0.0
    end
  end
  
  
  # Indicate if the schedule is impacted by the change.
  # 
  # :call-seq:
  #   schedule_impact?() -> boolean
  #
  # Returns true if hours were either added or removed from the schedule.
  def schedule_impact?
    self.impact != 'None'
  end
  
  
  # Provide a statement indicating the impact of the change.
  # 
  # :call-seq:
  #   schedule_impact_statement() -> String
  #
  # Returns a statement that indicates the impact of the change in English.
  def schedule_impact_statement
    if self.time_added?
      self.hours.to_s + ' hours added to the schedule'
    elsif self.time_removed?
      self.hours.to_s + ' hours removed from the schedule'
    else
      'No impact to the schedule'
    end
  end
  
  
  # Determine if the impact of the change is to add hours from the schedule
  # 
  # :call-seq:
  #   time_added?() -> boolean
  #
  # Returns true if the impact of the change is to add hours from the schedule.
  def time_added?
    self.impact == 'Added'
  end


  # Determine if the impact of the change is to remove hours from the schedule
  # 
  # :call-seq:
  #   time_removed?() -> boolean
  #
  # Returns true if the impact of the change is to remove hours from the schedule.
  def time_removed?
    self.impact == 'Removed'
  end

  
private
 
  validate :do_validate

    def do_validate

    if !self.change_class_set?
      errors.add :change_class_id, 'Change Class selection is required'
    end
    
    if self.change_type_required? && !self.change_type_set?
      errors.add(:change_type_id, 'Change Type selection is required')
    end

    if self.change_item_required? && !self.change_item_set?
      errors.add(:change_item_id, 'Change Item selection is required')
    end
    
    if self.change_detail_required? && !self.change_detail_set?
      errors.add(:change_detail_id, 'Change Detail selection is required')
    end
    
    if self.designer_comment.blank?
      errors.add(:designer_comment, 'Comment is required')
    end
    
    if self.hours > 0.00001  && !self.schedule_impact?
      errors.add(:hours, "If there is no schedule impact, the hours need to be set to '0.0'")
    end
    
  end
  
  
  #
  # before_save call back method
  # 
  # Round the hours field to the nearest half hour.
  #
  def round_hours
    self.hours  = self.hours.round_to_half
    self.impact = 'None' if self.hours == 0.0
  end
  
  
end