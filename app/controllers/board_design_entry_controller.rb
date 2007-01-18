########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: board_design_entry_controller.rb
#
# This contains the logic that handles events from the outside world
# (user input), interacts with the board design entry model,
#  and displays the appropriate view to the user.
#
# $Id$
#
########################################################################

class BoardDesignEntryController < ApplicationController

  before_filter(:verify_logged_in)
  

  ######################################################################
  #
  # originator_list
  #
  # Description:
  # This method retrieves a list of boards from the database for
  # display.  
  # 
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def originator_list
    bde  = BoardDesignEntry.find_all_by_originator_id_and_state(
             session[:user].id, 'originated').sort_by { |e| e.design_name }
    bde += BoardDesignEntry.find_all_by_originator_id_and_state(
             session[:user].id, 'submitted').sort_by { |e| e.design_name }
    @board_design_entries = bde
  end


  ######################################################################
  #
  # processor_list
  #
  # Description:
  # This method retrieves a list of boards from the database for
  # display fot the PCB Input Gate (processor).  
  # 
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def processor_list
  
    if !allow_access()
      flash['notice'] = "Access Prohibited"
      return
    end
  
    bde  = BoardDesignEntry.find_all_by_state('originated').sort_by { |e| e.design_name }
    bde += BoardDesignEntry.find_all_by_state('submitted').sort_by { |e| e.design_name }
    bde += BoardDesignEntry.find_all_by_state('ready_to_post').sort_by { |e| e.design_name }
    @board_design_entries = bde
    
    @pre_art_review = ReviewType.find_by_name('Pre-Artwork')
  end


  ######################################################################
  #
  # destroy
  #
  # Description:
  # This method removes the entry from the table.  In addition, any 
  # information related to the entry is also cleaned up.
  # 
  # Parameters from params
  # id - the identifier for the board design entry.
  #
  ######################################################################
  #
  def destroy

    board_design_entry = BoardDesignEntry.find(params[:id])

    for bde_user in board_design_entry.board_design_entry_users
      bde_user.destroy
    end
    
    
    Document.find(board_design_entry.outline_drawing_document_id).destroy \
      if board_design_entry.outline_drawing_document_id?
    Document.find(board_design_entry.pcb_attribute_form_document_id).destroy \
      if board_design_entry.pcb_attribute_form_document_id?
    Document.find(board_design_entry.teradyne_stackup_document_id).destroy \
      if board_design_entry.teradyne_stackup_document_id?
    
    if board_design_entry.destroy

      flash['notice'] = 'The entry has been deleted from the database'
      TrackerMailer::deliver_originator_board_design_entry_deletion(
        board_design_entry.design_name,
        session[:user])
                                             
    else
      flash['notice'] = 'The request to delete the entry failed - Contact DTG'
    end
    
    redirect_to(:action => params[:return])

  end


  ######################################################################
  #
  # send_back
  #
  # Description:
  # This method removes the entry from the table.  In addition, any 
  # information related to the entry is also cleaned up.
  # 
  # Parameters from params
  # id - the identifier for the board design entry.
  # 
  # TODO: Only allow admins to access.
  #
  ######################################################################
  #
  def send_back

    if !allow_access()
      flash['notice'] = "Access Prohibited"
      return
    end

    @board_design_entry = BoardDesignEntry.find(params[:id])
    
  end
  
  
  ######################################################################
  #
  # return_entry_to_originator
  #
  # Description:
  # This method resets the state of the entry to 'orginated', updates
  # the processor's comment section and sends mail to the originator 
  # indicating that the entry has been returned for more information.
  # 
  # Parameters from params
  # id - the identifier for the board design entry.
  #
  ######################################################################
  #
  def return_entry_to_originator
  
    if !allow_access()
      flash['notice'] = "Access Prohibited"
      return
    end

    board_design_entry = BoardDesignEntry.find(params[:id])
    
    board_design_entry.originated
    board_design_entry.update_attribute('input_gate_comments', 
                                        params[:board_design_entry][:input_gate_comments])
  
    TrackerMailer::deliver_board_design_entry_return_to_originator(
      board_design_entry,
      session[:user])

    redirect_to(:action => 'processor_list')
  
  end


  ######################################################################
  #
  # get_design_id
  #
  # Description:
  # This method gathers the data for the first screen displayed when 
  # creating a new board entry.
  # 
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def get_design_id

    @board_design_entry = BoardDesignEntry.new(:entry_type  => 'new',
                                               :division_id => session[:user].division_id,
                                               :location_id => session[:user].location_id)

    @prefix_list   = Prefix.find_all_by_active(1).sort_by { |p|  p.pcb_mnemonic }
    @revision_list = Revision.find_all.sort_by            { |r|  r.name }

    @user_action = 'adding'
    @new_entry   = 'true'
    
  end
  
  
  ######################################################################
  #
  # new_entry
  #
  # Description:
  # This method gathers the initial information needed to create a new 
  # board.  
  # 
  # Parameters from params
  # id - the board directory identifier
  #
  ######################################################################
  #
  def new_entry
  
    @board_design_entry = BoardDesignEntry.find(params[:id])
    @user_action        = params[:user_action]

    @design_dir_list   = DesignDirectory.find_all_by_active(1).sort_by   { |dd| dd.name }
    @division_list     = Division.find_all_by_active(1).sort_by          { |d|  d.name }
    @incoming_dir_list = IncomingDirectory.find_all_by_active(1).sort_by { |id| id.name }
    @location_list     = Location.find_all_by_active(1).sort_by          { |l|  l.name }
    @platform_list     = Platform.find_all_by_active(1).sort_by          { |p|  p.name }
    @prefix_list       = Prefix.find_all_by_active(1).sort_by            { |p|  p.pcb_mnemonic }
    @product_type_list = ProductType.find_all_by_active(1).sort_by       { |pt| pt.name } 
    @project_list      = Project.find_all_by_active(1).sort_by           { |p|  p.name }
    @revision_list     = Revision.find_all.sort_by                       { |r|  r.name }

  end
  
  
  ######################################################################
  #
  # view_entry
  #
  # Description:
  # This action provides the data to view an entire board design entry.  
  # 
  # Parameters from params
  # None
  # 
  # TO DO: Functional Test
  #
  ######################################################################
  #
  def view_entry
  
    @board_design_entry = BoardDesignEntry.find(params[:id])
    @return             = params[:return]
    @originator         = User.find(@board_design_entry.originator_id)
    @managers           = @board_design_entry.managers
    @reviewers          = @board_design_entry.reviewers

  end



  ######################################################################
  #
  # create_board_design_entry
  #
  # Description:
  # This action validates the user's prefix and number entry.  If the
  # entries are invalid then the get_design_id view is redisplayed with
  # a message indicating why the input is invalid.  If the input is valid
  # the row is added to the board_design_entry table the the new_entry view
  # is displayed.  
  # 
  # Parameters from params
  # None
  # 
  ######################################################################
  #
  def create_board_design_entry
  
    @board_design_entry = BoardDesignEntry.new(params[:board_design_entry])
    @board_design_entry.entry_type = 'new'
    
    # Verify before continuing.
    #  - the required information was entered
    if !(@board_design_entry.prefix_id && @board_design_entry.valid_number?)

      notice = "The following information must be provided in order to proceed <br />"
      notice += "<ul>"
      notice += "  <li>PCB Mnemonic</li>"              if !@board_design_entry.prefix_id
      notice += "  <li>Number (must be 3 digits)</li>" if !@board_design_entry.valid_number?
      notice += "</ul>"
      flash['notice'] = notice
    
      @prefix_list   = Prefix.find_all_by_active(1).sort_by { |p|  p.pcb_mnemonic }
      @revision_list = Revision.find_all.sort_by            { |r|  r.name }

      @user_action = 'adding'
      @new_entry   = 'true'
      
      render(:action => 'get_design_id')
      return
    end

    
    board = Board.find_by_prefix_id_and_number(@board_design_entry.prefix_id,
                                               @board_design_entry.number)
                           
    if board
      @board_design_entry.platform_id = board.platform_id
      @board_design_entry.project_id  = board.project_id
      @board_design_entry.description = board.description
    end
    @board_design_entry.originator_id = session[:user].id
  
    @board_design_entry.save
    
    if @board_design_entry.errors.empty?
      
      flash['notice'] = "The design entry has been stored in the database"
        
      @board_design_entry.load_design_team
        
      redirect_to(:action      => 'new_entry', 
                  :id          => @board_design_entry.id,
                  :user_action => 'adding')
    else
    
      flash['notice'] = "There was an error storing the design entry - DTG has been notified."
      redirect_to(:controller => 'tracker', :action => 'index')
    
    end
        
  end
  
  
  ######################################################################
  #
  # edit_entry
  #
  # Description:
  # This action provides the data for the user to edit an entry.  
  # 
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def edit_entry
  
    @board_design_entry = BoardDesignEntry.find(params[:id])
    @user_action        = params[:user_action]
    @viewer             = params[:viewer]
    
    @design_dir_list   = DesignDirectory.find_all_by_active(1).sort_by   { |dd| dd.name }
    @division_list     = Division.find_all_by_active(1).sort_by          { |d|  d.name }
    @incoming_dir_list = IncomingDirectory.find_all_by_active(1).sort_by { |id| id.name }
    @location_list     = Location.find_all_by_active(1).sort_by          { |l|  l.name }
    @platform_list     = Platform.find_all_by_active(1).sort_by          { |p|  p.name }
    @prefix_list       = Prefix.find_all_by_active(1).sort_by            { |p|  p.pcb_mnemonic }
    @product_type_list = ProductType.find_all_by_active(1).sort_by       { |pt| pt.name } 
    @project_list      = Project.find_all_by_active(1).sort_by           { |p|  p.name }
    @revision_list     = Revision.find_all.sort_by                       { |r|  r.name }
    
    render(:action => 'new_entry')
  
  end
  
  
  ######################################################################
  #
  # update_entry
  #
  # Description:
  # This method stores the updated entry information.  
  # 
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def update_entry
  
    @board_design_entry = BoardDesignEntry.find(params[:id])
    bde                 = BoardDesignEntry.new(params[:board_design_entry])
    bde.id              = params[:id]
    @viewer             = params[:viewer]
    
    # Verify that the required information was submitted before proceeding.
    if !bde.division_id   || !bde.location_id           ||
       !bde.prefix_id     || !bde.revision_id           ||
       !bde.platform_id   || !bde.product_type_id       ||
       !bde.project_id    ||  bde.description.size == 0 ||
       !bde.valid_number?
       
      notice = "The following information must be provided in order to proceed <br />"
      notice += "<ul>"
      notice += "  <li>Board Description</li>"         if bde.description.size == 0
      notice += "  <li>Division</li>"                  if !bde.division_id
      notice += "  <li>Location</li>"                  if !bde.location_id
      notice += "  <li>PCB Mnemonic</li>"              if !bde.prefix_id
      notice += "  <li>Platform</li>"                  if !bde.platform_id
      notice += "  <li>Product Type</li>"              if !bde.product_type_id
      notice += "  <li>Project</li>"                   if !bde.project_id
      notice += "  <li>Revision</li>"                  if !bde.revision_id?
      notice += "  <li>Number (must be 3 digits)</li>" if !bde.valid_number?
      notice += "</ul>"
      flash['notice'] = notice
      
      @design_dir_list   = DesignDirectory.find_all_by_active(1).sort_by   { |dd| dd.name }
      @division_list     = Division.find_all_by_active(1).sort_by          { |d|  d.name }
      @incoming_dir_list = IncomingDirectory.find_all_by_active(1).sort_by { |id| id.name }
      @location_list     = Location.find_all_by_active(1).sort_by          { |l|  l.name }
      @platform_list     = Platform.find_all_by_active(1).sort_by          { |p|  p.name }
      @prefix_list       = Prefix.find_all_by_active(1).sort_by            { |p|  p.pcb_mnemonic }
      @product_type_list = ProductType.find_all_by_active(1).sort_by       { |pt| pt.name } 
      @project_list      = Project.find_all_by_active(1).sort_by           { |p|  p.name }
      @revision_list     = Revision.find_all.sort_by                       { |r|  r.name }

      @board_design_entry = bde
      @new_entry   = 'true'
      @user_action = params[:user_action]
      render(:action => 'new_entry')
      
      return
      
    end
    
    if params[:user_action] == 'adding'
      # Verify that there is not another entry for the same design
      message = "find_by_prefix_id_and_number_and_revision_id_and_" +
                "numeric_revision_and_entry_type_and_eco_number"
      existing_entry = BoardDesignEntry.send(message,
                                             bde.prefix_id,
                                             bde.number,
                                             bde.revision_id,
                                             bde.numeric_revision,
                                             bde.entry_type,
                                             bde.eco_number)
      if existing_entry
       flash['notice'] = 'No update was made - the entry already exists'
       redirect_to(:action      => 'edit_entry',
                   :id          => @board_design_entry.id,
                   :user_action => 'adding',
                   :viewer      => @viewer)
        return
      end  
    end


    board = Board.find_by_prefix_id_and_number(bde.prefix_id, bde.number)  
    
    if bde.entry_type == 'new'
      if board && board.designs.size > 0
        last_design = board.designs.sort_by { |d| d.revision.name }.pop
        
        if last_design.revision.name > bde.revision.name
          flash['notice'] = "#{bde.design_name} not created - a newer revision exists in the system"    
          redirect_to(:action      => 'edit_entry',
                      :id          => @board_design_entry.id,
                      :user_action => 'adding',
                      :viewer      => @viewer)
          return
        end
      end
    elsif bde.entry_type == 'dot_rev' && !bde.numeric_revision
      flash['notice'] = "Entry not created - a numeric revision must be specified for a Dot Rev"
      redirect_to(:action      => 'edit_entry',
                  :id          => @board_design_entry.id,
                  :user_action => 'adding',
                  :viewer      => @viewer)
      return
    elsif bde.entry_type == 'date_code' && bde.eco_number == ''
      flash['notice'] = "Entry not created - an ECO number must be specified for a Date Code entry"
      redirect_to(:action      => 'edit_entry',
                  :id          => @board_design_entry.id,
                  :user_action => 'adding',
                  :viewer      => @viewer)
      return
    end
    

    if board
      design = board.designs.detect { |design| 
        design.revision_id      == bde.revision_id      &&
        design.numeric_revision == bde.numeric_revision &&
        design.eco_number       == design.eco_number
      }

      if design
        flash['notice'] = "#{bde.design_name} duplicates an existing design - the database was not updated"
        redirect_to(:action      => 'edit_entry',
                    :id          => @board_design_entry.id,
                    :user_action => 'adding',
                    :viewer      => @viewer)
        return
      end
    end
    
    if bde.entry_type == 'new'
      bde.numeric_revision = 0
      bde.eco_number       = ''
      params[:board_design_entry][:numeric_revision] = 0
      params[:board_design_entry][:eco_number]       = ''
      
    end
    
    existing_entry = BoardDesignEntry.find_by_prefix_id_and_number_and_revision_id_and_numeric_revision_and_entry_type(
                       bde.prefix_id,
                       bde.number,
                       bde.revision_id,
                       bde.numeric_revision,
                       bde.entry_type)
                       
    if existing_entry && existing_entry.id != @board_design_entry.id

      flash['notice'] = "Update duplicates existing entry - changes were not saved"

      redirect_to(:action      => 'edit_entry',
                  :id          => @board_design_entry.id,
                  :user_action => 'adding',
                  :viewer      => @viewer)
  
    elsif @board_design_entry.update_attributes(params[:board_design_entry])

      flash['notice'] = "Entry #{@board_design_entry.design_name} has been updated"

      #Update the user's division and/or location if it has changed.
       if (session[:user].division_id != @board_design_entry.division_id ||
           session[:user].location_id != @board_design_entry.location_id)

        session[:user].division_id = @board_design_entry.division_id
        session[:user].location_id = @board_design_entry.location_id
 
        user = User.find(session[:user].id)
        user.division_id = @board_design_entry.division_id
        user.location_id = @board_design_entry.location_id
        user.password    = ''
        user.update

      end
      
      if params[:user_action] == 'adding'
        redirect_to(:action      => 'design_constraints',
                    :id          => @board_design_entry.id,
                    :user_action => 'adding')
      elsif params[:user_action] == 'updating'
        redirect_to(:action      => 'edit_entry',
                    :id          => @board_design_entry.id,
                    :user_action => 'updating',
                    :viewer      => @viewer)
      end
  
    end
  
  end


  ######################################################################
  #
  # entry_type_selected
  #
  # Description:
  # This action updates the entry type div when the user selects the 
  # entry type in an edit entry view.  
  # 
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def entry_type_selected
    @board_design_entry = BoardDesignEntry.find(params[:id])
    @board_design_entry.entry_type = params[:type]
    render(:layout => false)
  end


  ######################################################################
  #
  # process_make_from
  #
  # Description:
  # This action updates the make from div when the user selects a make 
  # from radio button in an edit entry view.  
  # 
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def process_make_from
    @board_design_entry = BoardDesignEntry.find(params[:id])
    @board_design_entry.make_from = params[:value] == "yes" ? 1 : 0
    render(:layout => false)
  end


  ######################################################################
  #
  # process_lead_free
  #
  # Description:
  # This action updates the make from div when the user selects a lead 
  # free radio button in an edit entry view.  
  # 
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def process_lead_free
    @board_design_entry = BoardDesignEntry.find(params[:id])
    @board_design_entry.lead_free_devices = params[:value] == "yes" ? 1 : 0
    render(:layout => false)
  end


  ######################################################################
  #
  # entry_input_checklist
  #
  # Description:
  # This action provides the data for the entry input checklist view.
  # 
  # Parameters from params
  # id - the board_design_entry id
  #
  ######################################################################
  #
  def entry_input_checklist
    @board_design_entry = BoardDesignEntry.find(params[:id])
  end


  ######################################################################
  #
  # set_review_team
  #
  # Description:
  # This action displays the form for gathering the names of reviewers
  # associated with the design entry.
  # 
  # Parameters from params
  # id - the board_design_entry id
  #
  ######################################################################
  #
  def set_review_team
  
    @board_design_entry = BoardDesignEntry.find(params[:id])
    @user_action        = params[:user_action]
        
    reviewer_roles  = Role.find_all_by_reviewer_and_manager_and_active(1, 0, 1).delete_if { |m| 
                        !m.send(@board_design_entry.entry_type+'_design_type?') }

    # TO DO: Add a way to for the tracker admins to specify roles with a 
    # default user.  If a role has a default user then do not present it to 
    # the originator for selection.  Use it to replace the following
    skip_roles = ['Compliance - EMC',
                  'Compliance - Safety',
                  'Library',
                  'PCB Input Gate',
                  'PCB Mechanical',
                  'SLM BOM',
                  'SLM-Vendor']
    reviewer_roles.delete_if { |rr| skip_roles.detect { |sr|  sr == rr.name} }
    
    @reviewers = []
    for role in reviewer_roles.sort_by { |r| r.display_name }
      entry_user = @board_design_entry.board_design_entry_users.detect{ |eu| eu.role_id == role.id }
      reviewer_id = entry_user ? entry_user.user_id : 0
      @reviewers << { :role          => role,
                      :reviewer_list => role.active_users,
                      :reviewer_id   => reviewer_id,
                      :required      => !entry_user || (entry_user && entry_user.required?) }
    end

  end
  
  
  ######################################################################
  #
  # set_management_team
  #
  # Description:
  # This action displays the form for gathering the names of managers
  # associated with the design entry.
  # 
  # Parameters from params
  # id - the board_design_entry id
  #
  ######################################################################
  #
  def set_management_team
  
    @board_design_entry = BoardDesignEntry.find(params[:id])
    @user_action        = params[:user_action]
    
    manager_roles = Role.find_all_by_manager_and_active(1, 1).delete_if { |m| 
                      !m.send(@board_design_entry.entry_type+'_design_type?') }

    # TO DO: Add a way to for the tracker admins to specify roles with a 
    # default user.  If a role has a default user then do not present it to 
    # the originator for selection.  Use it to replace the following
    manager_roles.delete_if { |r| r.name == "PCB Design"}
    
    @managers = []
    for role in manager_roles.sort_by { |r| r.display_name }
      entry_user = @board_design_entry.board_design_entry_users.detect{ |eu| eu.role_id == role.id }
      manager_id =  entry_user ? entry_user.user_id : 0
      @managers << { :role         => role,
                     :manager_list => role.active_users,
                     :manager_id   => manager_id }
    end

  end
  
  
  ######################################################################
  #
  # set_team_member
  #
  # Description:
  # This action is called in response to a user update to a team member 
  # role in the select menu of member names.  The member name is updated 
  # in the database and the row in the view is refreshed.  It is used 
  # for both managers and reviewers.  
  # 
  # Parameters from params
  # bde_id            - the board_design_entry id
  # id                - the member's user id
  # required_checkbox - a boolean used to determine if the 'required' 
  #                     checkbox should be displayed in the view.
  #
  ######################################################################
  #
  def set_team_member
  
    @board_design_entry = BoardDesignEntry.find(params[:bde_id])
    @role               = Role.find(params[:role_id])
    @member_id          = params[:id].to_i
    @member_list        = @role.active_users
    @required_checkbox  = params[:required_checkbox]
    
    @entry_user = @board_design_entry.board_design_entry_users.detect { |eu| eu.role_id == @role.id }

    if @entry_user
      @entry_user.user_id = @member_id
      @entry_user.update
    else
      @entry_user = BoardDesignEntryUser.new
      @entry_user.role_id               = @role.id
      @entry_user.user_id               = @member_id
      @entry_user.board_design_entry_id = @board_design_entry.id
      @entry_user.save
    end
  
    render(:layout => false)
  
  end
  
  
  ######################################################################
  #
  # set_role_required
  #
  # Description:
  # This action is called in response to a user checking the 
  # 'not required' checkbox for a reviewer role.  If the checkbox is 
  # checked the selection menu of reviewer names is removed and the name
  # column is filled with 'Not Required'.  If the checkbox is unchecked,
  # the selection menu of member names is displayed and the name of the 
  # current member is displayed in the name column.  
  # 
  # Parameters from params
  # bde_id            - the board_design_entry id
  # role_id           - the role id
  # required_checkbox - a boolean used to determine if the 'required' 
  #                     checkbox should be displayed in the view.
  #
  ######################################################################
  #
  def set_role_required

    @board_design_entry = BoardDesignEntry.find(params[:bde_id])
    @role               = Role.find(params[:role_id])
    @required_checkbox  = params[:required_checkbox]
  
    @entry_user = @board_design_entry.board_design_entry_users.detect { |eu| eu.role_id == @role.id }

    if @entry_user
      @entry_user.required = params[:required] == 'not_required' ? 0 : 1
      @entry_user.update
    else
      @entry_user = BoardDesignEntryUser.new
      @entry_user.role_id               = @role.id
      @entry_user.required              = params[:required] == 'required' ? 1 : 0
      @entry_user.board_design_entry_id = @board_design_entry.id
      @entry_user.save
    end

    render(:layout => false)
    
  end
  
  
  ######################################################################
  #
  # toggle_processor_checks
  #
  # Description:
  # This action is called in response to a processor updating the 
  # 'checked' checkbox in the entry view.  The database is updated and 
  # the up to date checkbox is redisplayed.  
  # 
  # Parameters from params
  # id    - the board_design_entry id
  # field - identifies the field that has benn checked
  #
  ######################################################################
  #
  def toggle_processor_checks

    @board_design_entry = BoardDesignEntry.find(params[:id])
    @field              = params[:field]
    
    @board_design_entry.update_attribute(
      @field, 
      (@board_design_entry[@field] == 0 ? 1 : 0))

    render(:layout => false)
    
  end
  
  
  ######################################################################
  #
  # view_attachments
  #
  # Description:
  # This action displays form to gather the attachments associated
  # with the design entry.
  # 
  # Parameters from params
  # id          - the board_design_entry id
  # user_action - keeps track of whether the user is adding or updating
  #
  ######################################################################
  #
  def view_attachments
  
    @board_design_entry = BoardDesignEntry.find(params[:id])
    @user_action        = params[:user_action]
    
    @outline_drawing_document = Document.find(@board_design_entry.outline_drawing_document_id)    \
      if @board_design_entry.outline_drawing_document_id?
    @pcb_attribute_document   = Document.find(@board_design_entry.pcb_attribute_form_document_id) \
      if @board_design_entry.pcb_attribute_form_document_id?
    @stackup_document         = Document.find(@board_design_entry.teradyne_stackup_document_id)   \
      if @board_design_entry.teradyne_stackup_document_id?
    
  end
  
  
  ######################################################################
  #
  # design_constraints
  #
  # Description:
  # This action displays a form to gather design constraint details for
  # the design entry.  
  # 
  # Parameters from params
  # id          - the board_design_entry id
  # user_action - keeps track of whether the user is adding or updating
  #
  ######################################################################
  #
  def design_constraints
  
    @board_design_entry = BoardDesignEntry.find(params[:id])
    @user_action        = params[:user_action]

  end
  
  
  ######################################################################
  #
  # view_originator_comments
  #
  # Description:
  # This action displays a form to gather originator comments for
  # the design entry.  
  # 
  # Parameters from params
  # id          - the board_design_entry id
  # user_action - keeps track of whether the user is adding or updating
  #
  ######################################################################
  #
  def view_originator_comments
  
    @board_design_entry = BoardDesignEntry.find(params[:id])
    @user_action        = params[:user_action]

  end
  
  
  ######################################################################
  #
  # submit_originator_comments
  #
  # Description:
  # This action stores the  originator comments for the design entry.  
  # 
  # Parameters from params
  # id                  - the board_design_entry id
  # originator_comments - the originator's comments
  #
  ######################################################################
  #
  def submit_originator_comments
  
    board_design_entry = BoardDesignEntry.find(params[:id])
    board_design_entry.update_attribute('originator_comments', 
                                        params[:board_design_entry][:originator_comments])
    
    if params[:user_action] == 'adding'
      redirect_to(:action => 'originator_list')
    else
      redirect_to(:action => 'view_entry', :id => params[:id])
    end
  
  end
  
  
  ######################################################################
  #
  # view_processor_comments
  #
  # Description:
  # This action displays a form to gather processor comments for
  # the design entry.  
  # 
  # Parameters from params
  # id          - the board_design_entry id
  # user_action - keeps track of whether the user is adding or updating
  #
  ######################################################################
  #
  def view_processor_comments
  
    @board_design_entry = BoardDesignEntry.find(params[:id])
    @user_action        = params[:user_action]

  end
  
  
  ######################################################################
  #
  # submit_processor_comments
  #
  # Description:
  # This action stores the processor comments for the design entry.  
  # 
  # Parameters from params
  # id                 - the board_design_entry id
  # processor_comments - the processor's comments
  #
  ######################################################################
  #
  def submit_processor_comments
  
    board_design_entry = BoardDesignEntry.find(params[:id])
    board_design_entry.update_attribute('input_gate_comments', 
                                        params[:board_design_entry][:input_gate_comments])
    
    redirect_to(:action => 'view_entry',
                :id     => params[:id],
                :viewer => 'processor')
  
  end
  
  
  ######################################################################
  #
  # submit
  #
  # Description:
  # This action submits the board design entry to PCB Design.  
  # 
  # Parameters from params
  # id - the board_design_entry id
  #
  ######################################################################
  #
  def submit
  
    board_design_entry = BoardDesignEntry.find(params[:id])
    board_design_entry.submitted
    
    TrackerMailer::deliver_board_design_entry_submission(board_design_entry)
    
    redirect_to(:action => 'originator_list')
  
  end
  
  
  ######################################################################
  #
  # update_yes_no
  #
  # Description:
  # This action sets the values for the design constraint questions and 
  # updates the row in the view identified by the field key of the params
  # hash.  
  # 
  # Parameters from params
  # id    - the board_design_entry id
  # field - identifies the design constraint that is being updated
  # value - the value that the user is setting the field to
  #
  ######################################################################
  #
  def update_yes_no

    @board_design_entry = BoardDesignEntry.find(params[:id])
    @field              = params[:field]
    
    @board_design_entry.update_attribute(@field, params[:value] == "Yes" ? 1 : 0)
    @board_design_entry.reload

    @new_value     = @board_design_entry.send(@field+'?') ? 'No'  : 'Yes'
    @current_value = @board_design_entry.send(@field+'?') ? 'Yes' : 'No'
     
    case @field
    
    when 'differential_pairs'
      @label         = 'Differential Pairs:'
      @checkbox_var  = :diff_pair
      @div_id        = :diff_pairs
    when 'controlled_impedance'
      @label         = 'Controlled Impedance:'
      @checkbox_var  = :controlled_imp
      @div_id        = :controlled_impedance
    when 'scheduled_nets'
      @label         = 'Scheduled Nets:'
      @checkbox_var  = :sched_nets
      @div_id        = :scheduled_nets
    when 'propagation_delay'
      @label         = 'Propagation Delay:'
      @checkbox_var  = :prop_delay
      @div_id        = :prop_delay
    when 'matched_propagation_delay'
      @label         = 'Matched Propagation Delay:'
      @checkbox_var  = :matched_prop_delay
      @div_id        = :matched_prop_delay
    end

    render(:layout => false)
  
  end
  
  
  ######################################################################
  #
  # add_document
  #
  # Description:
  # This action provides the information for the add_document view.  
  # 
  # Parameters from params
  # id          - the board_design_entry id
  # type        - identifies the document type
  # user_action - passing along the 'adding'/'updating' value
  #
  ######################################################################
  #
  def add_document
  
    @board_design_entry = BoardDesignEntry.find(params[:id])
    @document_type      = DocumentType.find_by_name(params[:type])
    @user_action        = params[:user_action]
  
  end
  
  
  ######################################################################
  #
  # save_document
  #
  # Description:
  # This action saves the document that the user selected for attachment.  
  # 
  # Parameters from params
  # id            - the board_design_entry id
  # document      - the document that will be attached
  # document_type - identifies the type of document that is being attached
  # user_action   - passing along the 'adding'/'updating' value
  # viewer        - passing along the 'processor'/'' value
  #
  ######################################################################
  #
  def save_document
  
    board_design_entry = BoardDesignEntry.find(params[:id])

    document = Document.new(params[:document])

    if document.data.size > Document::MAX_FILE_SIZE
      flash['notice'] = "The document was too large to attach - it must be smaller than #{Document::MAX_FILE_SIZE/2}"
    elsif document.name == ''
      flash['notice'] = 'No file was specified'
    else
      document.created_by = session[:user].id
      if document.save
        case params[:document_type]
        when 'Outline Drawing'
          board_design_entry.outline_drawing_document_id = document.id
        when 'PCB Attribute'
          board_design_entry.pcb_attribute_form_document_id = document.id
        when 'Stackup'
          board_design_entry.teradyne_stackup_document_id = document.id
        end
        board_design_entry.save
        
        flash['notice'] = "The document has been attached"
      else
        flash['notice'] = "An error occurred - the document was not attached"
      end
    end
    
    redirect_to(:action      => 'view_attachments', 
                :id          => board_design_entry.id,
                :user_action => params[:user_action],
                :viewer      => params[:viewer])
  
  end
  
  
  ######################################################################
  #
  # get_document
  #
  # Description:
  # This action retrieves the attached document for the user.
  # 
  # Parameters from params
  # id - the document id
  #
  ######################################################################
  #
  def get_document
  
   document = Document.find(params[:id])
   
   send_data(document.data.to_a.pack("H*"),
             :filename    => document.name,
             :type        => document.content_type,
             :disposition => "inline")
  
  end
  
  
  ######################################################################
  #
  # delete_document
  #
  # Description:
  # This action deletesthe document that the user selected for deletion.  
  # 
  # Parameters from params
  # type        - identifies the type of document that is being attached
  # user_action - passing along the 'adding'/'updating' value
  # viewer      - passing along the 'processor'/'' value
  #
  ######################################################################
  #
  def delete_document
  
    board_design_entry = BoardDesignEntry.find(params[:id])
    
    case params[:type]
    
    when 'Outline Drawing'
      document = Document.find(board_design_entry.outline_drawing_document_id)
      board_design_entry.outline_drawing_document_id = 0
    when 'PCB Attribute'
      document = Document.find(board_design_entry.pcb_attribute_form_document_id)
      board_design_entry.pcb_attribute_form_document_id = 0
    when 'Stackup'
      document = Document.find(board_design_entry.teradyne_stackup_document_id)
      board_design_entry.teradyne_stackup_document_id = 0
    end
    
    document.destroy
    board_design_entry.update

  
    redirect_to(:action      => 'view_attachments', 
                :id          => board_design_entry.id, 
                :user_action => params[:user_action],
                :viewer      => params[:viewer])
  
  
  end
  
  
  ######################################################################
  #
  # create_tracker_entry
  #
  # Description:
  # This action creates the tracker entry.  
  # 
  # Parameters from params
  # id            - the board_design_entry id
  # review_type   - a hash, accessed by review type name,used to track the 
  #                 reviews that the user wants to include if set to 1 
  #                 (or exclude if set to 0)
  # priority      - indicates the criticality of the design
  # audit         - the value for the skip audit checkbox.  Set to '1' if 
  #                 the user wants to skip the audit.
  #
  ######################################################################
  #
  def create_tracker_entry
  
    board_design_entry = BoardDesignEntry.find(params[:id])
    flash['notice'] = ''
    
    # Check to see if the board exists,  if it does not exist, then create
    # the board.
    board = Board.find_by_prefix_id_and_number(board_design_entry.prefix_id,
                                               board_design_entry.number)
    
    if board
      design = board.designs.detect { |d| 
        d.revision_id      == board_design_entry.revision_id &&
        d.numeric_revision == board_design_entry.numeric_revision &&
        d.eco_number       == board_design_entry.eco_number }
    end
    
    if board && design
      flash['notice'] = "The board and the design already exist - no action taken"
      redirect_to(:action => 'processor_list')
      return
    end
    
    # If the board does not exist then create.
    if !board
      board = Board.new(:prefix_id   => board_design_entry.prefix_id,
                        :number      => board_design_entry.number,
                        :platform_id => board_design_entry.platform_id,
                        :project_id  => board_design_entry.project_id,
                        :description => board_design_entry.description,
                        :active      => 1)
      if board.save
        flash['notice'] = "Board created ... "
      else
        flash['notice'] = "The board already exists - this should never occur"
        redirect_to(:action => 'processor_list')
        return
      end
    end
    
    # Update the board reviewers table for this board.
    ig_role = Role.find_by_name('PCB Input Gate')
    for reviewer_record in board_design_entry.board_design_entry_users

      next if !reviewer_record.required?

      board_reviewer = board.board_reviewers.detect { |br| br.role_id == reviewer_record.role_id }

      if !board_reviewer
      
        if reviewer_record.role_id != ig_role.id
          reviewer_id = reviewer_record.user_id
        else
          reviewer_id = session[:user].id
        end

        board_reviewer = BoardReviewer.new(:board_id    => board.id,
                                           :reviewer_id => reviewer_id,
                                           :role_id     => reviewer_record.role_id)
        board_reviewer.save
        
      elsif board_reviewer.reviewer_id != reviewer_record.user_id
      
        board_reviewer.update_attribute('reviewer_id', reviewer_record.user_id)

      end
      
    end
    
    # Create the design
    case board_design_entry.entry_type
    when 'new'
      type = 'New'
    when 'dot_rev'
      type = 'Dot Rev'
    when 'date_code'
      type = 'Date Code'
    end
    
    review_types = ReviewType.find_all_by_active(1, 'sort_order ASC')
    
    phase_id = Design::COMPLETE
    for review_type in review_types
      if params[:review_type][review_type.name] == '1'
        phase_id = review_type.id
        break
      end
    end
    
    design = Design.new(:board_id         => board.id,
                        :phase_id         => phase_id,
                        :revision_id      => board_design_entry.revision_id,
                        :numeric_revision => board_design_entry.numeric_revision,
                        :eco_number       => board_design_entry.eco_number,
                        :design_type      => type,
                        :priority_id      => params[:priority][:id],
                        :pcb_input_id     => session[:user][:id],
                        :created_by       => session[:user][:id])
                  
    if design.save
      flash['notice'] += "Design created ... "
      
      design.setup_design_reviews(params[:review_type], 
                                  board_design_entry.board_design_entry_users)
                                  
      # Create the links to the documents that were attached during board 
      # design entry.
      entry_doc_types = { :outline_drawing_document_id    => 'Outline Drawing', 
                          :pcb_attribute_form_document_id => 'PCB Attribute',
                          :teradyne_stackup_document_id   => 'Stackup' }
                          
      entry_doc_types.each { |message, document_type_name|
      
        document_id = board_design_entry.send(message)
        
        if document_id > 0
        
          document_type = DocumentType.find_by_name(document_type_name)
          DesignReviewDocument.new(
                            :board_id         => board.id,
                            :design_id        => design.id,
                            :document_type_id => document_type.id,
                            :document_id      => document_id).save
        end
      }
                                  
      checklist = Checklist.find_by_released(1, 'major_rev_number DESC')                            
      audit = Audit.new(:design_id    => design.id,
                        :checklist_id => checklist.id,
                        :skip         => params[:audit][:skip])
      if audit.save
        audit.create_checklist
      end
      
      board_design_entry.ready_to_post
      board_design_entry.design_id = design.id
      board_design_entry.update
      
    else
      flash['notice'] = "The design already exists - this should never occur"
      redirect_to(:action => 'processor_list')
      return
    end
    
    redirect_to(:action => 'processor_list')
  
  end
  
  
  ######################################################################
  #
  # design_setup
  #
  # Description:
  # This action retrieves the data forthe design setup view.  
  # 
  # Parameters from params
  # id            - the board_design_entry id
  #
  ######################################################################
  #
  def design_setup
  
    @board_design_entry = BoardDesignEntry.find(params[:id])
    @review_types       = ReviewType.find_all_by_active(1, 'sort_order ASC')
    @priorities         = Priority.find_all(nil, 'value ASC')
  
  end
  
  
  private
  
  def allow_access
  
    if session[:user].roles.detect { |r| r.name == 'Admin' }
      true
    else
      redirect_to(:controller => 'tracker', :action => 'index')
      false
    end
  
  end
  
  
end
