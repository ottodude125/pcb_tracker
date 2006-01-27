########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: fab_house_controller.rb
#
# This contains the logic to create and modify fabrication houses.
#
# $Id$
#
########################################################################

class FabHouseController < ApplicationController

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
  # ['fab_house'] - Used to identify the fabrication house to be 
  #                 updated.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update

    @fab_house = FabHouse.find(@params['fab_house']['id'])

    if @fab_house.update_attributes(@params['fab_house'])
      flash['notice'] = 'Update recorded'
    else
      flash['notice'] = @fab_house.errors.full_messages.pop
    end

    redirect_to(:action => 'edit',
                :id     => @params["fab_house"]["id"])
  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method uses the information passed back from the user
  # to create a new fabrication house in the database
  #
  # Parameters from @params
  # ['new_fab_house'] - the information to be stored for the new 
  #                     fabrication house.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def create

    @fab_house = FabHouse.create(@params['new_fab_house'])

    if @fab_house.errors.empty?
      flash['notice'] = "#{@fab_house.name} added"
      redirect_to :action => 'list'
    else
      flash['notice'] = @fab_house.errors.full_messages.pop
      redirect_to :action => 'add'
    end
    
  end


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of fabrication houses from the database 
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
  #
  ######################################################################
  #
  def list

    @fab_house_pages, @fab_houses = paginate(:fab_houses,
                                             :per_page => 15,
                                             :order_by => 'name')

  end


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the fabrication house from the database for
  # display.
  #
  # Parameters from @params
  # ['id'] - Used to identify the fabrication house data to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def edit 

    @fab_house = FabHouse.find(@params['id'])

  end

end
