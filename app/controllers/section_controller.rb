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
  # Parameters from @params
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

    @section = Section.find(@params['id'])
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
  # Parameters from @params
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
    @section = Section.find(@params['section']['id'])
    if @section.update_attributes(@params['section'])
      flash['notice'] = 'Section was successfully updated.'
      redirect_to(:controller => 'checklist',
                  :action     => 'edit',
                  :id         => @params["section"]["checklist_id"])
    else
      flash['notice'] = 'Section not updated'
      redirect_to(:controller => 'checklist', 
                  :action     => 'edit',
                  :id         => @params["section"]["checklist_id"])
    end
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
  # Parameters from @params
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

    section = Section.find(@params['id'])
    next_sort = section.sort_order - 1
    next_section = Section.find(:first,
                                :conditions => [
                                  "checklist_id = ? AND sort_order = ?",
                                  section.checklist_id,
                                  next_sort])

    if section.update_attribute('sort_order', next_sort) &&
        next_section.update_attribute('sort_order', (next_sort + 1))
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
  # Parameters from @params
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

    section = Section.find(@params['id'])
    next_sort = section.sort_order + 1
    next_section = Section.find(:first,
                                :conditions => [
                                  "checklist_id = ? AND sort_order = ?",
                                  section.checklist_id,
                                  next_sort])

    if section.update_attribute('sort_order', next_sort) &&
        next_section.update_attribute('sort_order', (next_sort - 1))
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
  # the modify checks screen.  The sort_order for the sections that 
  # following the deleted section are updated to fill in the hole created 
  # by the deleted section.
  #
  # Parameters from @params
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

    section = Section.find(@params['id'])
    checklist_id = section.checklist_id

    sort_order = section.sort_order
    sections   = 
      Section.find_all("checklist_id=#{section.checklist_id} AND sort_order>#{sort_order}")

      for sect in sections
        new_sort_order = sect.sort_order - 1
        sect.update_attribute('sort_order', new_sort_order)
      end

    deleted_checks = Check.find_all("section_id=#{section.id}")
      for check in deleted_checks
        Checklist.increment_checklist_counters(check, -1)
      end

    if Check.destroy_all("section_id = #{section.id}")       &&
        Subsection.destroy_all("section_id = #{section.id}") &&
        section.destroy
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
  # This method takes the new section from the browser, adjusts the sort_order
  # for all the sections that follow the new section, and inserts the section in 
  # the database.
  #
  # Parameters from @params
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

    existing_sect = Section.find(@params['section']['id'])

    sections = Section.find_all("checklist_id=#{existing_sect['checklist_id']}")
      # Go through all of the sections and bump sort order by 1
      for section in sections
        if section.sort_order >= existing_sect['sort_order']
          section.update_attribute('sort_order', (section.sort_order+1))
        end
      end

    @params['new_section']['checklist_id'] = existing_sect['checklist_id']
    @params['new_section']['sort_order']   = existing_sect['sort_order']

    @new_section = Section.create(@params['new_section'])

    if @new_section.errors.empty?
      flash['notice'] = 'Section insert successful.'
      redirect_to :controller => 'checklist', 
        :action     => 'edit',
        :id         => existing_sect['checklist_id']
    else
      flash['notice'] = 'Section insert failed - Contact DTG'
      redirect_to :controller => 'section',
        :action     => 'insert',
        :id         => existing_sect['id']
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
  # Parameters from @params
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

    @section = Section.find(@params['id'])
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
  # This method takes the new section from the browser, adjusts the sort_order
  # for all the sections that follow the new section, and inserts the section
  # in the database.
  #
  # Parameters from @params
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

    existing_sect = Section.find(@params['section']['id'])

    sections = Section.find_all("checklist_id=#{existing_sect['checklist_id']}")
      # Go through all of the sections and bump sort order by 1
      for section in sections
        if section.sort_order > existing_sect['sort_order']
          section.update_attribute('sort_order', (section.sort_order+1))
        end
      end

    @params['new_section']['checklist_id'] = existing_sect['checklist_id']
    @params['new_section']['sort_order']   = existing_sect['sort_order'] + 1

    @new_section = Section.create(@params['new_section'])

    if @new_section.errors.empty?
      flash['notice'] = 'Section appended successfully.'
      redirect_to :controller => 'checklist', 
        :action     => 'edit',
        :id         => existing_sect['checklist_id']
    else
      flash['notice'] = 'Section append failed - Contact DTG'
      redirect_to :controller => 'section',
        :action     => 'append',
        :id         => existing_sect['id']

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
  # Parameters from @params
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

    @section = Section.find(@params['id'])
    @checklist = Checklist.find(@section.checklist_id)
      
    @new_section = @section.dup
      
    @new_section.name             = ''
    @new_section.background_color = ''

  end

end
