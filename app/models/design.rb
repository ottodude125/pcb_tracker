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
  belongs_to :priority
  belongs_to :part_number
  belongs_to :revision

  has_and_belongs_to_many :fab_houses

  has_many :design_review_documents
  has_many :design_reviews
  has_many :design_updates
  has_many :ipd_posts
  has_many :oi_instructions

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
  # work_assignment_data
  #
  # Description:
  # This method computes the following outsource instruction statistics
  #   - the total number of assignments
  #   - the total number of completed assignments
  #   - the total number of assignments that have report cards
  #
  # Parameters:
  # None
  #
  # Return value:
  # A hash with the outsource instruction statistics
  #
  ######################################################################
  #
  def work_assignment_data
  
    totals = { :assignments            => 0,
               :completed_assignments  => 0,
               :report_cards           => 0 }
    
    self.oi_instructions.each do |instruction| 
      instruction.oi_assignments.each do |a|
        totals[:assignments]            += 1 
        totals[:completed_assignments]  += 1 if a.complete?
        totals[:report_cards]           += 1 if a.oi_assignment_report
      end 
    end
    
    totals
  
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

    summary = self.work_assignment_data
  
    ( ( summary[:assignments] == summary[:completed_assignments] ) &&
      ( summary[:assignments] == summary[:report_cards] ) )
 
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

    role_names = ['Hardware Engineering Manager',
                  'Program Manager']
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
    logger.info("#################################")
    logger.info("#################################")
    logger.info("Design.name called")
    logger.info("#################################")
    logger.info("#################################")
    self.part_number.pcb_display_name
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
    self.update
  
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
#    review_types = ReviewType.find_all("active = 1 AND sort_order > '#{current_review_type.sort_order}'", 
#                                       "sort_order ASC")
    review_types = ReviewType.find(:all,
                                   :conditions => "active = 1 AND " +
                                                  "sort_order > '#{current_review_type.sort_order}'", 
                                   :order      => "sort_order ASC")

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
  # review_types_list - 
  # board_team_list   - a collection of users that are on the board team
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def setup_design_reviews(review_types_list, 
                           board_team_list)
                           
    skip_role = []
    if self.design_type != 'New'
      skip_role = [Role.find_by_name('Hardware Engineering Manager').id,
                   Role.find_by_name('Library').id,
                   Role.find_by_name('Compliance - EMC').id,
                   Role.find_by_name('Compliance - Safety').id,
                   Role.find_by_name('Operations Manager').id,
                   Role.find_by_name('PCB Mechanical').id,
                   Role.find_by_name('Program Manager').id,
                   Role.find_by_name('SLM BOM').id,
                   Role.find_by_name('SLM-Vendor').id]
    end
    
    not_started    = ReviewStatus.find_by_name('Not Started')
    review_skipped = ReviewStatus.find_by_name('Review Skipped')
    review_types   = ReviewType.get_active_review_types

    pcb_input_gate_role = Role.find_by_name('PCB Input Gate')
    
    #Go through each of the review types and setup a review.
    review_types_list.each { |review, active|

      review_type = review_types.detect { |rt| rt.name == review }
      
      design_review = DesignReview.new(:design_id      => self.id,
                                       :review_type_id => review_type.id,
                                       :creator_id     => self.created_by,
                                       :priority_id    => self.priority_id)
      design_review.review_status_id = active == '1' ? not_started.id : review_skipped.id
      
      if review_type.name == "Pre-Artwork"
        design_review.designer_id      = self.pcb_input_id
        design_review.design_center_id = User.find(self.pcb_input_id).design_center_id
      elsif review_type.name == 'Release'
        #TODO: This assumes there is only one PCB ADMIN - fix
        pcb_admin = User.find_by_first_name_and_last_name('Patrice', 'Michaels')
        design_review.designer_id      = pcb_admin.id
        design_review.design_center_id = pcb_admin.design_center_id
      end
      
      design_review.save

      
      board_team_list.each { |reviewer|
      
        # Do not create a record if:
        #   the team member is not a reviewer, or
        #   the reviewer role is not required, or
        #   the reviewer user id is zero,      or
        #   the role is listed it in skip_review
        next if (!(reviewer.role.reviewer? && reviewer.required? && 
                   reviewer.user_id?) || 
                 skip_role.detect { |i| i == reviewer.role_id })
        
        if reviewer.role.review_types.include?(review_type)
        
          if reviewer.role_id == pcb_input_gate_role.id 
            reviewer_id = self.created_by
          else
            reviewer_id = reviewer.user_id
          end
          
          drr = DesignReviewResult.new(:design_review_id => design_review.id,
                                       :reviewer_id      => reviewer_id,
                                       :role_id          => reviewer.role_id)
          drr.save

          # If the role (group) is set to have the peers CC'ed then update the 
          # design review.
          if reviewer.role.cc_peers?
            drr.role.users.each do |peer|
              next if (peer.id == drr.reviewer_id ||
                       !peer.active?              ||
                       design_review.design.board.users.include?(peer))
              design_review.design.board.users << peer
            end
          end


        end 
       
      }
    }
    
  
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
  
    final_review = self.get_design_review('Final')
  
    if final_review.review_status.name != "Review Completed"
    
      valor_review_result = final_review.get_review_result('Valor')
      if valor_review_result.reviewer_id != peer.id
        final_review.record_update('Valor Reviewer',
                                   valor_review_result.reviewer.name,
                                   peer.name,
                                   user)
        valor_review_result.reviewer_id = peer_id
        valor_review_result.update
        
        true
      else
        false
      end
    else
      false
    end

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

      # All design reviews will get any update to the design center.
      if dr.update_design_center(update[:design_center], user)
        changes[:design_center] = { :old => dr.design_center.name, 
                                    :new => update[:design_center].name }
      end

      next if dr.review_status.name == "Review Completed"

      if dr.update_criticality(update[:criticality], user)
        changes[:criticality] = { :old => dr.priority.name, 
                                  :new => update[:criticality].name}
      end
      
      if dr.update_review_status(update[:status], user)
        changes[:review_status] = { :old => dr.review_status.name, 
                                    :new => update[:status].name}
      end 
      

      # If the design review is "Pre-Artwork" that is not complete
      # then process any PCB Input Gate change.
      if dr.update_pcb_input_gate(update[:pcb_input_gate], user)
        cc_list << dr.designer.email             if dr.designer_id != 0
        cc_list << update[:pcb_input_gate].email if update[:pcb_input_gate].id != 0

        changes[:pcb_input_gate] = { :old => dr.designer.name, 
                                     :new => update[:pcb_input_gate].name}

        set_pcb_input_designer = true

      elsif dr.update_release_review_poster(update[:release_poster], user)

        cc_list << dr.designer.email             if dr.designer_id != 0
        cc_list << update[:release_poster].email if update[:release_poster].id != 0
        changes[:release_poster] = { :old => dr.designer.name, 
                                     :new => update[:release_poster].name }
        
      elsif dr.update_reviews_designer_poster(update[:designer], user)

        cc_list << dr.designer.email       if dr.designer_id != 0
        cc_list << update[:designer].email if update[:designer].id != 0
        changes[:designer] = { :old => dr.designer.name, 
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
        valor_review_result.update
           
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

      self.update
      self.reload

      TrackerMailer::deliver_design_modification(
        user,
        self,
        modification_comment(comment, changes), 
        cc_list)

      self.part_number.pcb_display_name + 
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
    open_reviews = 0
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
      result   = dr.design_review_results.detect { |drr| drr.role == role}
      reviewer = result.reviewer if result
    end

    return reviewer
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
        review_result.update
        
        dr.record_update(role.display_name + 'Reviewer', 
                         old_reviewer.name, 
                         new_reviewer.name, 
                         user)

        if dr.review_status.name == 'In Review'
          TrackerMailer::deliver_reviewer_modification_notification(dr, 
                                                                    role,
                                                                    old_reviewer,
                                                                    new_reviewer,
                                                                    user)
          in_review = dr.review_type.name
        end
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
    self.part_number.pcb_display_name + ' - ' + brd.platform.name + ' / ' +
    brd.project.name + ' / ' + brd.description
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

    msg += "\n\n" + post_comment if post_comment.size > 0
    
    msg

  end
  
  
end
