########################################################################
#
# Copyright 2008, by Teradyne, Inc., North Reading MA
#
# File: eco_task.rb
#
# This file maintains the state for eco tasks.
#
# $Id$
#
########################################################################

class EcoTask < ActiveRecord::Base
  
  
  has_and_belongs_to_many :eco_types
  has_and_belongs_to_many :users
  
  has_many(:eco_comments, :order => 'created_at DESC')
  has_many :eco_documents
  
    
  ##############################################################################
  #
  # Call Backs
  # 
  ##############################################################################
  
  
  # If the user identified a new specification for the task then update the
  # creation time and notify the appropriate people.
  before_save :check_for_new_specification
    
  validate :do_validate
  
  def do_validate
    if number.blank?
      errors.add(:number, 'The ECO Number field can not be blank')
    end
    if pcba_part_number.blank?
      errors.add(:pcba_part_number, "You must provide a PCBA Part Number.")
    end
    if pcb_revision.blank?
      errors.add(:pcb_revision, "You must provide a PCB Revision.")
    end
    if eco_types.size == 0
      errors.add(:eco_types, "You must select at least one ECO Type.")
    end
  end
 

  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


  # Retreive a list of all open ECO Tasks
  #
  # :call-seq:
  #   find_active() ->  []
  #
  # Returns a list of open ECO tasks.
  #
  def self.find_open
    self.find( :all, :conditions => ['closed=?', false], :order => 'created_at')
  end
  
  
  # Retreive a list of all closed ECO Tasks
  #
  # :call-seq:
  #   find_closed() ->  []
  #
  # Returns a list of closed ECO tasks.
  #
  def self.find_closed(start_date, end_date, order='created_at')
    self.find( :all,
               :conditions => ["closed=? AND created_at BETWEEN ? AND ?",
                               true, start_date, end_date+1.day], 
               :order => "#{order}")
  end
  
  
  # Provide a summary of the closed ECO Tasks within the specified range.
  #
  # :call-seq:
  #   eco_task_summary() ->  {}}
  #
  # Returns a hash with the summary totals.
  #
  def self.eco_task_summary(start_date, end_date)
    summary = { :schematic           => 0,
                :assembly_drawing    => 0,
                :fabrication_drawing => 0,
                :cuts_and_jumps      => 0 }
              
    self.find_closed(start_date, end_date).each do |task|
      summary[:schematic]           += 1 if task.schematic?
      summary[:assembly_drawing]    += 1 if task.assembly_drawing? 
      summary[:fabrication_drawing] += 1 if task.fabrication_drawing?
      summary[:cuts_and_jumps]      += 1 if task.cuts_and_jumps?
    end
    
    summary
  end
  
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################
  
  
  # Set the user instance variable
  #
  # :call-seq:
  #   set_user() ->  string
  #
  # Loads the value in the user record into the user instance variable.
  #
  def set_user(user)
    @user = user
  end
  

  # Get the value in the user instance variable
  #
  # :call-seq:
  #   get_user() ->  string
  #
  # Retrieves the value stored in the user instance variable.
  #
  def get_user
    @user
  end
  
  
  # Determine the state of the eco task
  #
  # :call-seq:
  #   state() ->  string
  #
  # Returns a string indicating the state of the ECO Task.
  #
  def state
    if !self.completed?
      'Incomplete'
    elsif self.completed? && !self.closed?
      'Complete'
    else
      'Closed'
    end
  end
  
  
  # Determine if the eco task is for a schematic
  #
  # :call-seq:
  #   schematic?() ->  boolean
  #
  # Returns a boolean value that is true when a schematic
  # eco type is attached to the eco task.
  #
  def schematic?
    self.eco_types.detect { |et| et.name == "Schematic" } != nil
  end
  
  
  # Determine if the eco task is for an assembly drawing
  #
  # :call-seq:
  #   assembly_drawing?() ->  boolean
  #
  # Returns a boolean value that is true when a assembly drawing
  # eco type is attached to the eco task.
  #
  def assembly_drawing?
    self.eco_types.detect { |et| et.name == "Assembly Drawing" } != nil
  end
  
  
  # Determine if the eco task is for an fabrication drawing
  #
  # :call-seq:
  #   fabrication_drawing?() ->  boolean
  #
  # Returns a boolean value that is true when a fabrication drawing
  # eco type is attached to the eco task.
  #
  def fabrication_drawing?
    self.eco_types.detect { |et| et.name == "Fabrication Drawing" } != nil
  end
  
  
  # Determine if the ECO Task specification document is attached
  #
  # :call-seq:
  #   specification_attached?() ->  boolean
  #
  # Returns a boolean value that is true when the specification
  # document is attached.
  #
  def specification_attached?
    self.eco_documents.detect { |d| d.specification? } != nil
  end
  
  
  # Provide the ECO Task's specification document.
  #
  # :call-seq:
  #   specification() ->   eco_document
  #
  # Returns the ECO Task specification document if one exists, otherwise
  # nil is returned
  #
  def specification
    return self.eco_documents.detect { |d| d.specification? }
  end
  
  
  # Remove the ECO Task specification from the database.
  #
  # :call-seq:
  #   destroy_specification() ->   boolean
  #
  # The ECO task specification document is removed from the database.
  #
  def destroy_specification
    return false if !self.specification
    self.specification.destroy
    self.reload
    return true
  end
  
  
  # Determine if the ECO Task specification has been identified
  #
  # :call-seq:
  #   specification_identified?() ->  boolean
  #
  # Returns a boolean value that is true when either a specification
  # document is attached or the document link is not blank.
  #
  def specification_identified?
    self.specification_attached? || !self.document_link.blank?
  end
  
  
  # Determine if there are any documents attached that at not task
  # specifications
  #
  # :call-seq:
  #   attachments?() ->  boolean
  #
  # Returns a boolean value that is true when the task has at least on 
  # non-specification document attached.
  #
  def attachments?
    self.attachments.size > 0
  end
  
  
  # Retrieve a list of documents related to the task excluding the task's
  # specification document.
  #
  # :call-seq:
  #   attachments() -> []
  #
  # Returns a list of ECO Task Documents.
  #
  def attachments
    eco_documents = self.eco_documents.reverse
    eco_documents.delete_if { |d| d.specification? }.reverse
  end
  
  
  # Insert a comment for the task.
  #
  # :call-seq:
  #   add_comment() -> eco_task_comment
  #
  # Creates an ECO Task comment if the comment is not blank.
  #
  def add_comment(eco_task_comment, user)
    if !eco_task_comment.comment.blank?
      eco_task_comment.user_id = user.id
      self.eco_comments << eco_task_comment
    end
    eco_task_comment
  end
  
  
  # Insert user(s) into the task's CC list
  #
  # :call-seq:
  #   add_users_to_cc_list() -> self.save result
  #
  # Updates the ECO Task's CC list.
  #
  def add_users_to_cc_list(user_ids)
    user_ids.each { |id| self.users << User.find(id) }
    self.save
  end
  
  
  # Attach a document to the ECO Task
  #
  # :call-seq:
  #   attach_document() -> eco_document
  #
  # Updates the ECO Task's document list.
  #
  def attach_document(document, 
                      user,
                      specification = false)
    document.user_id       = user.id
    document.specification = specification
    document.eco_task_id   = self.id
    document.save_attachment
    if specification && self.document_link.blank?
      self.started_at = Time.now
      self.save
    end
    document
  end
  
  
  # Retrieve a list of users that can be added to the task's CC list
  #
  # :call-seq:
  #   users_eligible_for_cc_list() -> [user]
  #
  # A list of users that is not already being included in the task's email.
  #
  def users_eligible_for_cc_list
    User.find(:all, :conditions => 'active=1',:order => 'last_name') -
      Role.find_by_name('HCL Manager').active_users                  -
      Role.find_by_name('Manager').active_users                      -
      Role.find_by_name('ECO Admin').active_users                    -
      Role.lcr_designers                                             -
      self.users
  end
  
  
  # Determine if any admin updates have been make to the task.
  #
  # :call-seq:
  #   check_for_admin_update() -> boolean
  #
  # A flag that indicates if an admin update was made to the task.
  #
  def check_for_admin_update(updated_task)
    (self.number           != updated_task.number           ||
     self.pcb_revision     != updated_task.pcb_revision     ||
     self.pcba_part_number != updated_task.pcba_part_number ||
     self.cuts_and_jumps   != updated_task.cuts_and_jumps   ||
     self.screened_at      != updated_task.screened_at      ||
     self.document_link    != updated_task.document_link    ||
     self.directory_name   != updated_task.directory_name   ||
     self.completed        != updated_task.completed        ||
     self.closed           != updated_task.closed           || 
     self.eco_types        != updated_task.eco_types)
  end
  
  
  # Determine if any processor updates have been make to the task.
  #
  # :call-seq:
  #   check_for_processor_update() -> boolean
  #
  # A flag that indicates if a processor update was made to the task.
  #
  def check_for_processor_update(updated_task)
    (self.completed != updated_task.completed)
  end
  
  
private

  #
  # before_save call back method
  # 
  # When the document link is included and it differs from the existing
  # value then updated the created_at field.
  #
  def check_for_new_specification

    stored_task = EcoTask.find(self.id) if self.id
    changed     = self != stored_task   if stored_task

    if self.specification_identified?
      
      if self.id
        # Set the creation time if a new document link as provided
        if (!self.document_link.blank? &&
            (self.document_link != stored_task.document_link) ||
            self.started_at == nil )
          self.started_at = Time.now
        end
      else
        self.started_at = Time.now
      end
    end

    if stored_task 
      if !stored_task.completed? && self.completed?
        self.completed_at = Time.now
        state_change      = 'Task Completed'
      elsif !stored_task.closed? && self.closed?
        self.closed_at = Time.now
        state_change   = 'Task Closed'
      elsif stored_task.closed? && !self.closed?
        state_change = 'Task Reopened'
      elsif stored_task.completed? && !self.completed?
        state_change = 'Task Incomplete - Needs more work/input'
      end
      if state_change
        self.eco_comments << EcoComment.new( :user_id => self.get_user.id, 
                                             :comment => 'STATUS CHANGE: ' + state_change)
      end
    end
    
  end
  
  
end
