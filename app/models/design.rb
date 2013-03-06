########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design.rb
#
# This file maintains the state for designs
#
# $Id$
#
########################################################################

class Design < ActiveRecord::Base

  belongs_to :board
  belongs_to :design_center
  belongs_to :priority
  belongs_to :part_number
  belongs_to :revision

  has_and_belongs_to_many :fab_houses

  has_many :design_changes,            :order => 'approved, created_at ASC'
  has_many :design_review_documents
  has_many :design_reviews
  has_many :design_updates
  has_many :ipd_posts
  has_many :oi_instructions
  #has_many :part_numbers
  has_many :part_nums

  has_one   :audit
  has_one   :board_design_entry
  has_one   :ftp_notification
  
  
  NOT_SET  = 'Not Set'
  COMPLETE = 255
  COMPLETED_RESULTS = ['APPROVED', 'WAIVED']


  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


  def self.http_object
    @@h = @@h ||= Net::HTTP::new("boarddev.teradyne.com")
    @@h
  end


  # Generates a list of active designs with information that is used to load
  # BOMs to TeamCenter by a DTG process.  This is called by an outside 
  # script.
  #
  # :call-seq:
  #   bom_upload_data() -> string
  #
  # Outputs the BOM Upload Data.
  #
  def self.bom_upload_data
    
    active_designs = self.get_active_designs
    
    active_designs.each do |design|
      
      current_design_review = design.get_phase_design_review
      
      hweng_role  = Role.find( :first, :conditions => "name='HWENG'")
      hweng       = current_design_review.role_reviewer(hweng_role)
      hweng_email = hweng ? hweng.email : "** NOT SET **"
      
      planning_role = Role.find( :first, :conditions => "name='Planning'")
      planner       = design.get_role_reviewer(planning_role)
      planner_email = planner ? planner.email : ''
      planner_name  = planner ? planner.name  : ''
      
      pcb_path = '/hwnet/' + 
                 design.design_center.pcb_path + '/' +
                 design.directory_name + '/'

      brd_dsn_entry = BoardDesignEntry.find( :first,
        :conditions => "design_id='#{design.id}'")

      eng_path = "Not Set"
      if brd_dsn_entry
        eng_path = # '/hwnet/' +
          brd_dsn_entry.design_directory_name + '/' +
          design.directory_name + '/'
      end

      PartNum.get_design_pcba_part_numbers(design.id).each do |pcba|
        puts(pcba.name_string                             + '|' +
            design.pcb_display                            + '|' +
            design.phase.name                             + '|' +
            current_design_review.review_status.name      + '|' +
            planner_email                                 + '|' +
            hweng_email                                   + '|' +
            design.designer.email                         + '|' +
            pcb_path                                      + '|' +
            eng_path                                      + '|')
      end
    end

  end

  
  ######################################################################
  #
  # get_unique_pcb_numbers
  #
  # Description:
  # This method provides a list of sorted, unique PCB part numbers.
  # Used for test
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of unique PCB part numbers represented as strings.
  #
  ######################################################################
  #
  def self.get_unique_pcb_numbers
    
    designs =Design.find(:all)
    designs.delete_if { |d| d.pcb_number == nil }
    #designs.collect { |design| design.part_number.pcb_unique_number }.uniq.sort
    designs.collect { |design|
      pnum = PartNum.get_design_pcb_part_number(design.id)
      pnum.uniq_name if pnum #handle nil
    }.compact.uniq.sort
  end
  
  
  ######################################################################
  #
  # find_all_active
  #
  # Description:
  # This method retrieves a list of all active designs.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of active designs.
  #
  ######################################################################
  #
  def self.find_all_active
    Design.find(:all, :conditions => "phase_id != #{COMPLETE}")
  end
  
  
  ######################################################################
  #
  # get_active_designs
  #
  # Description:
  # Retrieves a list of all active designs.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of active designs.
  #
  ######################################################################
  #
  def self.get_active_designs 
    self.find(:all,
              :conditions => "phase_id!='#{Design::COMPLETE}'",
              :order      => 'created_on')
  end
  
  def is_active?
    self.phase_id != Design::COMPLETE
  end
  ######################################################################
  #
  # get_active_designs_owned_by
  #
  # Description:
  # Retrieves a list of all active designs for a given designer.
  #
  # Parameters:
  # designer - the User record for the desinger.
  #
  # Return value:
  # A list of active designs assigned to the designer.
  #
  ######################################################################
  #
   def self.get_active_designs_owned_by(designer)

    pre_art_phase_id = ReviewType.get_pre_artwork.id

    designs  = Design.find(:all,
                           :conditions => "designer_id='#{designer.id}' " +
                                      "AND phase_id!='#{Design::COMPLETE}' " +
                                      "", #AND phase_id!='#{pre_art_phase_id}'",
                           :order      => 'created_on') +
               Design.find(:all,
                           :conditions => "pcb_input_id='#{designer.id}' AND phase_id='#{pre_art_phase_id}'",
                           :order      => 'created_on')

    designs.uniq.sort_by { |dr| dr.priority.value }

    # Load the design checks for statistics.
    designs.each { |design| design.audit.get_design_checks if design.audit.is_peer_audit? }

  end



  def surfboards_path
    "/surfboards/#{self.design_center.pcb_path}/#{self.directory_name}/"
  end
   
  # Provide the number of approved hours of adjustment that have been
  # applied to the schedule.
  #
  # :call-seq:
  #   total_approved_schedule_impact_hours() -> float
  #
  def total_approved_schedule_impact_hours
    delta  = 0.0
    self.design_changes.each do |design_change|
      if design_change.approved?
        delta += design_change.schedule_impact
      end
    end
    delta
   end
   
   
  # Provide the number of pending hours of adjustment that have been
  # applied to the schedule.
  #
  # :call-seq:
  #   total_pending_schedule_impact_hours() -> float
  #
   def total_pending_schedule_impact_hours
    delta  = 0.0
    self.design_changes.each do |design_change|
      if !design_change.approved?
        delta += design_change.schedule_impact
      end
    end
    delta
   end
   
   
  # The number of approved changes that have been applied to the
  # original schedule.
  #
  # :call-seq:
  #   total_approved_schedule_change_count() -> integer
  #
   def total_approved_schedule_change_count
     self.design_changes.count(:conditions => "approved=true")
   end


  # Indicate if there are any approved schedule changes for the design
  #
  # :call-seq:
  #   total_approved_schedule_changes?() -> boolean
  #
   def total_approved_schedule_changes?
     self.total_approved_schedule_change_count > 0
   end

   
  # The number of pending changes that have been applied to the
  # original schedule.
  #
  # :call-seq:
  #   total_pending_schedule_change_count() -> integer
  #
   def total_pending_schedule_change_count
     self.design_changes.count(:conditions => "approved=false")
   end

  
  # Indicate if there are any pending schedule changes for the design
  #
  # :call-seq:
  #   total_pending_schedule_changes?() -> boolean
  #
   def total_pending_schedule_changes?
     self.total_pending_schedule_change_count > 0
   end
  

  ######################################################################
  #
  # assignment_count
  #
  # Description:
  # Computes the number of outsource instruction assignments for the 
  # design.
  #
  # Parameters:
  # None
  #
  # Return value:
  # An integer representing the number of outsource instruction assignments
  # assigned for the design.
  #
  ######################################################################
  #
  def assignment_count
    total = 0
    self.oi_instructions.each { |inst| total += inst.assignment_count }
    total
  end
  
  
  ######################################################################
  #
  # completed_assignment_count
  #
  # Description:
  # Computes the number of completed outsource instruction assignments 
  # for the design.
  #
  # Parameters:
  # None
  #
  # Return value:
  # An integer representing the number of completed outsource 
  # instruction assignments assigned for the design.
  #
  ######################################################################
  #
  def completed_assignment_count
    total = 0
    self.oi_instructions.each { |inst| total += inst.completed_assignment_count }
    total
  end
  
  
  ######################################################################
  #
  # report_card_count
  #
  # Description:
  # Computes the number of completed outsource instruction assignment 
  # report cards for the design.
  #
  # Parameters:
  # None
  #
  # Return value:
  # An integer representing the number of completed outsource 
  # instruction assignment report cards assigned for the design.
  #
  ######################################################################
  #
  def report_card_count
    total = 0
    self.oi_instructions.each { |inst| total += inst.report_card_count }
    total
  end
  
  
  ######################################################################
  #
  # assignments_complete?
  #
  # Description:
  # Reports on the completion status of the outsource instruction 
  # assignments for the design.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if all of the outsource instructions assignments are complete.
  # Otherwise, false.
  #
  ######################################################################
  #
  def assignments_complete?
    self.assignment_count == self.completed_assignment_count
  end


  ######################################################################
  #
  # report_cards_complete?
  #
  # Description:
  # Reports on the completion status of the outsource instruction 
  # assignment report cards for the design.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if all of the outsource instructions assignment report cards 
  # are complete.  Otherwise, false.
  #
  ######################################################################
  #
  def report_cards_complete?
    self.assignment_count == self.report_card_count
  end
  
  
  ######################################################################
  #
  # work_assignments_complete
  #
  # Description:
  # This method determines if all of the work assignment have been
  # completed and evaluated by the designer.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A boolean that indicates that all work assignments have been
  # completed and have been evaluated when TRUE.
  #
  ######################################################################
  #
  def work_assignments_complete?
    ( self.assignments_complete? && self.report_cards_complete? )
  end


  ######################################################################
  #
  # comments_by_role
  #
  # Description:
  # This method retrieves the design review comments for the roles 
  # identified in the role_list parameter.
  #
  # Parameters:
  # role_list - a list of role names
  #
  # Return value:
  # A list of design review comments associated with the design review 
  # and the roles identified in the role_list.
  #
  ######################################################################
  #
  def comments_by_role(role_list)

    role_names = (role_list.class == String) ? [role_list] : role_list
    
    comment_list = []
    self.design_reviews.each { |dr| comment_list += dr.comments_by_role(role_names) }
    
    comment_list.sort_by { |c| c.created_on }.reverse
  
  end


  ######################################################################
  #
  # get_associated_users_by_role
  #
  # Description:
  # This method returns a hash of all of the people interested in 
  # the design.  The user records are access by the role names.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A hash of user records accessed by their role names.
  #
  ######################################################################
  #
  def get_associated_users_by_role

    users = {}
    
    users[:designer]  = self.designer   if (self.designer_id  > 0)
    users[:peer]      = self.peer       if (self.peer_id      > 0)
    users[:pcb_input] = self.input_gate if (self.pcb_input_id > 0)

    role_names = ['Hardware Engineering Manager', 'Program Manager']
    
    role_names.each do |role_name|
      role     = Role.find_by_name(role_name)
      reviewer = self.board.board_reviewers.detect { |br| br.role_id == role.id }

      if reviewer && reviewer.reviewer_id > 0
        users[role_name] = User.find(reviewer.reviewer_id)
      else
        users[role_name] = User.new(:first_name => 'Not', :last_name => 'Set')
      end
    end
    
    reviewer_list = self.all_reviewers
    self.design_reviews.each do |design_review|
      design_review.design_review_results.each do |review_result|
        role = Role.find(review_result.role_id)
        if not users[role.name]
          users[role.name] = User.find review_result.reviewer_id
        end
      end
    end
    
    return users
    
  end
  
  # Provide lists of users for mailing list display
  #
  # :call-seq:
  #   mail_lists([design_review_id) -> {return hash}
  #
  # An hash of containing 3 arrays of users
  #   :reviewers  => {:name, :group, :last_name, :id }
  #   :copied     => [users]
  #   :not_copied => [users]
  #
  def get_mail_lists(design_review_id="")

    if  design_review_id.blank?
     # Get a list of all design reviews
      design_reviews = DesignReview.find_all_by_design_id(self.id)
    else
      # Get the specified design review
      design_reviews = [ DesignReview.find(design_review_id) ]
    end

    # get the reviewer names, their functions and sort the list by the
    # reviewer's last name.
    reviewers_data = []
    reviewers = []

    design_reviews.each do |dr|
      dr.design_review_results.each do |review_result|
         reviewers_data.push({ :name      => review_result.reviewer.name,
                               :group     => review_result.role.name,
                               :last_name => review_result.reviewer.last_name,
                               :id        => review_result.reviewer_id
                             })
         user = User.find(review_result.reviewer_id)
         reviewers << user
      end
    end
    reviewers.uniq

    #create the cc and not on cc lists
    users_on_cc_list = []
    #  start with all design users
    self.board.users.uniq.each do |user|
      users_on_cc_list << user unless reviewers.include?(user)
    end

    # Get all of the users, remove the reviewer names, and add the full name.
    users = User.find(:all,
      :conditions => 'active=1')

    users_copied     = []
    users_not_copied = []
    # see if each user is associated with the design
    # if so, they are on the cc list
    # otherwise, they are on the not_copied list
    users.each do |user|
      next if user.id == self.designer_id
      if users_on_cc_list.include?(user)
        users_copied.push(user)
      else
        users_not_copied.push(user) unless reviewers.include?(user)
      end
    end
    { :reviewers  => reviewers_data.uniq.sort_by   { |r| r[:last_name] },
      :copied     => users_on_cc_list.sort_by { |u| u.last_name },
      :not_copied => users_not_copied.sort_by { |u| u.last_name }
    }
  end

  ######################################################################
  #
  # have_assignments
  #
  # Description:
  # This method determines if the user has any outsource instruction
  # assignments.
  #
  # Parameters:
  # user_id - to identify the user 
  #
  # Return value:
  # TRUE if the user has any outsource instruction assignments
  #
  ######################################################################
  #
  def have_assignments(user_id)
    
    self.oi_instructions.each do |instruction|
      if OiAssignment.find_by_oi_instruction_id_and_user_id(instruction.id, user_id) != nil
        return true
      end
    end
    
    return false
    
  end
  
  
  ######################################################################
  #
  # my_assignments
  #
  # Description:
  # This method retrieves the user's outsource instruction assignments
  #
  # Parameters:
  # user_id - to identify the user 
  #
  # Return value:
  # A list of outsource instruction assignments
  #
  ######################################################################
  #
  def my_assignments(user_id)
  
    my_assignments  = []    
    self.oi_instructions.each do |instruction|
      instruction.oi_assignments.each do |assignment| 
        my_assignments << assignment if assignment.user_id == user_id 
      end
    end
    
    my_assignments
  
  end


  ######################################################################
  #
  # all_assignments
  #
  # Description:
  # This method retrieves all of the design's outsource instruction 
  # assignments.  If the category_id is provided then the list is 
  # limited to the outsource instruction assignments for the category.
  #
  # Parameters:
  # category_id - to identify the category to provide outsource 
  #               instruction assignments when greater than 0
  #
  # Return value:
  # A list of outsource instruction assignments
  #
  ######################################################################
  #
  def all_assignments(category_id = 0)

    assignments  = []
    self.oi_instructions.each do |instruction|
      next if category_id > 0 && category_id != instruction.oi_category_section.oi_category_id
      instruction.oi_assignments.each { |assignment| assignments << assignment }
    end

    assignments

  end
  
  
  
  ######################################################################
  #
  # get_associated_users
  #
  # Description:
  # This method returns a hash of all of the people interested in 
  # the design.  The user records are access by the role names.
  # The reviewers are accessed by the key :reviewers.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A hash of user records accessed by their role names.
  #
  ######################################################################
  #
  def get_associated_users
  
    users = {:designer  => nil,
             :pcb_input => nil,
             :peer      => nil,
             :reviewers => []}
             
    users[:designer]  = User.find(self.designer_id)  if (self.designer_id  > 0)
    users[:peer]      = User.find(self.peer_id)      if (self.peer_id      > 0)
    users[:pcb_input] = User.find(self.pcb_input_id) if (self.pcb_input_id > 0)
    
    reviewer_list = {}
    design_reviews = self.design_reviews
    design_reviews.each do |design_review|
      design_review.design_review_results.each do |design_review_result|
        reviewer_id = design_review_result.reviewer_id
        if reviewer_list[reviewer_id] == nil
          reviewer_list[reviewer_id] = User.find(reviewer_id)
          users[:reviewers] << reviewer_list[reviewer_id]
        end
      end
    end
             
    return users 
  end
  
  
  ######################################################################
  #
  # designer
  #
  # Description:
  # This method returns the user record for the designer who is 
  # listed for the design.  If there is no listed designer, a user
  # record is created and the name is set to 'Not Assigned'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A User record for the designer.
  #
  ######################################################################
  #
  def designer
  
    if self.designer_id > 0
      User.find(self.designer_id)
    else
      User.new(:first_name => 'Not', :last_name => 'Assigned')
    end
  
  end
  
  
  ######################################################################
  #
  # complete?
  #
  # Description:
  # This method reports on the completion of a design
  #
  # Parameters:
  # None
  #
  # Return value:
  # True if the design is completed, otherwise False.
  #
  ######################################################################
  #
  def complete?
    self.phase_id == COMPLETE
  end
  
  
  ######################################################################
  #
  # in_phase?
  #
  # Description:
  # This method reports if the design is in the phase identified
  # by the review type.
  #
  # Parameters:
  # review_type - a review type record that represents the review
  #               type to check against.
  #
  # Return value:
  # True if the design is in the same phase as the review type,
  # otherwise False.
  #
  ######################################################################
  #
  def in_phase?(review_type)
    self.phase_id == review_type.id
  end


  ######################################################################
  #
  # phase
  #
  # Description:
  # This method returns the review type record that represents the phase
  # that the design is in.  If there is no listed designer, a user
  # record is created and the name is set to 'Not Assigned'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A User record for the designer.
  #
  ######################################################################
  #
  def phase
  
    if self.phase_id == COMPLETE
      ReviewType.new(:name => 'Complete')
    elsif self.phase_id > 0
      ReviewType.find(self.phase_id)
    else
      ReviewType.new(:name => 'Not Started')
    end
  
  end
  
  
  ######################################################################
  #
  # get_phase_design_review
  #
  # Description:
  # This method returns the design review identified by the phase_id
  #
  # Return value:
  # A design review record if the design is not in the complete phase.
  # Otherwise, nil is returned.
  #
  ######################################################################
  #
  def get_phase_design_review
    self.design_reviews.detect { |dr| self.phase_id == dr.review_type_id }
  end


  ######################################################################
  #
  # name
  #
  # Description:
  # This method returns the design name.
  #
  # Return value:
  # A string that identifies the design.
  #
  ######################################################################
  #
  def name
    #logger.info("#################################")
    #logger.info("#################################")
    #logger.info("Design.name called")
    #logger.info("#################################")
    #logger.info("#################################")
    self.pcb_display
  end
  
  
  ######################################################################
  #
  # priority_name
  #
  # Description:
  # This method returns the priority name.
  #
  # Return value:
  # A string that identifies the priority.
  #
  ######################################################################
  #
  def priority_name
    self.priority_id > 0 ? self.priority.name : NOT_SET
  end


  ######################################################################
  #
  # peer
  #
  # Description:
  # This method returns the user record for the peer who is 
  # listed for the design.  If there is no listed peer, a user
  # record is created and the name is set to 'Not Assigned'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A User record for the peer.
  #
  ######################################################################
  #
  def peer
  
    if self.peer_id > 0
      User.find(self.peer_id)
    else
      User.new(:first_name => 'Not', :last_name => 'Assigned')
    end
  
  end
  
  
  ######################################################################
  #
  # input_gate
  #
  # Description:
  # This method returns the user record for the input_gate who is 
  # listed for the design.  If there is no listed input_gate, a user
  # record is created and the name is set to 'Not Assigned'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A User record for the input_gate.
  #
  ######################################################################
  #
  def input_gate
  
    if self.pcb_input_id > 0
      User.find(self.pcb_input_id)
    else
      User.new(:first_name => 'Not', :last_name => 'Assigned')
    end
    
  end
  
  
  ######################################################################
  #
  # all_reviewers
  #
  # Description:
  # This method returns a list of all of the reviewers responsible
  # for the various reviews on the board.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of unique User records.  One for each of the reviewers.
  #
  ######################################################################
  #
  def all_reviewers(sorted = true)
  
    reviewer_list = []
    self.design_reviews.each do |design_review|
      # design_review.reviewers will not add duplicate
      # records to reviewer_list
      reviewer_list = design_review.reviewers(reviewer_list)
    end

    reviewer_list.sort_by { |reviewer| reviewer.last_name } if sorted
    
  end
  
  
  ######################################################################
  #
  # date_code?
  #
  # Description:
  # This method looks at the design_type and returns TRUE if it is
  # set to 'Date Code'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the design is a 'Date Code' design, FALSE otherwise.
  #
  ######################################################################
  #
  def date_code?
    self.design_type == 'Date Code'
  end
  
  
  ######################################################################
  #
  # dot_rev?
  #
  # Description:
  # This method looks at the design_type and returns TRUE if it is
  # set to 'Dot Rev'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the design is a 'Dot Rev' design, FALSE otherwise.
  #
  ######################################################################
  #
  def dot_rev?
    self.design_type == 'Dot Rev'
  end
  
  
  ######################################################################
  #
  # new?
  #
  # Description:
  # This method looks at the design_type and returns TRUE if it is
  # set to 'New'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the design is a 'New' design, FALSE otherwise.
  #
  ######################################################################
  #
  def new?
    self.design_type == 'New'
  end
  
  
  ######################################################################
  #
  # belongs_to
  #
  # Description:
  # This method looks at the entity (section, subsection, or check)
  # to determine if it belongs to the design.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the entity belongs to the design, FALSE otherwise.
  #
  ######################################################################
  #
  def belongs_to(entity)
      ((entity.full_review?     && self.new?)       ||
       (entity.date_code_check? && self.date_code?) ||
       (entity.dot_rev_check?   && self.dot_rev?))
  end
  
  
  ######################################################################
  #
  # increment_review
  #
  # Description:
  # This method sets the phase of the design to the next review.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def increment_review

    self.phase_id = self.next_review
    self.save
  
  end
  
  
  ######################################################################
  #
  # next_review
  #
  # Description:
  # This method determines the next review in the review cycle.
  #
  # Parameters:
  # None
  #
  # Return value:
  # The review type id of the next review in the review cycle.
  #
  ######################################################################
  #
  def next_review

    current_review_type = ReviewType.find(self.phase_id)
    review_types = ReviewType.find(:all,
                                   :conditions => "active = 1 AND " +
                                                  "sort_order > '#{current_review_type.sort_order}'", 
                                   :order      => "sort_order")

    phase_id    = COMPLETE
    next_review = nil
    review_types.each { |rt|
      next_review = self.design_reviews.detect { |dr| dr.review_type.id == rt.id }
      break if !next_review || next_review.review_status.name != "Review Skipped"
    }

    if next_review && next_review.review_status.name != "Review Skipped"
      phase_id = next_review.review_type_id
    end 
    
    phase_id 
  
  end
  
  
  ######################################################################
  #
  # setup_design_reviews
  #
  # Description:
  # This method sets up the design reviews.
  #
  # Parameters:
  # review_types_list - a hash of flags accessed by review type name
  #                     that indicate if the review type is active
  # board_team_list   - a collection of users that are on the board team
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def setup_design_reviews(review_types_list, 
                           board_team_list)
                           
    if review_types_list.size == 1
      in_review      = ReviewStatus.find_by_name('In Review')
      review_types   = ReviewType.get_active_review_types

      #Go through each of the review types and setup a review.
      review_types_list.each do |review, active|
  
        review_type = review_types.detect { |rt| rt.name == review }
        
        design_review = DesignReview.new(:review_type_id => review_type.id,  
                                         :creator_id     => self.created_by,  
                                         :priority_id    => self.priority_id)  
        
        design_review.review_status_id = in_review.id      
        self.design_reviews << design_review
      end
          
    else      
      not_started    = ReviewStatus.find_by_name('Not Started')
      review_skipped = ReviewStatus.find_by_name('Review Skipped')
      review_types   = ReviewType.get_active_review_types
  
      # Find the ECN Manager for the design
      ecn_manager_role = Role.find_by_name("ECN")
      
      ecn_manager = board_team_list.detect do |x|
        x.role_id == ecn_manager_role.id
      end
  
      #Go through each of the review types and setup a review.
      review_types_list.each do |review, active|
  
        review_type = review_types.detect { |rt| rt.name == review }
        
        design_review = DesignReview.new(:review_type_id => review_type.id,  
                                         :creator_id     => self.created_by,  
                                         :priority_id    => self.priority_id)  
        
        design_review.review_status_id = active == '1' ? not_started.id : review_skipped.id      
        
        if review_type.name == "Pre-Artwork"
          design_review.designer_id = self.pcb_input_id
        elsif review_type.name == 'Release'
          design_review.designer_id = ecn_manager.user_id
        end
        
        self.design_reviews << design_review
  
        # Create Design Review Result entries
        design_review.add_reviewers(board_team_list)
  
      end
    end
  end
  
  
  ######################################################################
  #
  # record_update
  #
  # Description:
  # This method stores the design update
  #
  # Parameters:
  # what      - the attribute that is being updated 
  # user      - the user that made the update
  # old_value - the value of the attribute before the update
  # new_value - the value of the attribute afer the update
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def record_update(what, old_value, new_value, user)
    self.design_updates << DesignUpdate.new(:what      => what, 
                                            :user_id   => user.id,
                                            :old_value => old_value,
                                            :new_value => new_value)
  end
  
  
  ######################################################################
  #
  # update_valor_reviewer
  #
  # Description:
  # This method updates the person assigned to perform the valor review
  #
  # Parameters:
  # peer - the user record for the new peer reviewer
  # user - the user that made the update
  #
  # Return value:
  # TRUE if the Valor reviewer was updated.
  #
  ######################################################################
  #
  def update_valor_reviewer(peer, user)
  
    updated      = false
    final_review = self.get_design_review('Final')
  
    # TO DO: This really should be a method in design_review
    if final_review.review_status.name != "Review Completed"
    
      valor_review_result = final_review.get_review_result('Valor')
      if valor_review_result.reviewer_id != peer.id
        final_review.record_update('Valor Reviewer',
                                   valor_review_result.reviewer.name,
                                   peer.name,
                                   user)
        valor_review_result.reviewer_id = peer_id
        valor_review_result.save
        
        updated = true
      end
    end

    updated

  end
  
  
  ######################################################################
  #
  # admin_updates
  #
  # Description:
  # This method processes the admin update
  #
  # Parameters:
  # update  - a hash of the attributes to be updated
  # comment - the user's comment associated with the update
  # user    -
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def admin_updates(update, comment, user)

    audit= self.audit
    
    changes = {}
    cc_list = []
    set_pcb_input_designer = false

    # Update the design reviews
    self.design_reviews.each do |dr|

      original_designer    = dr.designer
      original_criticality = dr.priority
      original_review_status = dr.review_status.name

      next if dr.review_status.name == "Review Completed"

      if dr.update_criticality(update[:criticality], user)
        changes[:criticality] = { :old => original_criticality.name, 
                                  :new => update[:criticality].name}
      end
      
      if dr.update_review_status(update[:status], user)
        changes[:review_status] = { :old => original_review_status,
                                    :new => update[:status].name}
      end 
      

      # If the design review is "Pre-Artwork" that is not complete
      # then process any PCB Input Gate change.
      if dr.update_pcb_input_gate(update[:pcb_input_gate], user)
        cc_list << original_designer.email
        cc_list << update[:pcb_input_gate].email if update[:pcb_input_gate].id != 0

        changes[:pcb_input_gate] = { :old => original_designer.name, 
                                     :new => update[:pcb_input_gate].name}

        set_pcb_input_designer = true

      elsif dr.update_release_review_poster(update[:release_poster], user)

        cc_list << original_designer.email
        cc_list << update[:release_poster].email if update[:release_poster].id != 0
        changes[:release_poster] = { :old => original_designer.name, 
                                     :new => update[:release_poster].name }
        
      elsif dr.update_reviews_designer_poster(update[:designer], user)

        cc_list << dr.designer.email       if dr.designer_id != 0
        cc_list << update[:designer].email if update[:designer].id != 0
        changes[:designer] = { :old => original_designer.name, 
                               :new => update[:designer].name }
      end
      
      dr.reload if changes.size > 0

    end
    
    # Update the design.
    cc_list << self.input_gate.email               if self.pcb_input_id != 0
    cc_list << self.designer.email                 if self.designer_id  != 0
    if set_pcb_input_designer && 
       update[:pcb_input_gate] && 
       self.pcb_input_id != update[:pcb_input_gate].id
      self.pcb_input_id = update[:pcb_input_gate].id
    end

    old_pcb_path = '/hwnet/' +
      self.design_center.pcb_path + '/' +
      self.directory_name
    old_design_center_name = self.set_design_center(update[:design_center], user)
    if old_design_center_name
      changes[:design_center] = { :old => old_design_center_name,
                                  :new => update[:design_center].name }
      # call the program to rename assembly folders in the NPI BOM data to reflect the
      # movement of the design.
      new_pcb_path = '/hwnet/' +
        self.design_center.pcb_path + '/' +
        self.directory_name
      PartNum.get_design_pcba_part_numbers(self).each { |pcba|
        cmd = "/hwnet/dtg_devel/web/boarddev/cgi-bin/npi_boms/rename_assembly_folder.pl" +
          " " + pcba.name_string +
          " " + old_pcb_path +
          " " + new_pcb_path
        system(cmd) unless Rails.env == "test"
      }
    end

    if update[:designer] && self.designer_id != update[:designer].id
      self.record_update('Designer', 
        self.designer.name,
        update[:designer].name,
        user)
      self.designer_id = update[:designer].id
   end

    if update[:criticality] && self.priority_id != update[:criticality].id
      self.priority  = update[:criticality] 
    end

    if update[:eco_number] && self.eco_number != update[:eco_number]
      old_eco_number = self.eco_number
      self.eco_number = update[:eco_number]
      changes[:ecn_number] = { :old => old_eco_number, :new => update[:eco_number]}
    end
    
    audit = self.audit
    if update[:peer] && self.peer_id != update[:peer].id 
      
      final_design_review = self.get_design_review('Final')
      valor_review_result = final_design_review.get_review_result('Valor')
      
      if valor_review_result.reviewer_id != update[:peer].id
          
        cc_list << valor_review_result.reviewer.email if valor_review_result.reviewer_id != 0
        changes[:valor] = { :old => valor_review_result.reviewer.name,
                            :new => update[:peer].name }
        final_design_review.record_update('Valor Reviewer',
                                          valor_review_result.reviewer.name,
                                          update[:peer].name,
                                          user)
                          
        valor_review_result.reviewer_id = update[:peer].id
        valor_review_result.save
           
      end
      
      if !audit.skip?  && !audit.is_complete?
        changes[:peer] = { :old => self.peer.name, :new => update[:peer].name }
        self.record_update('Peer Auditor', 
                            self.peer.name, 
                            update[:peer].name,
                            user)
      
        self.peer_id = update[:peer].id
      end
      
    end

        
    if changes.size > 0 || comment.size > 0 

      self.save
      self.reload

      DesignMailer::design_modification(
        user,
        self,
        modification_comment(comment, changes), 
        cc_list).deliver

      self.pcb_number +
      ' has been updated - the updates were recorded and mail was sent'
      
    else
      "Nothing was changed - no updates were recorded"
    end

  end
  
  
  ######################################################################
  #
  # get_design_review
  #
  # Description:
  # This method returns the design review for the review type identified
  # by name.
  #
  # Parameters:
  # name - the review type name
  #
  # Return value:
  # The design review record for the desired review type.
  #
  ######################################################################
  #
  def get_design_review(name)
    self.design_reviews.detect { |dr| dr.review_type.name == name }
  end
  
  
  # Set the reviewer for the design reviews with incomplete results for the 
  # role.
  #
  # :call-seq:
  #   set_reviewer(role, user) -> nil
  #
  #  For each of the design reviews associated with the design, set the reviewer
  #  for the specified role.
  #
  # Exception
  #   ArgumentError - indicates that the user is not a member of the group (role).
  def set_reviewer(role, user)
    self.design_reviews.each { |dr| dr.set_reviewer(role, user) }
  rescue
    raise
  end
  
  
  ######################################################################
  #
  # role_review_count
  #
  # Description:
  # This method returns the count of the number of reviews assigned
  # to the role over all of the design reviews for the design.
  #
  # Parameters:
  # role - record for the role of interest
  #
  # Return value:
  # The number of roles that have been assigned in all of the design's
  # reviews.
  #
  ######################################################################
  #
  def role_review_count(role)
    role_count = 0
    self.design_reviews.each do |dr|
      role_count += 1 if dr.design_review_results.detect { |drr| drr.role_id == role.id }
    end
    role_count
  end
  
  
  ######################################################################
  #
  # role_open_review_count
  #
  # Description:
  # This method returns the count of the number of open reviews assigned
  # to the role over all of the design reviews for the design.
  #
  # Parameters:
  # role - record for the role of interest
  #
  # Return value:
  # The number of roles that have been assigned in all of the design's
  # reviews that are open.
  #
  ######################################################################
  #
  def role_open_review_count(role)
    open_reviews   = 0
    closed_reviews = ReviewStatus.closed_reviews
    self.design_reviews.each do |dr|
      next if closed_reviews.detect { |rvw| rvw == dr.review_status }
      review_result = dr.design_review_results.detect { |drr| drr.role_id == role.id }
      open_reviews += 1 if review_result && !COMPLETED_RESULTS.include?(review_result.result)
    end
    open_reviews
  end
  
  
  ######################################################################
  #
  # get_role_reviewer
  #
  # Description:
  # This method returns the reviewer for the role
  #
  # Parameters:
  # role - record for the role of interest
  #
  # Return value:
  # The user record assigned to the reviewer role identified by the 
  # role argument.
  #
  ######################################################################
  #
  def get_role_reviewer(role)
    reviewer = nil
    self.design_reviews.sort_by { |dr| dr.review_type.sort_order }.each do |dr|
      result   = dr.design_review_results.detect { |drr| drr.role == role }
      reviewer = result.reviewer if result
    end

    return reviewer
  end
  
  
  # Retrieve a list of users assigned to the review role for the design.
  #
  # :call-seq:
  #   get_role_reviewers(role) -> []
  #
  #  Returns a list of users who have been assigned to the review role
  #  for the design alphabetized by the last name.
  #
  def get_role_reviewers(role_name)
    role      = Role.find_by_name(role_name)
    reviewers = []
    self.design_reviews.each do |dr|
      result = dr.design_review_results.detect { |drr| drr.role == role }
      reviewers << result.reviewer if  result
    end
    reviewers.uniq.sort_by { |reviewer| reviewer.last_name }
  end
  
  
  ######################################################################
  #
  # is_role_reviewer?
  #
  # Description:
  # This method indicates if the user is assigned to perform the review
  # for the role
  #
  # Parameters:
  # role - record for the role of interest
  # user - record for the user of interest
  #
  # Return value:
  # True if the user is assigned to perform the review for the role.
  # Otherwise False
  #
  ######################################################################
  #
  def is_role_reviewer?(role, user)
    user == self.get_role_reviewer(role)
  end
  
  
  ######################################################################
  #
  # set_role_reviewer
  #
  # Description:
  # This method updates the design review result with a new reviewer.
  #
  # Parameters:
  # role         - record for the role that is being updated
  # new_reviewer - record for the user that will be assigned to
  #                perform the review for the role
  # user         - record for the user that is performing the update
  #
  # Return value:
  # Nil if no role was updated, otherwise the review type name
  # of the last design review that was updated.
  #
  ######################################################################
  #
  def set_role_reviewer(role, new_reviewer, user)

    completed_results = ['APPROVED', 'WAIVED']
    in_review = nil
    self.design_reviews.each do |dr|

      next if dr.review_status.name == 'Review Completed'

      review_result = dr.design_review_results.detect { |drr| drr.role_id == role.id }
      if review_result && !completed_results.include?(review_result.result)
        old_reviewer              = review_result.reviewer
        review_result.reviewer_id = new_reviewer.id
        review_result.save

        dr.record_update(role.display_name + ' Reviewer', 
                         old_reviewer.name,
                         new_reviewer.name,
                         user)

        if dr.review_status.name == 'In Review'
          DesignMailer::reviewer_modification_notification(dr, 
            role,
            old_reviewer,
            new_reviewer,
            user).deliver
        end
        in_review = dr.review_type.name
      end
      
    end
  
    in_review
    
  end
  
  
  ######################################################################
  #
  # reviewers
  #
  # Description:
  # This method provides a list of all of the users assigned to perform
  # all of the reviews for the design.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A unique list of users assigned to perform all of the reviews
  #
  ######################################################################
  #
  def reviewers
    reviewer_list = []
    self.design_reviews.each { |dr| reviewer_list = dr.reviewers(reviewer_list) }
    reviewer_list.sort_by { |r| r.last_name }
  end
  
  
  ######################################################################
  #
  # reviewers_remaining_reviews
  #
  # Description:
  # This method provides a list of all of the users assigned to perform
  # all of the remaining reviews for the design.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A unique list of users assigned to perform all of the reviews for
  # the remaining reviews.
  #
  ######################################################################
  #
  def reviewers_remaining_reviews
    reviewer_list = []
    self.design_reviews.each do |dr|
      next if dr.review_status.name == 'Review Completed' || dr.review_status.name == 'Review Skipped'
      reviewer_list = dr.reviewers(reviewer_list)
    end
    reviewer_list.sort_by { |r| r.last_name }
  end
  
  
  ######################################################################
  #
  # inactive_reviewers?
  #
  # Description:
  # This method indicates if an inactive reviewer is assigned to perform
  # any of the remaining reviews for the design.
  #
  # Parameters:
  # None
  #
  # Return value:
  # True if any of the remaining reviews is assigned to a user that is
  # inactive, otherwise False.
  #
  ######################################################################
  #
  def inactive_reviewers?
    self.reviewers_remaining_reviews.each { |r| return true if !r.active? }
    return false
  end
  
  
  ######################################################################
  #
  # detailed_name
  #
  # Description:
  # This method returns the detailed name for the design
  #
  # Parameters:
  # None
  #
  # Return value:
  # A string with the design's detailed name
  #
  ######################################################################
  #
  def detailed_name
    brd = self.board
    self.directory_name + ' - ' + brd.platform.name + ' / ' +
    brd.project.name + ' / ' + brd.description
  end

  
  ######################################################################
  #
  # audit_type
  #
  # Description:
  # Determines the audit type, full or partial, associated with the 
  # design
  #
  # Parameters:
  # None
  #
  # Return value:
  # A string indicating the design's audit type
  #
  ######################################################################
  #
  def audit_type
    self.new? ? 'Full' : 'Partial'
  end


  ######################################################################
  #
  # flip_design_type
  #
  # Description:
  # The design type is toggled between 'New' (full) and
  # 'Dot Rev' (partial) and then the audit checklist is updated.
  #
  # Parameters:
  # None
  #
  # Return value:
  # The number of design checks that have been added or removed.
  #
  ######################################################################
  #
  def flip_design_type
    
    self.design_type = self.design_type == 'New' ? 'Dot Rev' : 'New'
    self.save
    
    self.audit.update_checklist_type
    
  end
  
  
  ######################################################################
  #
  # directory_name
  #
  # Description:
  # Provides the name of the directory in the PCB design file 
  # directory.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A string that represents the design's PCB design directory.
  #
  ######################################################################
  #
  def directory_name
    
    pnum = PartNum.get_design_pcb_part_number(self.id)
    if pnum 
      directory_name = "pcb" + pnum.prefix + "_" +
      pnum.number + "_" + pnum.dash + "_" + pnum.revision
      return directory_name
    end
    
    # If execution reaches this point then the design was originated
    # under the old part numbering schema and the directory is based on 
    # the pnemonic.
    return self.pnemonic_based_name
    
  end
  
  
  ######################################################################
  #
  # display_summary
  #
  # Description:
  # Provides summary information about the design for display.
  # The summary is in the following format:
  #   directory_name -> platform_name / project_name
  #
  # Parameters:
  # None
  #
  # Return value:
  # A string containing the display summary.
  #
  ######################################################################
  #
  def display_summary
    self.directory_name + ' -> ' + self.board.platform.name + ' / ' +
      self.board.project.name
  end
  
  
  ######################################################################
  #
  # pnemonic_based_name
  #
  # Description:
  # Provides the design name using the old PCB pnemonic based naming 
  # convention.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A string that represents the name under the old PCB pnemonic based
  # naming schema.
  #
  ######################################################################
  #
  def pnemonic_based_name
    
    base_name = self.board.name + self.revision.name
    
    if self.dot_rev? && self.numeric_revision?
      base_name += self.numeric_revision.to_s
    end
    
    base_name
    
    
  end
  
  #JPA
  ######################################################################
  #
  # set_design_center
  #
  # Description:
  # This method updates the design center attribute and records the
  # update.
  #
  # Parameters:
  # design_center - the new value for the design center attribute
  # user          - the user who made the update
  #
  # Return value:
  # The old design center name if the design center was updated.
  # Otherwise, nil
  ####################################################################
  #
  def set_design_center(design_center, user)

    if design_center && self.design_center_id != design_center.id
      old_design_center_name = self.design_center_id > 0 ? self.design_center.name : 'Not Set'
      self.record_update('Design Center',
                         old_design_center_name,
                         design_center.name,
                         user)
      self.design_center = design_center
      self.save
    end

    old_design_center_name

  end

   ######################################################################
  #
  # pcb_number
  #
  # Description:
  # This method returns the pcb number.
  #
  ######################################################################
  #
  def pcb_number
    pnum = PartNum.get_design_pcb_part_number(self.id)
    if pnum
      pnum.name_string
    else
      ""
    end
    #PartNum.get_design_pcb_part_number(self.id).name_string
  end

  def pcb_number?
    PartNum.get_design_pcb_part_number(self.id)?true:nil
  end

  def pcb_rev
    PartNum.get_design_pcb_part_number(self.id).rev_string
  end

  def pcb_display
    part_num = PartNum.get_design_pcb_part_number(self.id)
    if part_num
      part_num.name_string + ' ' + part_num.rev_string
    else
      "(no part number)"
    end
  end

   ######################################################################
  #
  # pcb_number_with_description
  #
  # Description:
  # This method returns the pcb number with its description.
  #
  ######################################################################
  #
  def pcb_number_with_description
    pnum = PartNum.get_design_pcb_part_number(self.id)
    if pnum
      pnum.name_string_with_description
    else
      ""
    end
  end

  ######################################################################
  #
  # pcba part numbers
  #
  # Description:
  # These methods returns the pcba part number.
  #
  ######################################################################
  #
  def pcbas_string
    first = 1
    pcbas = ""
    PartNum.get_design_pcba_part_numbers(self.id).each { |pcba|
      if first == 1
        pcbas = pcba.name_string_with_description
        first = 0
      else
        pcbas << "<br>" + pcba.name_string_with_description
      end
    }
    pcbas
  end

 ######################################################################
  #
  # subject_prefix
  #
  # Description:
  # Provides a common prefix for subjects
  #
  # Parameters:
  #   None
  #
  ######################################################################
  #
  def subject_prefix
    self.board.platform.name + '/' +
    self.board.project.name  + '/' +
    self.board.description   + '(' +
    self.directory_name      +  '): '
  end

