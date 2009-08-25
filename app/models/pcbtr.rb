########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: pcbtr.rb
#
# This file contains general information about the tracker.
#
# $Id$
#
########################################################################

class Pcbtr < ActiveRecord::Base

  MESSAGES = {
    :admin_only => 'Administrators only!  Check your role.'
  }

  def self.development_environment?
    ENV['RAILS_ENV']  == 'development'
  end
  
  def self.production_environment?
    ENV['RAILS_ENV'] == 'production'
  end

  def self.hostname
    $hostname ||= Socket.gethostname
  end


  if Pcbtr.production_environment?
    PCBTR_BASE_URL = 'http://boarddev.teradyne.com/pcbtr/'
    TRACKER_ROOT   = 'http://boarddev.teradyne.com/pcbtr'
    SENDER         = 'PCB_Tracker'
  else
    PCBTR_BASE_URL = 'http://boarddev-beta.teradyne.com/pcbtr/'
    TRACKER_ROOT   = 'http://boarddev-beta.teradyne.com/pcbtr/'
    SENDER         = 'DEVEL_PCB_Tracker'
  end
  EAVESDROP      = 'ron_dallas@notes.teradyne.com'

  
end
