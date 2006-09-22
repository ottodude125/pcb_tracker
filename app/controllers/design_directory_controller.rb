########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_directory_controller.rb
#
# This contains the logic to create and modify design directories.
#
# $Id$
#
########################################################################

class DesignDirectoryController < ApplicationController

  before_filter :verify_admin_role


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of design directories from the database for 
  # display.
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
    
    @design_directory_pages, @design_directories = paginate(:design_directory, 
					                                        :per_page => 15,
					                                        :order_by => "name")
  end 


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the design directory from the database for display.
  #
  # Parameters from @params
  # ['id'] - Used to identify the design directory to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def edit 
    @design_directory = DesignDirectory.find(@params['id'])
  end


  ######################################################################
  #
  # update
  #
  # Description:
  # This method updates the database with the modified design directory
  # information
  #
  # Parameters from @params
  # ['design_directory'] - Contains the information used to make the update.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def update
    @design_directory = DesignDirectory.find(@params['design_directory']['id'])

    if @design_directory.update_attributes(@params['design_directory'])
      flash['notice'] = 'Design Directory was successfully updated.'
      redirect_to :action => 'edit', 
                  :id     => @params["design_directory"]["id"]
    else
      flash['notice'] = @design_directory.errors.full_messages.pop
      redirect_to :action => 'edit', 
                  :id     => @params["design_directory"]["id"]
    end

  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method creates a new design directory in the database.
  #
  # Parameters from @params
  # ['new_design_directory'] - Contains the information used to make the
  #                            update.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def create

    @design_directory = DesignDirectory.create(@params['new_design_directory'])

    if @design_directory.errors.empty?
      flash['notice'] = "Design Directory #{@design_directory[:name]} added"
      redirect_to :action => 'list'
    else
      flash['notice'] = @design_directory.errors.full_messages.pop
      redirect_to :action => 'add'
    end
   
  end

  
end
