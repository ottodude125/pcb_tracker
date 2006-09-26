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

  has_one   :audit
  has_one   :board_design_entry
  
  
  NOT_SET = 'Not Set'


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
    for role_name in role_names
      role     = Role.find_by_name(role_name)
      reviewer = BoardReviewers.find_by_board_id_and_role_id(
                   self.board.id,
                   role.id)
      if reviewer && reviewer.reviewer_id > 0
        users[role_name] = User.find(reviewer.reviewer_id)
      else
        users[role_name] = User.new(:first_name => 'Not', :last_name => 'Set')
      end
    end
    
    reviewer_list = self.all_reviewers
    for design_review in self.design_reviews
      for review_result in design_review.design_review_results
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
  # get_associated_users_by_role
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
    for design_review in design_reviews
      for design_review_result in design_review.design_review_results
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
  
    if self.phase_id > 0
      ReviewType.find(self.phase_id)
    elsif self.phase_id == Design::COMPLETE
      ReviewType.new(:name => 'Complete')
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
    for design_review in self.design_reviews
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
  # This method sets the phase of the design to the next available 
  # review.
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

    review_types = ReviewType.find_all
    review_types = review_types.sort_by { |rt| rt.sort_order }
    
    current_review_type = ReviewType.find(self.phase_id)

    phase_id   = Design::COMPLETE
    next_review = nil
    review_types.each { |rt|
      next if rt.sort_order <= current_review_type.sort_order
      next_review = self.design_reviews.detect { |dr| dr.review_type_id == rt.id }
      break if next_review.review_status.name != "Review Skipped"
    }

    if next_review && next_review.review_status.name != "Review Skipped"
      phase_id = next_review.review_type_id
    end
    
    self.phase_id = phase_id
    self.update
  
  end
  
  
  def setup_design_reviews(review_types_list, 
                           board_team_list)
    
    not_started    = ReviewStatus.find_by_name('Not Started')
    review_skipped = ReviewStatus.find_by_name('Review Skipped')
    review_types   = ReviewType.find_all_by_active(1)
    
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
      design_review.dump_design_review
      
      pcb_input_gate_role = Role.find_by_name('PCB Input Gate')
      board_team_list.each { |reviewer|
      
        # Do not create a record if the team member is not a reviewer or
        # if the reviewer role is not required
        next if !reviewer.role.reviewer? || !reviewer.required?
        
        if reviewer.role.review_types.include?(review_type)
        
          if reviewer.role_id == pcb_input_gate_role.id 
            reviewer_id = self.created_by
          else
            reviewer_id = reviewer.user_id
          end
          
          drr = DesignReviewResult.new(:design_review_id => design_review.id,
                                       :reviewer_id      => reviewer.user_id,
                                       :role_id          => reviewer.role_id)
          drr.save

          # If the role (group) is set to have the peers CC'ed then update the 
          # design review.
          if reviewer.role.cc_peers?
            cc_list = drr.role.users
            for peer in cc_list
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
  
  
  def dump_design
  
    review   = ReviewType.find(self.phase_id)
    priority = Priority.find(self.priority_id)
    designer = User.find(self.designer_id)  if self.designer_id  > 0
    peer     = User.find(self.peer_id)      if self.peer_id      > 0
    ig       = User.find(self.pcb_input_id) if self.pcb_input_id > 0
    creator  = User.find(self.created_by)   if self.created_by   > 0
    
    logger.info "************************* DESIGN *************************"
    logger.info "NAME: #{self.name}"
    logger.info "TYPE: #{self.design_type}"
    logger.info "ID: #{self.id}"
    logger.info "BOARD_ID: #{self.board_id}"
    if review
      logger.info "PHASE: #{review.name}"
    else
      logger.info "PHASE_ID: #{self.phase_id}"
    end
    if priority
      logger.info "PRIORITY: #{priority.name}"
    else
      logger.info "PRIORITY_ID: #{self.priority_id}"
    end
    if designer
      logger.info "DESIGNER: #{designer.name}"
    else
      logger.info "DESIGNER_ID: #{self.designer_id}"
    end
    if peer
      logger.info "PEER: #{peer.name}"
    else
      logger.info "PEER_ID: #{self.peer_id}"
    end
    if ig
      logger.info "INPUT GATE: #{ig.name}"
    else
      logger.info "INPUT GATE ID: #{self.pcb_input_id}"
    end
    if creator
      logger.info "CREATED BY: #{creator.name}"
    else
      logger.info "CREATED BY ID: #{self.created_by}"
    end
    logger.info "##########################################################"
  
  end


  COMPLETE = 255
  

end
