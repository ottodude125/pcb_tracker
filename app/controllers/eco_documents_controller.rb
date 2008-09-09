########################################################################
#
# Copyright 2005, by Teradyne, Inc., North Reading MA
#
# File: eco_documents_controller.rb
#
# This contains the logic that handles events from the outside world
# (user input), interacts with the eco task model, and displays the 
# appropriate view to the user.
#
# $Id$
#
########################################################################

class EcoDocumentsController < ApplicationController

  before_filter(:verify_logged_in)
 

  # DELETE /eco_tasks/1
  def destroy
    eco_document = EcoDocument.find(params[:id])
    eco_task     = eco_document.eco_task
    eco_document.destroy

    redirect_to edit_eco_task_path(eco_task)
  end
  
  
end