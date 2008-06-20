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

#PCBTR_BASE_URL = 'http://boarddev.teradyne.com/pcbtr/'
#SENDER         = 'PCB_Tracker'
EAVESDROP      = 'paul_altimonte@notes.teradyne.com'

  
# FOR DEVEL PLATFORM
PCBTR_BASE_URL = 'http://' + ENV['HOSTNAME'] + ':8000/'
SENDER         = 'DEVEL_PCB_TRACKER'


end
