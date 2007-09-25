########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: product_type.rb
#
# This file maintains the state for product types.
#
# $Id$
#
########################################################################

class ProductType < ActiveRecord::Base
  
  has_many :board_design_entries

  validates_uniqueness_of :name
  validates_presence_of :name


  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################

  
  ######################################################################
  #
  # get_active_product_types
  #
  # Description:
  # This method returns a list of the active product type records
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of active product type records
  #
  ######################################################################
  #
  def self.get_active_product_types
    self.find(:all, :conditions => 'active=1', :order => 'name')
  end
  
  
end
