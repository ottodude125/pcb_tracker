########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: posting_timestamp.rb
#
# This file maintains the state for posting timestamps.
#
# $Id$
#
########################################################################

class PostingTimestamp < ActiveRecord::Base

  belongs_to :review

end
