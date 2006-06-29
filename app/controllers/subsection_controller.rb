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
  # Parameters from @params
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

    @subsection = Subsection.find(@params['id'])

  end


  ######################################################################
  #
  # update
  #
  # Description:
  # This method is called when the user submits from the edit subsection
  # screen.  The database is updated with the changes made by the user.
  #
  # Parameters from @params
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
    @subsection = Subsection.find(@params['subsection']['id'])
    if @subsection.update_attributes(@params['subsection'])
      flash['notice'] = 'Subsection was successfully updated.'
      redirect_to(:controller => 'checklist',
		  :action     => 'edit',
		  :id         => @params["subsection"]["checklist_id"])
    else
      flash['notice'] = 'Subsection not updated'
      redirect_to(:controller => 'checklist', 
		  :action     => 'edit',
		  :id         => @params["subsection"]["checklist_id"])
    end
  end


  ######################################################################
  #
  # move_up
  #
  # Description:
  # This method is called when the user clicks the "move up" icon on
  # the edit checklist screen.  The subsectio's sort_order is swapped with 
  # the preceeding subsection.
  #
  # Parameters from @params
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

    subsection = Subsection.find(@params['id'])
    next_sort = subsection.sort_order - 1
    other_sub = Subsection.find(:first,
                                :conditions => [
                                  "section_id = ? AND sort_order =?",
                                  subsection.section_id,
                                  next_sort])

    if subsection.update_attribute('sort_order', next_sort) &&
        other_sub.update_attribute('sort_order', (next_sort + 1))
      flash['notice'] = 'Subsections were re-ordered'
    else
      flash['notice'] = 'Subsection re-order failed'
    end
    
    redirect_to(:controller => 'checklist', 
                :action     => 'edit', 
                :id         => subsection.checklist_id)
  end


  ######################################################################
  #
  # move_down
  #
  # Description:
  # This method is called when the user clicks the "move down" icon on
  # the edit checklist screen.  The subsection's sort_order is swapped with 
  # the subsection that follows the subsection.
  #
  # Parameters from @params
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

    subsection = Subsection.find(@params['id'])
    next_sort = subsection.sort_order + 1
    other_sub = Subsection.find(:first,
                                :conditions => [
                                  "section_id = ? AND sort_order =?",
                                  subsection.section_id,
                                  next_sort])
    
    if subsection.update_attribute('sort_order', next_sort) &&
        other_sub.update_attribute('sort_order', (next_sort - 1))
      flash['notice'] = 'Subsections were re-ordered'
    else
      flash['notice'] = 'Subsection re-order failed'
    end
    
    redirect_to(:controller => 'checklist', 
                :action     => 'edit', 
                :id         => subsection.checklist_id)
  end


  ######################################################################
  #
  # destroy
  #
  # Description:
  # This method is called when the user clicks the "delete" icon next 
  # to a subsection on the checklist edit screen.  The sort_order for the 
  # that subsections following the deleted subsection are updated to fill 
  # in the hole created by the deleted subsection.
  #
  # Parameters from @params
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

    subsection = Subsection.find(@params['id'])
    checklist_id = subsection.checklist_id
    
    sort_order  = subsection.sort_order
    subsections =
      Subsection.find_all("section_id=#{subsection.section_id} " +
                          "AND sort_order>#{sort_order}")
      for subsect in subsections
        new_sort_order = subsect.sort_order - 1
        subsect.update_attribute('sort_order', new_sort_order)
      end 
    
      for check in subsection.checks
        subsection.checklist.increment_checklist_counters(check, -1)
      end 
    if Check.destroy_all("subsection_id = #{subsection.id}") &&
        subsection.destroy
      flash['notice'] = 'Subsection deletion successful.'
    else
      flash['notice'] = 'Subsection deletion failed - Contact DTG'
    end
    
    redirect_to(:controller => 'checklist', 
                :action     => 'edit', 
                :id         => checklist_id)
  end


  ######################################################################
  #
  # create_first
  #
  # Description:
  # This method creates a new subsection, preloads data from the section, and
  # displays the add_first screen.
  #
  # Parameters from @params
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

    @section = Section.find(@params['id'])

    @new_subsection = Subsection.new
    @new_subsection.section_id   = @section.id   
    @new_subsection.checklist_id = @section.checklist_id
    @new_subsection.name         = ''
    @new_subsection.note         = ''
    @new_subsection.sort_order   = 1
    
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
  # Parameters from @params
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
    
    section = Section.find(@params['section']['id'])
    new_subsection = @params['new_subsection'].dup
    new_subsection['sort_order']   = 1
    new_subsection['checklist_id'] = section.checklist_id
    new_subsection['section_id']   = section.id

    new_subsect = Subsection.create(new_subsection)
    
    if new_subsect.errors.empty?
      flash['notice'] = 'Subsection insert successful.'
      redirect_to(:controller => 'checklist',
                  :action => 'edit',
                  :id     => section.checklist_id)
    else
      flash['notice'] = 'Subsection insert failed - Contact DTG'
      redirect_to(:action => 'create_first',
                  :id     => section.id)
    end

  end


  ######################################################################
  #
  # insert_subsection
  #
  # Description:
  # This method takes the new subsection from the browser, adjusts the 
  # sort_order for all the subsections that follow the new subsection, 
  # and inserts the subsection in the database.
  #
  # Parameters from @params
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

    existing_sub = Subsection.find(@params['subsection']['id'])

    subsections = Subsection.find_all("section_id=#{existing_sub.section_id}")
      # Go through all of the subsections and bump sort order by 1
      # if the subsection follows the new subsection.
      for subsect in subsections
        if subsect.sort_order >= existing_sub.sort_order
          subsect.update_attribute('sort_order', (subsect.sort_order+1))
        end
      end

    @params['new_subsection']['checklist_id'] = existing_sub.checklist_id
    @params['new_subsection']['section_id']   = existing_sub.section_id
    @params['new_subsection']['sort_order']   = existing_sub.sort_order
    new_subsect = Subsection.create(@params['new_subsection'])

    if new_subsect.errors.empty?
      flash['notice'] = 'Subsection insert successful.'
      redirect_to(:controller => 'checklist', 
                  :action     => 'edit',
                  :id         => existing_sub.checklist_id)
    else
      flash['notice'] = 'Subsection insert failed - Contact DTG'
      redirect_to(:action => 'insert',
                  :id     => existing_sub.id)
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
  # Parameters from @params
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

    @subsection = Subsection.find(@params['id'])
    @section    = Section.find(@subsection.section_id)
    @checklist  = Checklist.find(@subsection.checklist_id)
    
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
  # all of the sort_order values for subsections that follow the 
  # new subsection in the list.
  #
  # Parameters from @params
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

    existing_sub = Subsection.find(@params['subsection']['id'])

    # Go through all of the subsections and bump sort order by 1
    # if the subsection follows the new subsection.
    subsections = 
      Subsection.find_all("section_id=#{existing_sub.section_id} and " +
                          "sort_order>#{existing_sub.sort_order}")
      for subsect in subsections
        subsect.update_attribute('sort_order', (subsect.sort_order+1))
      end

    @params['new_subsection']['checklist_id'] = existing_sub.checklist_id
    @params['new_subsection']['section_id']   = existing_sub.section_id
    @params['new_subsection']['sort_order']   = existing_sub.sort_order + 1
    subsect = Subsection.create(@params['new_subsection'])

    if subsect.errors.empty?
      flash['notice'] = 'Appended subsection successfully.'
      redirect_to(:controller => 'checklist', 
                  :action     => 'edit',
                  :id         => existing_sub.checklist_id)
    else
      flash['notice'] = 'Subsection append failed - Contact DTG'
      redirect_to(:action => 'append',
                  :id     => existing_sub.id)
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
  # Parameters from @params
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
    
    @subsection = Subsection.find(@params['id'])
      
    @new_subsection = @subsection.dup
      
    @new_subsection.name = ''
    @new_subsection.note = ''

  end



end
