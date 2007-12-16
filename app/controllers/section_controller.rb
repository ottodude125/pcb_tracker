########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: section_controller.rb
#
# This contains the logic to create, modify, and delete sections.
#
# $Id$
#
########################################################################

class SectionController < ApplicationController

  before_filter :verify_admin_role


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the section from the database for display.
  #
  # Parameters from params
  # ['id'] - Used to identify the section to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def edit

    @section = Section.find(params[:id])
    @checklist = Checklist.find(@section.checklist_id)

  end


  ######################################################################
  #
  # update
  #
  # Description:
  # This method is called when the user submits from the edit section
  # screen.  The database is updated with the changes made by the user.
  #
  # Parameters from params
  # ['section] - Contains the udpated section data.
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
    @section = Section.find(params[:section][:id])
    params[:section][:url] = params[:section][:url].sub(/http:\/\//, '')
    if @section.update_attributes(params[:section])
      flash['notice'] = 'Section was successfully updated.'
    else
      flash['notice'] = 'Section not updated'
    end

    redirect_to(:controller => 'checklist', 
                :action     => 'edit',
                :id         => @section.checklist_id)
  end


  ######################################################################
  #
  # move_up
  #
  # Description:
  # This method is called when the user clicks the "move up" icon on
  # the modify checks screen.  The section  is swapped with the
  # preceeding section.
  #
  # Parameters from params
  # ['id'] - Identifies the section that moved up. 
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

    section = Section.find(params[:id])
    index   = section.checklist.sections.index(section)
    if section.checklist.sections[index].move_higher
      flash['notice'] = 'Sections were re-ordered'
    else
      flash['notice'] = 'Section re-order failed'
    end

    redirect_to(:controller => 'checklist', 
                :action     => 'edit', 
                :id         => section.checklist_id)
  end


  ######################################################################
  #
  # move_down
  #
  # Description:
  # This method is called when the user clicks the "move down" icon on
  # the modify checks screen.  The section is swapped with the
  # section that follows.
  #
  # Parameters from params
  # ['id'] - Identifies the section that moved up. 
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

    section = Section.find(params[:id])
    index   = section.checklist.sections.index(section)

    if section.checklist.sections[index].move_lower
      flash['notice'] = 'Sections were re-ordered'
    else
      flash['notice'] = 'Section re-order failed'
    end

    redirect_to(:controller => 'checklist', 
                :action     => 'edit', 
                :id         => section.checklist_id)
  end


  ######################################################################
  #
  # destroy
  #
  # Description:
  # This method is called when the user clicks the "delete" icon on
  # the modify checks screen.  The position for the sections that 
  # following the deleted section are updated to fill in the hole created 
  # by the deleted section.
  #
  # Parameters from params
  # ['id'] - Identifies the section to be deleted.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def destroy

    section = Section.find(params[:id])
    checklist_id = section.checklist_id

    if section.remove
      flash['notice'] = 'Section deletion successful.'
    else
      flash['notice'] = 'Section deletion failed - Contact DTG'
    end
      
    redirect_to(:controller => 'checklist',
                :action     => 'edit',
                :id         => checklist_id)
  end


  ######################################################################
  #
  # insert_section
  #
  # Description:
  # This method takes the new section from the browser, adjusts the position
  # for all the sections that follow the new section, and inserts the section in 
  # the database.
  #
  # Parameters from params
  # ['section']['id'] - Identifies the existing section.  The new section will
  #                     be inserted in front of this section.
  # ['new_section']   - Contains the information to be stored with the new
  #                     section.
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def insert_section

    new_section      = Section.new(params[:new_section])
    existing_section = Section.find(params[:section][:id])

    new_section.insert(existing_section.checklist_id,
                       existing_section.position)

    if new_section.errors.empty?
      flash['notice'] = 'Section insert successful.'
      redirect_to(:controller => 'checklist',
                  :action     => 'edit',
                  :id         => existing_section.checklist_id)
    else
      flash['notice'] = 'Section insert failed - Contact DTG'
      redirect_to(:controller => 'section',
                  :action     => 'insert',
                  :id         => existing_section.id)
    end
  end


  ######################################################################
  #
  # insert
  #
  # Description:
  # This method retrieves the section that the user has identified to 
  # follow the new section in the list of sections.  The new section is created
  # and loaded with initial values and the insert screen is displayed.
  #
  # Parameters from params
  # ['id'] - Used to identify the existing section; the new section
  #          will be inserted into the list before this section.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def insert

    @section = Section.find(params[:id])
    @checklist = Checklist.find(@section.checklist_id)
      
    @new_section = @section.dup
      
    @new_section.name             = ''
    @new_section.background_color = ''

  end


  ######################################################################
  #
  # append_section
  #
  # Description:
  # This method takes the new section from the browser, adjusts the position
  # for all the sections that follow the new section, and inserts the section
  # in the database.
  #
  # Parameters from params
  # ['section']['id'] - Identifies the existing section.  The new section will
  #                     be inserted in front of this section.
  # ['new_section']   - Contains the information to be stored with the new
  #                     section.
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def append_section

    new_section      = Section.new(params[:new_section])
    existing_section = Section.find(params[:section][:id])
    
    new_section.insert(existing_section.checklist_id, 
                       existing_section.position + 1) 

    if new_section.errors.empty?
      flash['notice'] = 'Section appended successfully.'
      redirect_to :controller => 'checklist', 
        :action     => 'edit',
        :id         => existing_section.checklist_id
    else
      flash['notice'] = 'Section append failed - Contact DTG'
      redirect_to :controller => 'section',
        :action     => 'append',
        :id         => existing_section.id

    end
  end


  ######################################################################
  #
  # append
  #
  # Description:
  # This method retrieves the section that the user has identified to 
  # preceed the new section in the list of sections.  The new section
  # is created and loaded with initial values and the append screen is 
  # displayed.
  #
  # Parameters from params
  # ['id'] - Used to identify the existing section; the new section
  #          will be inserted into the list after this section.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def append

    @section = Section.find(params[:id])
    @checklist = Checklist.find(@section.checklist_id)
      
    @new_section = @section.dup
      
    @new_section.name             = ''
    @new_section.background_color = ''

  end

end
