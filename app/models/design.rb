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

  has_many  :design_reviews

  has_one   :audit


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