########################################################################
########################################################################
  private
########################################################################
########################################################################
  
  
  ######################################################################
  #
  # modification_comment
  #
  # Description:
  # This method creates the comment for design modifications made
  # by the managers and designers
  #
  # Parameters
  # post_comment  - the associated comment entered by the user
  # changes       - contains the modifications that were made to the 
  #                 design review
  #
  ######################################################################
  #
  def modification_comment(post_comment, changes)

    msg = ''
    
    if changes[:designer]
      msg += "The Lead Designer was changed from #{changes[:designer][:old]} to #{changes[:designer][:new]}\n"
    end
    if changes[:peer]
      msg += "The Peer Auditor was changed from #{changes[:peer][:old]} to #{changes[:peer][:new]}\n"
    end
    if changes[:pcb_input_gate]
      msg += "The PCB Input Gate was changed from #{changes[:pcb_input_gate][:old]} to #{changes[:pcb_input_gate][:new]}\n"
    end
    if changes[:release_poster]
      msg += "The Release Poster was changed from #{changes[:release_poster][:old]} to #{changes[:release_poster][:new]}\n"
    end
    if changes[:criticality]
      msg += "The Criticality was changed from #{changes[:criticality][:old]} to #{changes[:criticality][:new]}\n"
    end
    if changes[:design_center]
      msg += "The Design Center was changed from #{changes[:design_center][:old]} to #{changes[:design_center][:new]}\n"
    end
    if changes[:review_status]
      msg += "The design review status was changed from #{changes[:review_status][:old]} to #{changes[:review_status][:new]}\n"
    end
    if changes[:ecn_number]
      msg += "The ECN number was changed from #{changes[:ecn_number][:old]} to #{changes[:ecn_number][:new]}\n"
    end

    msg += "\n\n" + post_comment if post_comment.size > 0
    
    msg

  end
  
  
end
