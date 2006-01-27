########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_center_controller.rb
#
# This contains the logic to create and modify design centers.
#
# $Id$
#
########################################################################

class DesignCenterController < ApplicationController


  before_filter :verify_admin_role

  ######################################################################
  #
  # update
  #
  # Description:
  # This method uses information passed back from the edit screen to
  # update the database.
  #
  # Parameters from @params
  # ['design_center'] - Used to identify the design center to be 
  #                     updated.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update

    @design_center = DesignCenter.find(@params['design_center']['id'])

    if @design_center.update_attributes(@params['design_center'])
      flash['notice'] = 'Update recorded'
    else
      flash['notice'] = 'Update failed'
    end

    redirect_to(:action => 'edit',
                :id     => @params["design_center"]["id"])
  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method uses the information passed back from the user
  # to create a new design center in the database
  #
  # Parameters from @params
  # ['new_design_center'] - the information to be stored for the new 
  #                         design center.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def create

    @design_center = DesignCenter.create(@params['new_design_center'])

    if @design_center.errors.empty?
      flash['notice'] = "#{@design_center.name} added"
      redirect_to :action => 'list'
    else
      flash['notice'] = @design_center.errors.full_messages.pop
      redirect_to :action => 'add'
    end
    
  end


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of design centers from the database 
  # for display.  The list is paginated and is limited to the number 
  # passed to the ":per_page" argument.
  #
  # Parameters from @params
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

    @design_center_pages, @design_centers = paginate(:design_centers,
                                                     :per_page => 15,
                                                     :order_by => 'name')

  end


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the design center from the database for
  # display.
  #
  # Parameters from @params
  # ['id'] - Used to identify the design center data to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def edit 

    @design_center = DesignCenter.find(@params['id'])

  end

end
