########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: review_type_controller.rb
#
# This contains the logic to create and modify review types.
#
# $Id$
#
########################################################################

class ReviewTypeController < ApplicationController

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
  # ['review_type'] - Used to identify the review type to be updated.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update

    @review_type = ReviewType.find(params[:review_type][:id])

    if @review_type.update_attributes(params[:review_type])
      flash['notice'] = 'Update recorded'
    else
      flash['notice'] = @review_type.errors.full_messages.pop
    end

    redirect_to(:action => 'edit',
                :id     => params[:review_type][:id])
  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method uses the information passed back from the user
  # to create a new review type in the database
  #
  # Parameters from params
  # ['new_review_type'] - the information to be stored for the new 
  #                       reviw type.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def create

    @review_type = ReviewType.create(params[:new_review_type])

    if @review_type.errors.empty?
      flash['notice'] = "#{@review_type.name} added"
      redirect_to :action => 'list'
    else
      flash['notice'] = @review_type.errors.full_messages.pop
      redirect_to :action => 'add'
    end
    
  end


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of review types from the database 
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

    @review_type_pages, @review_types = paginate(:review_types,
                                                 :per_page => 15,
                                                 :order_by => 'sort_order')

  end


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the review type from the database for
  # display.
  #
  # Parameters from params
  # ['id'] - Used to identify the review type data to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def edit 

    @review_type = ReviewType.find(params[:id])

  end
end
