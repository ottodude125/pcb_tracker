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

end
