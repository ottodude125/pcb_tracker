########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: review_status.rb
#
# This file maintains the state for review statuss.
#
# $Id$
#
########################################################################

class ReviewStatus < ActiveRecord::Base

  has_many :design_reviews


  validates_uniqueness_of(:name,
                          :message => 'already exists in the database')
  validates_presence_of   :name

end
