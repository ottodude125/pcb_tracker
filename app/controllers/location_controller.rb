########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: location_controller.rb
#
# This contains the logic to create and modify location information.
#
# $Id$
#
########################################################################

class LocationController < ApplicationController

  before_filter :verify_admin_role


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of divisions from the database for
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

    @location_pages, @locations = paginate(:locations, 
                                           :per_page => 15,
                                           :order_by => "name")
  end 


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the location from the database for display.
  #
  # Parameters from params
  # ['id'] - Used to identify the location to be retrieved.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def edit 
    @location = Location.find(params[:id])
  end


  ######################################################################
  #
  # update
  #
  # Description:
  # This method uses information passed back from the edit screen to
  # update the database.
  #
  # Parameters from params
  # ['location'] - Used to identify the location to be updated.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update
    @location = Location.find(params[:location][:id])

    if @location.update_attributes(params[:location])
      flash['notice'] = "Location #{@location.name} was successfully updated."
      redirect_to :action => 'edit', 
                  :id     => params[:location][:id]
    else
      flash['notice'] = @location.errors.full_messages.pop
      redirect_to :action => 'edit', 
                  :id     => params[:location][:id]
    end

  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method uses the information passed back from the user
  # to create a new location in the database
  #
  # Parameters from params
  # ['new_location'] - the information to be stored for the new location.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def create

    @location = Location.create(params[:new_location])

    if @location.errors.empty?
      flash['notice'] = "Location #{@location.name} added"
      redirect_to :action => 'list'
    else
      flash['notice'] = @location.errors.full_messages.pop
      redirect_to :action => 'add'
    end

  end
  

end
