########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: priority.rb
#
# This file maintains the state for review priorities.
#
# $Id$
#
########################################################################

class Priority < ActiveRecord::Base

  has_many :designs
  has_many :design_reviews
  
  
  validates_uniqueness_of(:name,
                          :message => 'already exists in the database')
  validates_uniqueness_of(:value,
                          :message => 'must be unique')
  validates_numericality_of(:value,
                            :message => '- Review Priority must be an integer greater than 0',
                            :only_integer => true)


  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


  ######################################################################
  #
  # get_priorities
  #
  # Description:
  # This method retrieves all of the priority records
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of priorities ordered by value
  #
  ######################################################################
  #
  def self.get_priorities
    self.find(:all, :order => 'value')
  end
  
  
end
