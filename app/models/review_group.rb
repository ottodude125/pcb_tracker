########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: review_group.rb
#
# This file maintains the state for review groups.
#
# $Id$
#
########################################################################

class ReviewGroup < ActiveRecord::Base

  validates_uniqueness_of(:name,
			  :message => 'already exists in the database')

end
