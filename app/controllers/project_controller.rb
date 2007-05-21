########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: project_controller.rb
#
# This contains the logic to create and modify project information.
#
# $Id$
#
########################################################################

class ProjectController < ApplicationController

  before_filter :verify_admin_role


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of projects from the database for
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

    @project_pages, @projects = paginate(:projects, 
					 :per_page => 15,
					 :order_by => "name")
  end 


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the project from the database for display.
  #
  # Parameters from params
  # ['id'] - Used to identify the project to be retrieved.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def edit 
    @project = Project.find(params[:id])
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
  # ['project'] - Used to identify the project to be updated.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update
    @project = Project.find(params[:project][:id])

    if @project.update_attributes(params[:project])
      flash['notice'] = "Project #{@project.name} was successfully updated."
      redirect_to :action => 'edit', 
                  :id     => params[:project][:id]
    else
      flash['notice'] = @project.errors.full_messages.pop
      redirect_to :action => 'edit', 
                  :id     => params[:project][:id]
    end

  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method uses the information passed back from the user
  # to create a new project in the database
  #
  # Parameters from params
  # ['new_project'] - the information to be stored for the new project.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def create

    @project = Project.create(params[:new_project])

    if @project.errors.empty?
      flash['notice'] = "Project #{@project.name} added"
      redirect_to :action => 'list'
    else
      flash['notice'] = @project.errors.full_messages.pop
      redirect_to :action => 'add'
    end

  end
  
end
