########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: review_typerb
#
# This file maintains the state for review types.
#
# $Id$
#
########################################################################

class ReviewType < ActiveRecord::Base


  has_and_belongs_to_many :roles

  has_many :design_reviews


  validates_uniqueness_of(:name,
			  :message => 'already exists in the database')
  validates_uniqueness_of(:sort_order,
			  :message => 'must be unique')
  validates_numericality_of(:sort_order,
			    :message => '- must be an integer greater than 0',
			    :only_integer => true)
  validates_presence_of   :name


  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


  ######################################################################
  #
  # get_active_review_types
  #
  # Description:
  # This method retrieves all of the active review type records
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of active review types ordered by the sort_order attribute
  #
  ######################################################################
  #
  def self.get_active_review_types
    self.find(:all, :conditions => 'active=1', :order => 'sort_order')
  end
  
  
  ######################################################################
  #
  # get_review_types
  #
  # Description:
  # This method retrieves all of the review type records
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of review types ordered by the sort_order attribute
  #
  ######################################################################
  #
  def self.get_review_types
    self.find(:all, :order => 'sort_order')
  end
  
  
  ######################################################################
  #
  # get_pre_artwork
  #
  # Description:
  # This method retrieves the Pre-Artwork Review Type record
  #
  # Parameters:
  # None
  #
  # Return value:
  # A review type record
  #
  ######################################################################
  #
  def self.get_pre_artwork
    self.find_by_name('Pre-Artwork')
  end
  
  
  ######################################################################
  #
  # get_placement
  #
  # Description:
  # This method retrieves the Placement Review Type record
  #
  # Parameters:
  # None
  #
  # Return value:
  # A review type record
  #
  ######################################################################
  #
  def self.get_placement
    self.find_by_name('Placement')
  end
  
  
  ######################################################################
  #
  # get_routing
  #
  # Description:
  # This method retrieves the Routing Review Type record
  #
  # Parameters:
  # None
  #
  # Return value:
  # A review type record
  #
  ######################################################################
  #
  def self.get_routing
    self.find_by_name('Routing')
  end
  

  ######################################################################
  #
  # get_final
  #
  # Description:
  # This method retrieves the Final Review Type record
  #
  # Parameters:
  # None
  #
  # Return value:
  # A review type record
  #
  ######################################################################
  #
  def self.get_final
    self.find_by_name('Final')
  end
  
  
  ######################################################################
  #
  # get_release
  #
  # Description:
  # This method retrieves the Release Review Type record
  #
  # Parameters:
  # None
  #
  # Return value:
  # A review type record
  #
  ######################################################################
  #
  def self.get_release
    self.find_by_name('Release')
  end
  
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################

  
  ######################################################################
  #
  # next
  #
  # Description:
  # This method retrieves the review type that follows this instance
  # of review types based on the sort_order attribute.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A review type record if this instance is not the last one in the
  # list.  Otherwise, Nil is returned.
  #
  ######################################################################
  #
  def next
    ReviewType.find(:first,
                    :conditions => "active = 1 AND sort_order > '#{self.sort_order}'",
                    :order      => "sort_order")
  end


end
