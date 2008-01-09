########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: division_controller.rb
#
# This contains the logic to create and modify division information.
#
# $Id$
#
########################################################################

class DivisionController < ApplicationController

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
    @divisions = Division.find(:all, :order => "name")
  end 


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the division from the database for display.
  #
  # Parameters from params
  # ['id'] - Used to identify the division to be retrieved.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def edit 
    @division = Division.find(params[:id])
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
  # ['division'] - Used to identify the division to be updated.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update
    @division = Division.find(params[:division][:id])

    if @division.update_attributes(params[:division])
      flash['notice'] = "Division #{@division.name} was successfully updated."
      redirect_to :action => 'edit', 
                  :id     => params[:division][:id]
    else
      flash['notice'] = @division.errors.full_messages.pop
      redirect_to :action => 'edit', 
                  :id     => params[:division][:id]
    end

  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method uses the information passed back from the user
  # to create a new division in the database
  #
  # Parameters from params
  # ['new_division'] - the information to be stored for the new division.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def create

    @division = Division.create(params[:new_division])

    if @division.errors.empty?
      flash['notice'] = "Division #{@division.name} added"
      redirect_to :action => 'list'
    else
      flash['notice'] = @division.errors.full_messages.pop
      redirect_to :action => 'add'
    end

  end
  

end
