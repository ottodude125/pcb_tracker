########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: review_group_controller.rb
#
# This contains the logic to create and modify review groups.
#
# $Id$
#
########################################################################

class ReviewGroupController < ApplicationController

  before_filter :verify_admin_role

  ######################################################################
  #
  # update
  #
  # Description:
  # This method uses information passed back from the edit screen to
  # update the database.
  #
  # Parameters from params
  # ['review_group'] - Used to identify the review group to be updated.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update

    @review_group = ReviewGroup.find(params[:review_group][:id])

    if @review_group.update_attributes(params[:review_group])
      flash['notice'] = 'Update recorded'
    else
      flash['notice'] = 'Update failed'
    end

    redirect_to(:action => 'edit',
                :id     => params[:review_group][:id])
  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method uses the information passed back from the user
  # to create a new review group in the database
  #
  # Parameters from params
  # ['new_review_group'] - the information to be stored for the new 
  #                        review group.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def create

    @review_group = ReviewGroup.create(params[:new_review_group])

    if @review_group.errors.empty?
      flash['notice'] = "#{@review_group.name} added"
      redirect_to :action => 'list'
    else
      flash['notice'] = @review_group.errors.full_messages.pop
      redirect_to :action => 'add'
    end
    
  end


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of review groups from the database 
  # for display.  The list is paginated and is limited to the number 
  # passed to the ":per_page" argument.
  #
  # Parameters from params
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
    @review_groups = ReviewGroup.find(:all, :order => 'name')
  end


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the review group from the database for
  # display.
  #
  # Parameters from params
  # ['id'] - Used to identify the review group data to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def edit 

    @review_group = ReviewGroup.find(params[:id])

  end

end
