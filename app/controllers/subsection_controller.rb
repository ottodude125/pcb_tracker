########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: subsection_controller.rb
#
# This contains the logic to create, modify, and delete checklist
# subsections
#
# Revision History:
#    $Id$
#
########################################################################
class SubsectionController < ApplicationController

  before_filter :verify_admin_role



  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the subsection from the database for display
  # on the subsection edit screen.
  #
  # Parameters from params
  # ['id'] - Used to identify the subsection to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def edit
    @subsection = Subsection.find(params['id'])
  end


  ######################################################################
  #
  # update
  #
  # Description:
  # This method is called when the user submits from the edit subsection
  # screen.  The database is updated with the changes made by the user.
  #
  # Parameters from params
  # ['check'] - Contains the udpated subsection data.
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def update
    @subsection = Subsection.find(params[:subsection][:id])
    params[:subsection][:url] = params[:subsection][:url].sub(/http:\/\//, '')
    
    if @subsection.update_attributes(params[:subsection])
      flash['notice'] = 'Subsection was successfully updated.'
    else
      flash['notice'] = 'Subsection not updated'
    end
    
    redirect_to(:controller => 'checklist',
                :action     => 'edit',
                :id         => @subsection.checklist.id)
  end


  ######################################################################
  #
  # move_up
  #
  # Description:
  # This method is called when the user clicks the "move up" icon on
  # the edit checklist screen.  The subsectio's position is swapped with 
  # the preceeding subsection.
  #
  # Parameters from params
  # ['id'] - Identifies the subsection to moved up. 
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def move_up

    subsection = Subsection.find(params['id'])   
    index      = subsection.section.subsections.index(subsection)

    if subsection.section.subsections[index].move_higher
      flash['notice'] = 'Subsections were re-ordered'
    else
      flash['notice'] = 'Subsection re-order failed'
    end
    
    redirect_to(:controller => 'checklist', 
                :action     => 'edit', 
                :id         => subsection.checklist.id)
  end


  ######################################################################
  #
  # move_down
  #
  # Description:
  # This method is called when the user clicks the "move down" icon on
  # the edit checklist screen.  The subsection's position is swapped with 
  # the subsection that follows the subsection.
  #
  # Parameters from params
  # ['id'] - Identifies the subsection to moved down. 
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def move_down

    subsection = Subsection.find(params['id'])   
    index      = subsection.section.subsections.index(subsection)
    
    if subsection.section.subsections[index].move_lower
      flash['notice'] = 'Subsections were re-ordered'
    else
      flash['notice'] = 'Subsection re-order failed'
    end
    
    redirect_to(:controller => 'checklist', 
                :action     => 'edit', 
                :id         => subsection.checklist.id)
  end


  ######################################################################
  #
  # destroy
  #
  # Description:
  # This method is called when the user clicks the "delete" icon next 
  # to a subsection on the checklist edit screen.  The position for the 
  # that subsections following the deleted subsection are updated to fill 
  # in the hole created by the deleted subsection.
  #
  # Parameters from params
  # ['id'] - Identifies the subsection marked for deletion. 
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def destroy

    subsection   = Subsection.find(params['id'])   
    index        = subsection.section.subsections.index(subsection)
    checklist_id = subsection.checklist.id
    
    if subsection.remove
      flash['notice'] = 'Subsection deletion successful.'
    else
      flash['notice'] = 'Subsection deletion failed - Contact DTG'
    end
    
    redirect_to(:controller => 'checklist', :action => 'edit', :id => checklist_id)
    
  end


  ######################################################################
  #
  # create_first
  #
  # Description:
  # This method creates a new subsection, preloads data from the section, and
  # displays the add_first screen.
  #
  # Parameters from params
  # ['id'] - Identifies the section.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def create_first

    @section = Section.find(params[:id])

    @new_subsection = Subsection.new
    @new_subsection.section_id   = @section.id   
    @new_subsection.name         = ''
    @new_subsection.note         = ''
    
    @new_subsection.date_code_check = @section.date_code_check
    @new_subsection.dot_rev_check   = @section.dot_rev_check

  end


  ######################################################################
  #
  # insert_first
  #
  # Description:
  # This method creates a new subsection and inserts the record in 
  # the database.
  #
  # Parameters from params
  # ['section']    - Contains data used in the new check.
  # ['subsection'] - Contains data used in the new check.
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def insert_first
    
    new_subsection = Subsection.new(params[:new_subsection])
    new_subsection.insert(params[:section][:id], 1)

    if new_subsection.errors.empty?
      flash['notice'] = 'Subsection insert successful.'
      redirect_to(:controller => 'checklist',
                  :action     => 'edit',
                  :id         => new_subsection.checklist.id)
    else
      flash['notice'] = 'Subsection insert failed - Contact DTG'
      redirect_to(:action => 'create_first',
                  :id     => params[:section][:id])
    end

  end


  ######################################################################
  #
  # insert_subsection
  #
  # Description:
  # This method takes the new subsection from the browser, adjusts the 
  # position for all the subsections that follow the new subsection, 
  # and inserts the subsection in the database.
  #
  # Parameters from params
  # ['subsection']['id'] - Identifies the existing subsection.  The 
  #                        new subsection will be inserted in front of
  #                        this subsection.
  # ['new_subsection']   - Contains the information to be stored with the new
  #                        subsection.
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def insert_subsection


    new_subsection      = Subsection.new(params[:new_subsection])
    existing_subsection = Subsection.find(params[:subsection][:id])

    new_subsection.insert(existing_subsection.section_id, existing_subsection.position)

    if new_subsection.errors.empty?
      flash['notice'] = 'Subsection insert successful.'
      redirect_to(:controller => 'checklist', 
                  :action     => 'edit',
                  :id         => existing_subsection.checklist.id)
    else
      flash['notice'] = 'Subsection insert failed - Contact DTG'
      redirect_to(:action => 'insert',
                  :id     => existing_subsection.id)
    end
  end


  ######################################################################
  #
  # insert
  #
  # Description:
  # This method retrieves the subsection that the user has identified to 
  # follow the new subsection in the list of subsections.  The new 
  # subsection is created and loaded with initial values and the 
  # insert screen is displayed.
  #
  # Parameters from params
  # ['id'] - Used to identify the existing subsection; the new subsection
  #          will be inserted into the list before this subsection.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def insert

    @subsection = Subsection.find(params['id'])
    @section    = Section.find(@subsection.section_id)
    
    @new_subsection = @subsection.dup
    
    @new_subsection.name = ''
    @new_subsection.note = ''

  end


  ######################################################################
  #
  # append_subsection
  #
  # Description:
  # The existing subsection and the new subsection are posted.
  # This method uses the existing subsection to determine where
  # to insert the new subsection in the list.  This method will adjust
  # all of the position values for subsections that follow the 
  # new subsection in the list.
  #
  # Parameters from params
  # ['new_subsection'] - the new subsection
  # ['subsection']     - the existing subsection 
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def append_subsection

    new_subsection      = Subsection.new(params[:new_subsection])
    existing_subsection = Subsection.find(params[:subsection][:id])

    new_subsection.insert(existing_subsection.section_id, 
                          existing_subsection.position + 1)

    if new_subsection.errors.empty?
      flash['notice'] = 'Appended subsection successfully.'
      redirect_to(:controller => 'checklist', 
                  :action     => 'edit',
                  :id         => existing_subsection.checklist.id)
    else
      flash['notice'] = 'Subsection append failed - Contact DTG'
      redirect_to(:action => 'append',
                  :id     => existing_subsection.id)
    end
  end


  ######################################################################
  #
  # append
  #
  # Description:
  # This method retrieves the subsection that the user has identified to 
  # preceed the new subsection in the list of subsections.  The new 
  # subsection is created and loaded with initial values and the append
  # screen is displayed.
  #
  # Parameters from params
  # ['id'] - Used to identify the existing subsection; the new subsection
  #          will be inserted into the list after this subsection.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def append
    
    @subsection = Subsection.find(params['id'])
      
    @new_subsection = @subsection.dup
      
    @new_subsection.name = ''
    @new_subsection.note = ''

  end


end
