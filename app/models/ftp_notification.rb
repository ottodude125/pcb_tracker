########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: ftp_notification.rb
#
# This file maintains the state for ftp notifications
#
# $Id$
#
########################################################################

class FtpNotification < ActiveRecord::Base

  belongs_to :design
  belongs_to :design_center
  belongs_to :division
  belongs_to :fab_house
  

end
