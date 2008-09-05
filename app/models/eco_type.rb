########################################################################
#
# Copyright 2008, by Teradyne, Inc., Boston MA
#
# File: eco_type.rb
#
# This file maintains the state for board reviewers.
#
# $Id$
#
########################################################################

class EcoType < ActiveRecord::Base
  
  
  has_and_belongs_to_many :eco_tasks
  
  
  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


  # Find active ECO Types
  # 
  # :call-seq:
  #   ECOType.find_find_all_active() -> array
  #
  # Returns a list of active ECO Types
  def self.find_active
    self.find(:all, :conditions => "active=1", :order => 'name')
  end
  
  
end
