########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: division.rb
#
# This file maintains the state for divisions.
#
# $Id$
#
########################################################################

class Division < ActiveRecord::Base

  validates_uniqueness_of :name
  validates_presence_of :name


  has_many :ftp_notifications
  has_many :users

end
