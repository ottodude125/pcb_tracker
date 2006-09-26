########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: priority_controller.rb
#
# This contains the logic to create and modify priorities.
#
# $Id$
#
########################################################################

class PriorityController < ApplicationController

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
  # ['priority'] - Used to identify the priority to be updated.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update

    @priority = Priority.find(@params['priority']['id'])
    
    if @priority.update_attributes(@params['priority'])
      flash['notice'] = 'Update recorded'
    else
      flash['notice'] = 'Update failed'
    end

    redirect_to(:action => 'edit',
                :id     => @params["priority"]["id"])
  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method uses the information passed back from the user
  # to create a new review type in the database
  #
  # Parameters from @params
  # ['new_priority'] - the information to be stored for the new 
  #                       reviw type.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def create

    @priority = Priority.create(@params['new_priority'])
    
    if @priority.errors.empty?
      flash['notice'] = "#{@priority.name} added"
      redirect_to :action => 'list'
    else
      flash['notice'] = @priority.errors.full_messages.pop
      redirect_to :action => 'add'
    end
    
  end


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of priorities from the database 
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
  # Validates the user is an Admin before proceeding.
  #
  ######################################################################
  #
  def list

    @priority_pages, @priorities = paginate(:priorities,
                                            :per_page => 15,
                                            :order_by => 'value')

  end


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the priority from the database for display.
  #
  # Parameters from @params
  # ['id'] - Used to identify the priority data to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def edit 

    @priority = Priority.find(@params['id'])

  end
end
