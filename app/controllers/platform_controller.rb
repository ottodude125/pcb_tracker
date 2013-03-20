########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: platform_controller.rb
#
# This contains the logic to create and modify platforms.
#
# $Id$
#
########################################################################

class PlatformController < ApplicationController

  before_filter :verify_admin_role


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of platforms from the database for 
  # display.
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
    @platforms = Platform.find(:all, :order => "name")
  end 


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the platform from the database for display.
  #
  # Parameters from params
  # ['id'] - Used to identify the platform to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def edit 
    @platform = Platform.find(params[:id])
  end


  ######################################################################
  #
  # update
  #
  # Description:
  # This method updates the database with the modified platform
  # information
  #
  # Parameters from params
  # ['platform'] - Contains the information used to make the update.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def update
    @platform = Platform.find(params[:platform][:id])

    if @platform.update_attributes(params[:platform])
      flash['notice'] = 'Platform was successfully updated.'
      redirect_to :action => 'edit', 
                  :id     => params[:platform][:id]
    else
      flash['notice'] = @platform.errors.full_messages.pop
      redirect_to :action => 'edit', 
                  :id     => params[:platform][:id]
    end

  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method creates a new platform in the database.
  #
  # Parameters from params
  # ['new_platform'] - Contains the information used to make the
  #                    update.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def create

    @platform = Platform.create(params[:new_platform])

    if @platform.errors.empty?
      flash['notice'] = "Platform #{@platform[:name]} added"
      redirect_to :action => 'list'
    else
      flash['notice'] = @platform.errors.full_messages.pop
      redirect_to :action => 'add'
    end
   
  end

  
end
