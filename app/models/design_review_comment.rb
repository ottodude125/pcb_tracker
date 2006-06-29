########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: designe_review_comment.rb
#
# This file maintains the state for users.
#
# $Id$
#
########################################################################

class DesignReviewComment < ActiveRecord::Base

  belongs_to :user

end
