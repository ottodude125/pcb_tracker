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

  before_filter(:verify_logged_in, :except => [ :view_entry ])
  before_filter(:verify_admin_role,
                :only => [ :process_entry_type,
                           :processor_list,
                           :return_entry_to_originator,
                           :send_back,
                           :set_entry_type ])
  

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
    @board_design_entries = BoardDesignEntry.get_user_entries(@logged_in_user)
    @other_entries        = BoardDesignEntry.get_other_pending_entries(@logged_in_user)
  end


  ######################################################################
  #
  # processor_list
  #
  # Description:
  # This method retrieves a list of boards from the database for
  # display for the PCB Input Gate (processor).  
  # 
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def processor_list
    @board_design_entries = BoardDesignEntry.get_entries_for_processor
    @pre_art_review       = ReviewType.get_pre_artwork
  end


  ######################################################################
  #
  # set_entry_type
  #
  # Description:
  # Gathers the information to display the Set Entry Type screen.
  # 
  # Parameters from params
  # id - the identifier for the board design entry.
  #
  ######################################################################
  #
  def set_entry_type
    @board_design_entry = BoardDesignEntry.find(params[:id])
  end
  
  
  ######################################################################
  #
  # display_prompt
  #
  # Description:
  # Called when the user clicks one of the radio buttons on the 
  # set entry type screen.
  # 
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def display_prompt
    render(:layout => false)
  end
  
  
  ######################################################################
  #
  # process_entry_type
  #
  # Description:
  # Called when the user selects the entry type from the set entry type
  # screen.
  # 
  # Parameters from params
  # id - the identifier for the board design entry.
  #
  ######################################################################
  #
  def process_entry_type
    
    board_design_entry = BoardDesignEntry.find(params[:id])
    entry_type = params[:design_type] == 'new' ? 'new' : 'dot_rev'
    message    = 'set_entry_type_' + entry_type
    
    board_design_entry.send(message)
    
    redirect_to(:action => 'design_setup', :id => board_design_entry.id)
    
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
  def delete_entry
    board_design_entry = BoardDesignEntry.find(:first, :conditions => { :id => params[:id] })
    pcb_number = board_design_entry.pcb_number
    if board_design_entry
      board_design_entry.board_design_entry_users.destroy_all
      board_design_entry.part_nums.destroy_all

      Document.find(board_design_entry.outline_drawing_document_id).destroy \
        if board_design_entry.outline_drawing_document_id?
      Document.find(board_design_entry.pcb_attribute_form_document_id).destroy \
        if board_design_entry.pcb_attribute_form_document_id?
      Document.find(board_design_entry.teradyne_stackup_document_id).destroy \
        if board_design_entry.teradyne_stackup_document_id?

      if board_design_entry.destroy

        flash['notice'] = 'The entry for ' + pcb_number + ' has been deleted from the database'
        BoardDesignEntryMailer::originator_board_design_entry_deletion(
          pcb_number,@logged_in_user).deliver

      else
        flash['notice'] = 'The request to delete the entry failed - Contact DTG'
      end
    else
      flash['notice'] = 'The entry could not be found'
    end
    redirect_to( url_for( :action => params[:return] ))

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
  ######################################################################
  #
  def send_back
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
  
    board_design_entry = BoardDesignEntry.find(params[:id])
    
    board_design_entry.originated
    board_design_entry.update_attribute('input_gate_comments', 
                                        params[:board_design_entry][:input_gate_comments])
    BoardDesignEntryMailer::board_design_entry_return_to_originator(
      board_design_entry, @logged_in_user).deliver

    redirect_to(:action => 'processor_list')
  
  end


  ######################################################################
  #
  # get_part_number
  #
  # Description:
  # Get the part number(s) for a board_design_entry
  # 
  # Parameters
  # None
  #
  ######################################################################
  #
  def get_part_number

    if params[:rows]
      @rows = params[:rows].values.collect { |row| PartNum.new(row) }
     else
      @rows = [ PartNum.new( :use => "pcb",  :revision => "a" ) ]
    end
    (@rows.size+1..5).each do
      @rows << PartNum.new( :use => "pcba",  :revision => "a" )
    end

    @heading       = "PCB Engineering - New Entry"
    @next_value    = "Next -->"
    @next_action   = { :action => 'create_board_design_entry' }
    @cancel_value  = "Cancel / Return to PCB Engineering Entry List"
    @cancel_action = { :action => 'originator_list'}
    @id            = ""
    render :template => 'shared/enter_part_numbers'
  end

  ######################################################################
  #
  # change_part_number
  #
  # Description:
  # Change the part number(s) for a board_design_entry
  #
  # Parameters
  # id => board_design_entry.id
  #
  ######################################################################
  #
  def change_part_numbers

    @board_design_entry   = BoardDesignEntry.find(params[:id])
    if ! params['pnums'].blank?
      @rows = params['pnums']
    else
      @rows = PartNum.find(:all,
      :conditions => { :board_design_entry_id => @board_design_entry.id},
      :order => "'use','prefix','number','dash'" )
    end
    #add more rows to make a total of 5
    (@rows.size+1..5).each do
      @rows << PartNum.new( :use => "pcba",  :revision => "a" )
    end
    @heading       = "PCB Engineering - Update Part Numbers"
    @next_value    = "Update Part Numbers"
    @next_action   = { :action => 'update_part_numbers', :id =>@board_design_entry.id}
    @cancel_value  = "Cancel / Return View Design Entry"
    @cancel_action = { :action => 'view_entry', :id =>@board_design_entry.id}
    render :template => 'shared/enter_part_numbers'
  end

  ######################################################################
  #
  # update_part_numbers
  #
  # Description:
  # Change the part number(s) for a board_design_entry
  #
  # Parameters
  # id => board_design_entry.id
  #
  ######################################################################
  #
  def update_part_numbers

    board_design_entry_id = params[:id]
    board_design_entry  = BoardDesignEntry.find(params[:id])

    #create part number objects from form data
    pnums = params[:rows].values.collect { |row| PartNum.new(row) }

    #check for a valid PCB part number
    pcb  = pnums.detect { |pnum| pnum.use == 'pcb' }
    unless pcb.valid_pcb_part_number?
      flash['notice'] = "A valid PCB part number like '123-456-78' must be specified"
      redirect_to( :action => 'change_part_numbers',
        :id => board_design_entry_id,
        :pnums => pnums ) and return
    end

    #a valid PCB part number was specified

    #check for duplicates already assigned
    fail = 0
    flash['notice'] = ''
    pnums.each do | pnum |
      if pnum.part_num_exists? == 1 &&
          PartNum.get_part_number(pnum).board_design_entry_id != board_design_entry_id
        flash['notice'] += "Part number #{pnum.name_string} exists<br>\n"
        fail = 1
      end
    end
    if fail == 1
      redirect_to( :action => 'change_part_numbers',
        :id => board_design_entry_id,
        :pnums => pnums ) and return
    end

    old_pcb_num = board_design_entry.pcb_number
    old_pcba_nums = board_design_entry.pcbas_string

    # delete the current part numbers for the design entry
    PartNum.delete_all(:board_design_entry_id => board_design_entry_id)

    #save and relate the partnumbers to the design
    fail = 0
    flash['notice'] = ''
    pnums.each do |pnum|
      unless pnum[:prefix] == ""
        pnum.board_design_entry_id = board_design_entry_id
        if ! pnum.save
          flash['notice'] += "Couldn't create part number #{pnum.name_string}"
          fail = 1
        end
      end
    end

    #create 'new' entries for notifier
    new_pcb_num = board_design_entry.pcb_number
    new_pcba_nums = board_design_entry.pcbas_string


    if fail == 1
      redirect_to( :action => 'change_part_numbers',
        :id => board_design_entry_id,
        :pnums => pnums ) and return
    else
      change = 0
      if old_pcb_num != new_pcb_num || old_pcba_nums != new_pcba_nums
        flash['notice'] = "The new part numbers have been assigned"
      else
        flash['notice'] = "The part numbers are unchanged"
      end
      redirect_to(:action      => 'view_entry',
        :id          => board_design_entry_id ) and return
    end
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
    @design_dir_list    = DesignDirectory.get_active_design_directories
    @division_list      = Division.get_active_divisions
    @incoming_dir_list  = IncomingDirectory.get_active_incoming_directories
    @location_list      = Location.get_active_locations
    @platform_list      = Platform.get_active_platforms
    @product_type_list  = ProductType.get_active_product_types
    @project_list       = Project.get_active_projects
    @revision_list      = Revision.get_revisions
    @hw_engineers       = User.get_hw_engineers(User.find(:all, :order => "last_name ASC"))

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
    @design_review_id   = params[:design_review_id]
    @originator         = @board_design_entry.user
    @managers           = @board_design_entry.manager_roles
    @reviewers          = @board_design_entry.reviewer_roles

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

    #check to ensure that a legal PCB part number was specified
    pcb = nil
    params[:rows].each_value do |row|
      unless row[:prefix] == ""
        pcb = PartNum.new(row) if row[:use] == "pcb"
      end
    end
    unless pcb && pcb.valid_pcb_part_number?
      flash['notice'] = "A valid PCB part number like '123-456-78' must be specified"
      redirect_to :action => 'get_part_number', :rows => params[:rows]
    else

      #PCB part number specified
      @board_design_entry = BoardDesignEntry.add_entry(@logged_in_user)

      if @board_design_entry
        #save and relate the partnumbers to the board design entry
        fail = 0
        @errors = []
        @rows   = []
        params[:rows].each_value do |pnum|
          unless pnum[:prefix] == ""
            num = PartNum.new(pnum)
            num.board_design_entry_id = @board_design_entry.id
            @rows << num
            if ! num.save
              fail = 1
              @errors << num.errors
            end
          end
        end

        flash['notice'] = "The design entry has been stored in the database"
        
        redirect_to(:action      => 'new_entry',
          :id          => @board_design_entry.id,
          :user_action => 'adding')
      else
        flash['notice'] = "Failed to create the board design entry"
        render(:action => 'get_part_number')

      end

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
    
    @design_dir_list   = DesignDirectory.get_active_design_directories
    @division_list     = Division.get_active_divisions
    @incoming_dir_list = IncomingDirectory.get_active_incoming_directories
    @location_list     = Location.get_active_locations
    @platform_list     = Platform.get_active_platforms
    @prefix_list       = Prefix.get_active_prefixes
    @product_type_list = ProductType.get_active_product_types
    @project_list      = Project.get_active_projects
    @revision_list     = Revision.get_revisions
    @hw_engineers      = User.get_hw_engineers(User.find(:all, :order => "last_name ASC"))
    
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
    bde.user_id         = @logged_in_user.id
    #bde.part_number_id  = @board_design_entry.part_number_id
    @viewer             = params[:viewer]
    
    # Verify that the required information was submitted before proceeding.
    if !bde.division_id   || !bde.location_id           ||
       !bde.revision_id   ||
       !bde.platform_id   || !bde.product_type_id       ||
       !bde.project_id    ||  bde.description.size == 0
       
      notice = "The following information must be provided in order to proceed <br />"
      notice += "<ul>"
      notice += "  <li>Board Description</li>"         if bde.description.size == 0
      notice += "  <li>Division</li>"                  if !bde.division_id
      notice += "  <li>Location</li>"                  if !bde.location_id
      notice += "  <li>Platform</li>"                  if !bde.platform_id
      notice += "  <li>Product Type</li>"              if !bde.product_type_id
      notice += "  <li>Project</li>"                   if !bde.project_id
      notice += "  <li>Revision</li>"                  if !bde.revision_id
      notice += "</ul>"
      flash['notice'] = notice
      
      @design_dir_list   = DesignDirectory.get_active_design_directories
      @division_list     = Division.get_active_divisions
      @incoming_dir_list = IncomingDirectory.get_active_incoming_directories
      @location_list     = Location.get_active_locations
      @platform_list     = Platform.get_active_platforms
      @prefix_list       = Prefix.get_active_prefixes
      @product_type_list = ProductType.get_active_product_types
      @project_list      = Project.get_active_projects
      @revision_list     = Revision.get_revisions

      @board_design_entry = bde
      @new_entry   = 'true'
      @user_action = params[:user_action]
      render(:action => 'new_entry')
      
      return
      
    end

    board = Board.find_by_prefix_id_and_number(bde.prefix_id, bde.number)  
    
    if bde.entry_type == 'new'
      if board && board.designs.size > 0
        last_design = board.designs.sort_by { |d| d.revision.name }.pop
        
        if last_design.revision.name > bde.revision.name
          flash['notice'] = "#{bde.full_name} not created - a newer revision exists in the system"    
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
    end
    

    if bde.entry_type == 'new'
      bde.numeric_revision = 0
      bde.eco_number       = ''
      params[:board_design_entry][:numeric_revision] = 0
      params[:board_design_entry][:eco_number]       = ''
      
    end
    
    if @board_design_entry.update_attributes(params[:board_design_entry])

      flash['notice'] = "Entry #{@board_design_entry.pcb_number} has been updated"

      #Update the user's division and/or location if it has changed.
      @logged_in_user.save_division(@board_design_entry.division_id)
      @logged_in_user.save_location(@board_design_entry.location_id)
      
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
    @title = "Review Team"
    @members  = []
    Role.get_open_reviewer_roles.each do |role|
      entry_user = @board_design_entry.board_design_entry_users.detect{ |eu| eu.role_id == role.id }
      @members << {  :role         => role,
                     :member_list  => role.active_users,
                     :member_id    => entry_user ? entry_user.user_id : 0,
                     :required     => !entry_user || (entry_user && entry_user.required?) }
    end
    @back_action = 'set_management_team',
    @next_action = 'view_attachments'

    render(:action => "set_team")
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
    @title = "Management Team"
    @members = []
    Role.get_open_manager_reviewer_roles.each do |role|
      entry_user = @board_design_entry.board_design_entry_users.detect{ |eu| eu.role_id == role.id }
      @members << { :role         => role,
                     :member_list => role.active_users,
                     :member_id   => entry_user ? entry_user.user_id : 0,
                     :required    => !entry_user || (entry_user && entry_user.required?) }
    end

    @back_action = 'design_constraints'
    @next_action = 'set_review_team'

    render(:action => "set_team")

  end
  
  
  ######################################################################
  #
  # set_team_member
  #
  # Description:
  # This action is called in response to a user update to a team member 
  # role in the select menu of member names.  The member name is updated 
  # in the database.  It is used for both managers and reviewers.  
  # 
  # Parameters from params
  # bde_id     - the board_design_entry id
  # user_id    - the member's user id
  # role_id    - the role id
  # req        - a boolean set to 0 if the 'not-required' checkbox was checked
  #
  ######################################################################
  #
  def set_team_member
  
    board_design_entry = BoardDesignEntry.find(params[:bde_id])
    role               = Role.find(params[:role_id])
    member_id          = params[:user_id].to_i
    required           = params[:req].to_i
    entry_user = board_design_entry.board_design_entry_users.detect {
      |eu| eu.role_id == role.id }

    if entry_user
      # change assignment
      entry_user.user_id = member_id
      entry_user.required = required
      entry_user.save
    else
      # create assignment
      entry_user = BoardDesignEntryUser.new
      entry_user.role_id               = role.id
      entry_user.user_id               = member_id
      entry_user.required              = required
      entry_user.board_design_entry_id = board_design_entry.id
      entry_user.save
    end
  
    render(:nothing => true)
  
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
    
    BoardDesignEntryMailer::board_design_entry_submission(board_design_entry).deliver
    
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
    
    @board_design_entry.update_attribute(@field, params[:value] )
    @board_design_entry.reload
   
    render(:nothing => true)
  
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

    document = Document.new(params[:document]) if (params[:document] != nil && params[:document][:document] != "" )

    if document && document.data.size > Document::MAX_FILE_SIZE
      flash['notice'] = "The document was too large to attach - it must be smaller than #{Document::MAX_FILE_SIZE/2}"
    elsif !document
      flash['notice'] = 'No file was specified'
    else
      document.created_by = @logged_in_user.id
      document.unpacked   = 0
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
   
   send_data(document.data,
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
    board_design_entry.save

  
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
    
    board = Board.new( :platform_id => board_design_entry.platform_id,
                       :project_id  => board_design_entry.project_id,
                       :description => board_design_entry.description,
                       :active      => 1 )
    if board.save
      flash['notice'] = "Board created ... "
    else
      flash['notice'] = "The board already exists - this should never occur"
      redirect_to(:action => 'processor_list')
      return
    end
    
    # Update the board reviewers table for this board.
    ig_role = Role.find_by_name('PCB Input Gate')
    board_design_entry.board_design_entry_users.each do |reviewer_record|

      next if !reviewer_record.required?

      board_reviewer = board.board_reviewers.detect { |br| br.role_id == reviewer_record.role_id }

      if !board_reviewer
      
        if reviewer_record.role_id != ig_role.id
          reviewer_id = reviewer_record.user_id
        else
          reviewer_id = @logged_in_user.id
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
    
    review_types = ReviewType.get_active_review_types
    
    phase_id = Design::COMPLETE
    review_types.each do |review_type|
      if params[:review_type][review_type.name] == '1'
        phase_id = review_type.id
        break
      end
    end
    
    design = Design.new(:board_id         => board.id,
                        #:part_number_id   => board_design_entry.part_number_id,
                        :phase_id         => phase_id,
                        :design_center_id => @logged_in_user.design_center_id,
                        :revision_id      => board_design_entry.revision_id,
                        :numeric_revision => board_design_entry.numeric_revision,
                        :eco_number       => board_design_entry.eco_number,
                        :design_type      => type,
                        :priority_id      => params[:priority][:id],
                        :pcb_input_id     => @logged_in_user.id,
                        :created_by       => @logged_in_user.id)
                  
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
                                                        
      audit = Audit.new(:design_id    => design.id,
                        :checklist_id => Checklist.latest_release.id,
                        :skip         => params[:audit][:skip])
      if audit.save
        audit.create_checklist
      end
      
      board_design_entry.ready_to_post
      board_design_entry.design_id = design.id
      board_design_entry.save

      #add the design id to the part numbers for the board_design_entry
      pcb_num=PartNum.get_bde_pcb_part_number(board_design_entry)
      pcb_num.design_id = design.id
      pcb_num.save
      PartNum.get_bde_pcba_part_numbers(board_design_entry).each do |pcba|
        pcba.design_id = design.id
        pcba.save
      end
      
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
    @review_types       = ReviewType.get_active_review_types
    @priorities         = Priority.get_priorities
  
  end


  private
  
  
end
