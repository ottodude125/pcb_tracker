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

  has_and_belongs_to_many :fab_houses

  has_many  :design_review_documents
  has_many  :design_reviews
  has_many  :ipd_posts

  has_one   :audit


  def get_associated_users_by_role

    users = {}
    
    users[:designer]  = User.find(self.designer_id)  if (self.designer_id  > 0)
    users[:peer]      = User.find(self.peer_id)      if (self.peer_id      > 0)
    users[:pcb_input] = User.find(self.pcb_input_id) if (self.pcb_input_id > 0)
    
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
  
  
  def designer
  
    if self.designer_id > 0
      User.find(self.designer_id)
    else
      User.new(:first_name => 'Not', :last_name => 'Assigned')
    end
  
  end


  def peer
  
    if self.peer_id > 0
      User.find(self.peer_id)
    else
      User.new(:first_name => 'Not', :last_name => 'Assigned')
    end
  
  end
  
  
  def input_gate
  
    if self.pcb_input_id > 0
      User.find(self.pcb_input_id)
    else
      User.new(:first_name => 'Not', :last_name => 'Assigned')
    end
    
  end
  
  
  def all_reviewers(sorted = false)
  
    reviewer_list = []
    for design_review in self.design_reviews
      reviewer_list = design_review.reviewers(reviewer_list)
    end

    reviewer_list = 
      reviewer_list.sort_by { |reviewer| reviewer.last_name } if sorted
    
    reviewer_list.uniq
    
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

      reviewers = Role.find_by_name("#{role.name}").users
      
      reviewer_list[:group]        = role.name
      reviewer_list[:group_id]     = role.id
      reviewer_list[:reviewers]    = reviewers.sort_by { |r| r.last_name }
      reviewer_list[:reviewer_id]  = board_reviewers[role.name]
      @reviewers.push(reviewer_list)
    end

    return @reviewers
    
  end
  

end
