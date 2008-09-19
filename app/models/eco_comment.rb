########################################################################
#
# Copyright 2008, by Teradyne, Inc., North Reading MA
#
# File: eco_comment.rb
#
# This file maintains the state for eco comment.
#
# $Id$
#
########################################################################

class EcoComment < ActiveRecord::Base
  
  
  belongs_to :eco_task
  belongs_to :user
  
  
end
