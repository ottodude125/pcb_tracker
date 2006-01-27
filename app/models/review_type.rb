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

end
