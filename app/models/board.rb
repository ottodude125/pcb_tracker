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

  has_many   :designs
  has_many   :board_reviewers
  has_one    :audit

  has_and_belongs_to_many :fab_houses
  has_and_belongs_to_many :users

  validates_presence_of :number
  validates_presence_of :platform_id
  validates_presence_of :prefix_id
  validates_presence_of :project_id

  validates_numericality_of :number


  ######################################################################
  #
  # validate_on_create
  #
  # Description:
  # This method prevents duplicate boards from being created
  #
  ######################################################################
  #
  def validate_on_create
    new_board = Board.find_by_number_and_prefix_id(number, prefix_id)
    if new_board
      errors.add("Board #{new_board.name} already exists - creation")
    end
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
