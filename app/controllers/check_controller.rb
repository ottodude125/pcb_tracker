########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: check_controller.rb
#
# This contains the logic to create, modify, and delete checks.
#
# $Id$
#
########################################################################

class CheckController < ApplicationController

  before_filter :verify_admin_role


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the check from the database for display.
  #
  # Parameters from params
  # ['id'] - Used to identify the check to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def edit

    @check = Check.find(params['id'])

  end


  ######################################################################
  #
  # insert_check
  #
  # Description:
  # This method takes the new check from the browser, adjusts the sort_order
  # for all the checks the follow the new check, and inserts the check in 
  # the database.
  #
  # Parameters from params
  # ['check']['id'] - Identifies the existing check.  The new check will
  #                   be inserted in front of this check.
  # ['new_check']   - Contains the information to be stored with the new
  #                   check.
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def insert_check

    @new_check = params['new_check']

    @existing_check = Check.find(params['check']['id'])
    @new_check['section_id']    = @existing_check.section_id
    @new_check['subsection_id'] = @existing_check.subsection_id
    @new_check['sort_order']    = @existing_check.sort_order

    # Update all of the checks that will follow the new check
    checks = 
      Check.find(:all,
                 :conditions => "subsection_id=#{@existing_check.subsection_id} and " +
                                "sort_order >= #{@existing_check.sort_order}",
                 :order      => 'sort_order ASC');

    checks.each { |check| check.update_attribute('sort_order', (check.sort_order+1)) }

    new_ch = Check.create(params['new_check'])

    if new_ch.errors.empty?
      new_ch.section.checklist.increment_checklist_counters(new_ch, 1)

      flash['notice'] = 'Inserted check successfully.'
      redirect_to(:action => 'modify_checks',
                  :id     => params['new_check']['subsection_id'])
    else
      flash['notice'] = 'Insert check failed - contact DTG'
      redirect_to(:action => 'insert', :id => params['check']['id'])
    end
  end


  ######################################################################
  #
  # insert
  #
  # Description:
  # This method retrieves the check that the user has identified to 
  # follow the new check in the list of check.  The new check is created
  # and loaded with initial values and the insert screen is displayed.
  #
  # Parameters from params
  # ['id'] - Used to identify the check existing check; the new check
  #          will be inserted into the list before this check.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def insert

    @check = Check.find(params['id'])
      
    @new_check = @check.dup
    @new_check.title = ''
    @new_check.check = ''
    @new_check.url   = ''

  end


  ######################################################################
  #
  # append_check
  #
  # Description:
  # This method takes the new check from the browser, adjusts the sort_order
  # for all the checks the follow the new check, and inserts the check in 
  # the database.
  #
  # Parameters from params
  # ['check']['id'] - Identifies the existing check.  The new check will
  #                   be inserted in front of this check.
  # ['new_check']   - Contains the information to be stored with the new
  #                   check.
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def append_check

    @new_check = params['new_check']

    @existing_check = Check.find(params['check']['id'])
    @new_check['section_id']    = @existing_check.section_id
    @new_check['subsection_id'] = @existing_check.subsection_id
    @new_check['sort_order']    = @existing_check.sort_order + 1

    # Update all of the checks that will follow the new check
    checks = 
      Check.find(:all,
                 :conditions => "subsection_id=#{@existing_check.subsection_id} and " +
                                "sort_order >= #{@new_check['sort_order']}",
                 :order      => 'sort_order ASC')

    checks.each { |check| check.update_attribute('sort_order', (check.sort_order+1)) }

    new_ch = Check.create(params['new_check'])

    if new_ch.errors.empty?
      new_ch.section.checklist.increment_checklist_counters(new_ch, 1)
      flash['notice'] = 'Appended check successfully.'
      redirect_to(:action => 'modify_checks',
                  :id => params['new_check']['subsection_id'])
    else
      flash['notice'] = 'Append check failed - contact DTG'
      redirect_to(:action => 'append', :id => params['check']['id'])
    end

  end


  ######################################################################
  #
  # append
  #
  # Description:
  # This method retrieves the check that the user has identified to 
  # preceed the new check in the list of checks.  The new check is created
  # and loaded with initial values and the append screen is displayed.
  #
  # Parameters from params
  # ['id'] - Used to identify the check existing check; the new check
  #          will be inserted into the list after this check.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def append

    @check = Check.find(params['id'])

    @new_check = @check.dup
    @new_check.title = ''
    @new_check.check = ''
    @new_check.url   = ''

  end


  ######################################################################
  #
  # modify_checks
  #
  # Description:
  # This method determines if the subsection contains any checks.  If 
  # there is at least one check, the modify checks screen is displayed.
  # Otherwise the add first check screen is displayed.
  #
  # Parameters from params
  # ['id'] - Identifies the subsection.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def modify_checks

    @subsection = Subsection.find(params['id'])
    @checks = @subsection.checks.sort_by { |check| check.sort_order }

    redirect_to(:action =>'add_first', :id => @subsection.id) if @checks.size == 0

  end


  ######################################################################
  #
  # add_first
  #
  # Description:
  # This method creates a new check, preloads data from the subsection, and
  # displays the add_first screen.
  #
  # Parameters from params
  # ['id'] - Identifies the subsection.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def add_first

    @subsection = Subsection.find(params['id'])
    @section    = @subsection.section

    @new_check = Check.new(:title           => '',
                           :check           => '',
                           :dot_rev_check   => @subsection.dot_rev_check,
                           :date_code_check => @subsection.date_code_check,
                           :section_id      => @subsection.section_id,
                           :subsection_id   => @subsection.id,
                           :sort_order      => 1)

  end


  ######################################################################
  #
  # insert_first
  #
  # Description:
  # This method creates a new check, preloads data from the subsection, and
  # displays the add_first screen.
  #
  # Parameters from params
  # ['new_check']  - Contains the data the user filled in for the new check.
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

    new_check                  = params['new_check']
    new_check['section_id']    = params['section']['id']
    new_check['subsection_id'] = params['subsection']['id']
    new_check['sort_order']    = 1
    new_ch                     = Check.create(new_check)

    if new_ch.errors.empty?
       new_ch.section.checklist.increment_checklist_counters(new_ch, 1)
      flash['notice'] = 'Added first check successfully.'
      redirect_to(:controller => 'checklist', 
                  :action     => 'edit', 
                  :id         => params['section']['checklist_id'])
    else
      flash['notice'] = 'Add first check failed - contact DTG'
      redirect_to(:action => 'add_first', 
                  :id     => params['subsection']['id'])
    end
  end


  ######################################################################
  #
  # move_down
  #
  # Description:
  # This method is called when the user clicks the "move down" icon on
  # the modify checks screen.  The check's sort_order is swapped with 
  # the next check.
  #
  # Parameters from params
  # ['id'] - Identifies the check that moved down. 
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

    check      = Check.find(params['id'])
    next_sort  = check.sort_order + 1
    next_check = Check.find(:first,
                            :conditions => [
                              "subsection_id = ? AND sort_order = ?", 
                              check.subsection.id, 
                              next_sort])

    if check.update_attribute('sort_order', next_sort) && 
       next_check.update_attribute('sort_order', (next_sort - 1))
      flash['notice'] = 'Checks were re-ordered'
    else
      flash['notice'] = 'Check re-order failed'
    end

    redirect_to(:action => 'modify_checks', :id => check.subsection_id)
  end


  ######################################################################
  #
  # move_up
  #
  # Description:
  # This method is called when the user clicks the "move up" icon on
  # the modify checks screen.  The check's sort_order is swapped with 
  # the preceeding check.
  #
  # Parameters from params
  # ['id'] - Identifies the check that moved up. 
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

    check      = Check.find(params['id'])
    next_sort  = check.sort_order - 1
    next_check = Check.find(:first,
                            :conditions => [
                              "subsection_id = ? and sort_order = ?", 
                              check.subsection.id, 
                              next_sort])
    
    if check.update_attribute('sort_order', next_sort) &&
       next_check.update_attribute('sort_order', (next_sort + 1))
      flash['notice'] = 'Checks were re-ordered'
    else
      flash['notice'] = 'Check re-order failed'
    end
    
    redirect_to(:action => 'modify_checks', :id => check.subsection_id)
  end


  ######################################################################
  #
  # destroy
  #
  # Description:
  # This method is called when the user clicks the "delete" icon on
  # the modify checks screen.  The sort_order for the checks that 
  # following the deleted check are updated to fill in the hole created 
  # by the deleted check.
  #
  # Parameters from params
  # ['id'] - Identifies the check that moved up. 
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def destroy

    check           = Check.find(params['id'])
    check_dup       = check.dup
    subsection_id   = check.subsection_id
    omit_sort_order = check.sort_order
    
    if check.destroy
      check_dup.section.checklist.increment_checklist_counters(check_dup, -1)
      flash['notice'] = 'Check deletion successful.'
    else
      flash['notice'] = 'Check deletion failed - Contact DTG'
    end

    # Update all of the checks that follow the deleted check
    checks = Check.find_all("subsection_id=#{subsection_id} and " +
                            "sort_order>#{omit_sort_order}")
    
    checks.each { |chk| chk.update_attribute('sort_order', (chk.sort_order-1)) }
    
    redirect_to(:action => 'modify_checks', :id => subsection_id)
  end


  ######################################################################
  #
  # destroy_list
  #
  # Description:
  # This method is called when the user clicks the "delete" icon for
  # an entire list of checks on the checklist edit screen.  All of the
  # checks in the subsection are removed.
  #
  # Parameters from params
  # ['id'] - Identifies the subsection whose checks are being removed.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def destroy_list
    
    subsection = Subsection.find(params['id'])

    if not subsection.checklist.released?

      subsection.checks.each do |check|
        subsection.checklist.increment_checklist_counters(check, -1)
      end
        
      if Check.destroy_all("subsection_id=#{subsection.id}")
        flash['notice'] = 'All checks deleted successfully'
      else
        flash['notice'] = 'Failure while deleting all checks - contact DTG'
      end
        
      redirect_to(:controller => 'checklist',
                  :action     => 'edit',
                  :id         => subsection.checklist_id)
    else
      flash['notice'] = 'This is a released checklist.  No checks were deleted.'
      redirect_to(:controller => 'checklist',
                  :action     => 'edit',
                  :id         => subsection.checklist_id)
    end
  end


  ######################################################################
  #
  # update
  #
  # Description:
  # This method is called when the user submits from the edit check
  # screen.  The database is updated with the changes made by the user.
  #
  # Parameters from params
  # ['check'] - Contains the udpated check data.
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

    @check = Check.find(params[:check][:id])
    params[:check][:url] = params[:check][:url].sub(/http:\/\//, '')

    if ! @check.section.checklist.released?
      @check.section.checklist.increment_checklist_counters(@check, -1)

      if @check.update_attributes(params[:check])
        @check.section.checklist.increment_checklist_counters(@check, 1)
        flash['notice'] = 'Check was successfully updated.'
        redirect_to(:action => 'modify_checks', :id => @check.subsection_id)
      else
        flash['notice'] = 'Check was not updated.'
        redirect_to(:action => 'edit')
      end
    else
      flash['notice'] = 'Check is locked.  The parent checklist is released.'
      redirect_to(:action => 'modify_checks', :id => @check.subsection_id)
    end

  end

end
