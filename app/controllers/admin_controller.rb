########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: admin_controller.rb
#
# This contains the logic that handles events from the outside world
# (user input), interacts with the admin model, and displays the 
# appropriate view to the user.
#
# $Id$
#
########################################################################

class AdminController < ApplicationController


  ######################################################################
  #
  # index
  #
  # Description:
  # This method performs setup prior to display of the admin index page.
  #
  # Parameters from @params
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def index
  #  @session[:return_to] = "/admin/index"
  end
  
  
end
