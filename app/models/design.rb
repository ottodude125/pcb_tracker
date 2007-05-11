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
  belongs_to :revision

  has_and_belongs_to_many :fab_houses

  has_many  :design_review_documents
  has_many  :design_reviews
  has_many  :ipd_posts
  has_many  :oi_instructions

  has_one   :audit
  has_one   :board_design_entry
  has_one   :ftp_notification
  
  
  NOT_SET = 'Not Set'


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
  
  
  def have_assignments(user_id)
    
    self.oi_instructions.each do |instruction|
      if OiAssignment.find_by_oi_instruction_id_and_user_id(instruction.id, user_id) != nil
        return true
      end
    end
    
    return false
    
  end
  
  
  def my_assignments(user_id)
  
    my_assignments  = []    
    self.oi_instructions.each do |instruction|
      instruction.oi_assignments.each do |assignment| 
        my_assignments << assignment if assignment.user_id == user_id 
      end
    end
    
    my_assignments
  
  end


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
  
    if self.phase_id == Design::COMPLETE
      ReviewType.new(:name => 'Complete')
    elsif self.phase_id > 0
      ReviewType.find(self.phase_id)
    else
      ReviewType.new(:name => 'Not Started')
    end
  
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

    base_name = self.board.name + self.revision.name

    if self.date_code?
      if self.numeric_revision?
        base_name + self.numeric_revision.to_s + '_eco' + self.eco_number
      else
        base_name + '_eco' + self.eco_number
      end
    elsif self.dot_rev?
      if self.numeric_revision?
        base_name + self.numeric_revision.to_s
      else
        base_name
      end
    else
      base_name
    end
  
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
  # A list of User records.  One for each of the reviewers.
  #
  ######################################################################
  #
  def all_reviewers(sorted = false)
  
    reviewer_list = []
    self.design_reviews.each do |design_review|
      reviewer_list = design_review.reviewers(reviewer_list)
    end

    reviewer_list = 
      reviewer_list.sort_by { |reviewer| reviewer.last_name } if sorted
    
    reviewer_list.uniq
    
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

    phase_id   = Design::COMPLETE
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
    review_types   = ReviewType.find_all_by_active(1)

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
        #TO Do: This assumes there is only one PCB ADMIN - fix
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
  

  COMPLETE = 255
  

end
