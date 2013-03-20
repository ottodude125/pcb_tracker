########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: incoming_directory_controller.rb
#
# This contains the logic to create and modify incoming directories.
#
# $Id$
#
########################################################################

class IncomingDirectoryController < ApplicationController

  before_filter :verify_admin_role


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of incoming directories from the 
  # database for display.
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
    @incoming_directories = IncomingDirectory.find(:all, :order => "name")
  end 


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the incoming directory from the database for 
  # display.
  #
  # Parameters from params
  # ['id'] - Used to identify the incoming directory to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def edit 
    @incoming_directory = IncomingDirectory.find(params[:id])
  end


  ######################################################################
  #
  # update
  #
  # Description:
  # This method updates the database with the modified incoming directory
  # information
  #
  # Parameters from params
  # ['incoming_directory'] - Contains the information used to make the 
  #                          update.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def update
    @incoming_directory = IncomingDirectory.find(
                            params[:incoming_directory][:id])

    if @incoming_directory.update_attributes(params[:incoming_directory])
      flash['notice'] = 'Incoming Directory was successfully updated.'
      redirect_to :action => 'edit', 
                  :id     => params[:incoming_directory][:id]
    else
      flash['notice'] = @incoming_directory.errors.full_messages.pop
      redirect_to :action => 'edit', 
                  :id     => params[:incoming_directory][:id]
    end

  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method creates a new incoming directory in the database.
  #
  # Parameters from params
  # ['new_incoming_directory'] - Contains the information used to make the
  #                              update.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def create

    @incoming_directory = IncomingDirectory.create(params[:new_incoming_directory])

    if @incoming_directory.errors.empty?
      flash['notice'] = "Incoming Directory #{@incoming_directory[:name]} added"
      redirect_to :action => 'list'
    else
      flash['notice'] = @incoming_directory.errors.full_messages.pop
      redirect_to :action => 'add'
    end
   
  end

  
end
