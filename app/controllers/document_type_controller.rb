########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: document_type_controller.rb
#
# This contains the logic to create and modify document types.
#
# $Id$
#
########################################################################

class DocumentTypeController < ApplicationController

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
  # ['document_type'] - Used to identify the document type to be 
  #                     updated.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update

    @document_type = DocumentType.find(params[:document_type][:id])

    if @document_type.update_attributes(params[:document_type])
      flash['notice'] = 'Update recorded'
    else
      flash['notice'] = 'Update failed'
    end

    redirect_to(:action => 'edit',
		:id     => params[:document_type][:id])
  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method uses the information passed back from the user
  # to create a new document type in the database
  #
  # Parameters from params
  # ['new_document_type'] - the information to be stored for the new 
  #                         document type.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def create

    @document_type = DocumentType.create(params[:new_document_type])

    if @document_type.errors.empty?
      flash['notice'] = "#{@document_type.name} added"
      redirect_to :action => 'list'
    else
      flash['notice'] = @document_type.errors.full_messages.pop
      redirect_to :action => 'add'
    end
    
  end


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of document types from the database 
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
  #
  ######################################################################
  #
  def list

    @document_types = DocumentType.find(:all, :order => 'name')
  end


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the document type from the database for
  # display.
  #
  # Parameters from params
  # ['id'] - Used to identify the document type data to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def edit 

    @document_type = DocumentType.find(params[:id])

  end

end
