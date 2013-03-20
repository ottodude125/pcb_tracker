########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: prefix_controller.rb
#
# This contains the logic to create and modify board number prefix 
# information.
#
# $Id$
#
########################################################################

class PrefixController < ApplicationController

  before_filter :verify_admin_role


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of prefixes from the database for
  # display.  The list is paginated and is limited to the number 
  # passed to the ":per_page" argument.
  #
  # Parameters from params
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def list
    
    @prefixes = Prefix.get_prefixes

  end


end
