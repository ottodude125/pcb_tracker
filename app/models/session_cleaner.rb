########################################################################
#
# Copyright 2008, by Teradyne, Inc., North Reading MA
#
# File: session_cleaner.rb
#
# This file provides the method to clean stale sessions.
#
# $Id$
#
########################################################################

class SessionCleaner
  
  # Remove stale Rail sessions
  # 
  # :call-seq:
  #   SessionCleaner.remove_stale_sessions(hours) -> boolean
  #
  # Returns a list of incomplete audits as an array.
  #
  # NOTE: Invoked from crontab every 15 minutes
  #       * 15 * * * ruby <full path>/script/runner -e production "SessionCleaner.remove_stale_sessions(8)"
  #
  def self.remove_stale_sessions(number_of_hours)
    ActiveRecord::SessionStore::Session.destroy_all(['updated_at < ?', number_of_hours.hours.ago])
  end
  
end