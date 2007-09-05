########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: board.rb
#
# This file maintains the state for boards.
#
# $Id$
#
########################################################################

class Board < ActiveRecord::Base

  belongs_to :platform
  belongs_to :project
  belongs_to :prefix

  has_many(:designs,       :order => 'name' )
  has_many   :board_reviewers
  has_many   :design_review_documents
  has_one    :audit

  has_and_belongs_to_many :fab_houses
  has_and_belongs_to_many :users

  validates_presence_of :platform_id
  validates_presence_of :project_id


  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################

  
  ######################################################################
  #
  # role_reviewer
  #
  # Description:
  # This method locates the board reviewer for the role_id that is
  # passed in.
  #
  # Parameters:
  # role_id - role record id
  #
  # Return value:
  # A board_reviewer record if there is a board reviewer for the role.
  # Otherwise, nil is returned.
  #
  ######################################################################
  #
  def role_reviewer(role_id)
    self.board_reviewers.detect { |br| br.role_id == role_id }
  end
  

  ######################################################################
  #
  # name
  #
  # Description:
  # This method returns the boards display name
  #
  ######################################################################
  #
  def name 
    self.prefix.pcb_mnemonic + self.number
  end
  
  
end
