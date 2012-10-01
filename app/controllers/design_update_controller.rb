########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_update_controller.rb
#
# This contains the logic that handles events from the outside world
# (user input), interacts with the design update model, and displays the 
# appropriate view to the user.
#
# $Id$
#
########################################################################

class DesignUpdateController < ApplicationController


  ######################################################################
  #
  # list
  #
  # Description:
  # This method gathers the information for displaying a design update
  # list.
  #
  # Parameters from params
  # id - The design review ID.
  #
  ######################################################################
  #
  def list
  
    @design_review = DesignReview.find(params[:id])
    
    updates  = @design_review.design_updates + @design_review.design.design_updates
    @updates = updates.sort_by { |u| u.created_on }.reverse
  
    render(:layout => false)
    
  end

end
