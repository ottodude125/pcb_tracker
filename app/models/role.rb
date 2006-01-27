########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: role.rb
#
# This file maintains the state for roles.
#
# $Id$
#
########################################################################

class Role < ActiveRecord::Base
#  has_and_belongs_to_many :permissions

  has_many :design_review_results

  has_and_belongs_to_many :review_types
  has_and_belongs_to_many :users


  validates_uniqueness_of :name

end
