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
  belongs_to :suffix

  has_and_belongs_to_many :fab_houses

  has_many  :design_review_documents
  has_many  :design_reviews
  has_many  :ipd_posts

  has_one   :audit


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
      base_name + '_eco' + self.suffix.name
    elsif self.dot_rev?
      base_name + self.suffix.name
    else
      base_name
    end
  
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


  COMPLETE = 255
  

  private

  def self.get_reviewers(board_id, role_list=nil)

    @review_roles = Role.find_all('reviewer=1', 'name ASC')

    reviewers = BoardReviewers.find_all("board_id=#{board_id}")

    board_reviewers = Hash.new
    for reviewer in reviewers
      board_reviewers[Role.find(reviewer.role_id).name] = reviewer.reviewer_id
    end

    @reviewers = Array.new
    for role in @review_roles

      if role_list != nil
        next if not role_list.include?(role.id)
      end

      reviewer_list = Hash.new

      reviewers = Role.find_by_name("#{role.name}").active_users
      
      reviewer_list[:group]        = role.name
      reviewer_list[:group_id]     = role.id
      reviewer_list[:reviewers]    = reviewers
      reviewer_list[:reviewer_id]  = board_reviewers[role.name]
      @reviewers.push(reviewer_list)
    end

    return @reviewers
    
  end
  

end
