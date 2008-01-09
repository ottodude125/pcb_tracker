########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: review_status_controller.rb
#
# This contains the logic to create and modify review status.
#
# $Id$
#
########################################################################

class ReviewStatusController < ApplicationController


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
  # ['review_status'] - Used to identify the review status to be 
  #                     updated.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update

    @review_status = ReviewStatus.find(params[:review_status][:id])

    if @review_status.update_attributes(params[:review_status])
      flash['notice'] = 'Update recorded'
    else
      flash['notice'] = @review_status.errors.full_messages.pop
    end

    redirect_to(:action => 'edit',
                :id     => params[:review_status][:id])
  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method uses the information passed back from the user
  # to create a new review status in the database
  #
  # Parameters from params
  # ['new_review_status'] - the information to be stored for the new 
  #                         review status.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def create

    @review_status = ReviewStatus.create(params[:new_review_status])

    if @review_status.errors.empty?
      flash['notice'] = "#{@review_status.name} added"
      redirect_to :action => 'list'
    else
      flash['notice'] = @review_status.errors.full_messages.pop
      redirect_to :action => 'add'
    end
    
  end


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of review statuses from the database 
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
    @review_statuses = ReviewStatus.find(:all, :order => 'name')
  end


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the review status from the database for
  # display.
  #
  # Parameters from params
  # ['id'] - Used to identify the review status data to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def edit 

    @review_status = ReviewStatus.find(params[:id])

  end

end
