########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: prefix_controller.rb
#
# This contains the logic to create and modify board number prefix 
# information.
#
# $Id$
#
########################################################################

class PrefixController < ApplicationController

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
  # ['prefix'] - Used to identify the prefix to be updated.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update

    @prefix = Prefix.find(@params['prefix']['id'])

    if @prefix.update_attributes(@params['prefix'])
      flash['notice'] = 'Prefix was successfully updated.'
    else
      flash['notice'] = 'Prefix not updated'
    end

    redirect_to(:action => 'edit',
                :id     => @params["prefix"]["id"])
  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method uses the information passed back from the user
  # to create a new prefix in the database
  #
  # Parameters from @params
  # ['new_prefix'] - the information to be stored for the new prefix.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def create
    
    @prefix = Prefix.create(@params['new_prefix'])
    
    if @prefix.errors.empty?
      flash['notice'] = "Prefix #{@prefix.pcb_mnemonic} added"
      redirect_to :action => 'list'
    else
      flash['notice'] = @prefix.errors.full_messages.pop
      redirect_to :action => 'add'
    end
    
  end


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of prefixes from the database for
  # display.  The list is paginated and is limited to the number 
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
    
    @prefixes = Prefix.find_all(nil, 'pcb_mnemonic ASC')

  end


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the prefix from the database for display.
  #
  # Parameters from @params
  # ['id'] - Used to identify the prefix to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def edit 

    @prefix = Prefix.find(@params['id'])

  end


end
