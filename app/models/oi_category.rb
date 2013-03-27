########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: oi_category.rb
#
# This file maintains the state for oi_categories.
#
# $Id$
#
########################################################################

class OiCategory < ActiveRecord::Base


  has_many(:oi_category_sections, 
           :order => :id)

           
  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


  ######################################################################
  #
  # list
  #
  # Description:
  # This method returns a list of categories ordered by the ID.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def self.list
    self.find(:all, :order => :id)
  end


  ######################################################################
  #
  # other_category_section_id
  #
  # Description:
  # This method returns the category section id of "Other"
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def self.other_category_section_id
    self.find_by_name("Other").oi_category_sections[0].id
  end


  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################


  ######################################################################
  #
  # other?
  #
  # Description:
  # This method returns True if the category is "Other"
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def other?
    self.name == 'Other'
  end


end
