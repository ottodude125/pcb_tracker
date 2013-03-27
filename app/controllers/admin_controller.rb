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

  # Do not allow access to this controller unless the user is in the Admin
  # role.
  before_filter(:verify_admin_role)

end
