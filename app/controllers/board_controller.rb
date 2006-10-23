########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: board_controller.rb
#
# This contains the logic that handles events from the outside world
# (user input), interacts with the board model, and displays the 
# appropriate view to the user.
#
# $Id$
#
########################################################################

class BoardController < ApplicationController

before_filter(:verify_admin_role, 
              :except => [:auto_complete_for_board_name,
                          :board_design_search,
                          :design_information,
                          :search_options,
                          :show_boards] )
  
  auto_complete_for :board, :name


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of boards from the database for
  # display.  The list is paginated and is limited to the number 
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

    #    @board_pages, @boards = paginate(:boards,
    #				     :per_page => 15,
    #				     :order_by => '`prefixes`.`name` ASC, `boards`.`number` ASC',
    #				     :join => ' LEFT JOIN `prefixes` ON boards.prefix_id=prefixes.id')
    #    The wrong index is being stuffed into the link.
    #    For the time being, sort the boards based on the prefix/number combination.

    queried_boards = Board.find_all

    prefix_list = Array.new
    temp_boards = Hash.new
    for board in queried_boards
      if prefix_list[board.prefix_id] == nil
        prefix_list[board.prefix_id] = Prefix.find(board.prefix_id).pcb_mnemonic
      end

      temp_boards[prefix_list[board.prefix_id].to_s + board.number.to_s] = board
    end

    sorted_boards = temp_boards.sort
    i = 0
    sorted_boards.each { |k, v|
      queried_boards[i] = v
      i += 1
    }

    @board_pages, @boards = paginate_collection(queried_boards,
                                                :page => params[:page])
  end


  ######################################################################
  #
  # filtered_list
  #
  # Description:
  # This method retrieves a filtered list of boards from the database 
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
  def filtered_list

    conditions = ''

    if params['filter']['prefix_id'] != ''
      conditions = "prefix_id=#{params['filter']['prefix_id']}"
    end
    if params['filter']['platform_id'] != ''
      conditions += ' and ' if conditions != ''
      conditions += "platform_id=#{params['filter']['platform_id']}"
    end
    if params['filter']['project_id'] != ''
      conditions += ' and ' if conditions != ''
      conditions += "project_id=#{params['filter']['project_id']}"
    end

    if conditions == ''
      queried_boards = Board.find_all
    else
      queried_boards = Board.find_all(conditions)
    end

    prefix_list = Array.new
    temp_boards = Hash.new
    for board in queried_boards
      if prefix_list[board.prefix_id] == nil
        prefix_list[board.prefix_id] = Prefix.find(board.prefix_id).pcb_mnemonic
      end

      temp_boards[prefix_list[board.prefix_id].to_s + board.number.to_s] = board
    end

    sorted_boards = temp_boards.sort
    i = 0
    sorted_boards.each { |k, v|
      queried_boards[i] = v
      i += 1
    }

    @board_pages, @boards = paginate_collection(queried_boards,
                                                :page => params[:page])

    render(:action => 'list')
  end


  ######################################################################
  #
  # add
  #
  # Description:
  # This method retrieves the board from the database for display.
  #
  # Parameters from params
  # ['id'] - Used to identify the board to be retrieved.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def add

    @platforms = Platform.find_all('active=1',  'name ASC')
    @projects  = Project.find_all('active=1',   'name ASC')
    @prefixes  = Prefix.find_all('active=1',    'pcb_mnemonic ASC')
    @review_roles = Role.find_all('reviewer=1', 'name ASC')

    @reviewers = Array.new
    for role in @review_roles
      reviewer_list = Hash.new

      reviewers = Role.find_by_name("#{role.name}").active_users
      reviewer_list[:group]     = role.name
      reviewer_list[:id]        = role.id
      reviewer_list[:reviewers] = reviewers
      @reviewers.push(reviewer_list)
    end

    @fab_houses = FabHouse.find_all('active=1', 'name ASC')
    # fab_house_ids is used for the form - when adding, it's empty.
    @fab_house_ids = Array.new

    # Create the new board and set to active.
    @board = Board.new
    @board.active = 1

    render_action 'edit'

  end


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the board from the database for display.
  #
  # Parameters from params
  # ['id'] - Used to identify the board to be retrieved.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def edit

    @board = Board.find(params['id'])
    @platforms = Platform.find_all('active=1', 'name ASC')
    @projects  = Project.find_all('active=1',  'name ASC')
    @prefixes  = Prefix.find_all('active=1',   'pcb_mnemonic ASC')
    @review_roles = Role.find_all('reviewer=1', 'name ASC')

    reviewers = BoardReviewers.find_all("board_id=#{@board.id}")
      
    board_reviewers = Hash.new
    for reviewer in reviewers
      board_reviewers[Role.find(reviewer.role_id).name] = reviewer.reviewer_id
    end

    @reviewers = Array.new
    for role in @review_roles
      reviewer_list = Hash.new

      reviewers = Role.find_by_name("#{role.name}").active_users
      reviewer_list[:group]        = role.name
      reviewer_list[:id]           = role.id
      reviewer_list[:reviewers]    = reviewers
      reviewer_list[:reviewer_id]  = board_reviewers[role.name]
      @reviewers.push(reviewer_list)
    end

    board_fab_houses = @board.fab_houses
    @fab_house_ids = Array.new
    for fab_house in board_fab_houses
      @fab_house_ids.push(fab_house.id)
    end
    @fab_houses    = FabHouse.find_all('active=1', 'name ASC')

  end


  ######################################################################
  #
  # update
  #
  # Description:
  # This method uses information passed back from the edit screen to
  # update the database.
  #
  # Parameters from params
  # ['project'] - Used to identify the board to be updated.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update

    @board = Board.find(params['board']['id'])

    params['board'][:name] = Prefix.find(params['board']['prefix_id']).pcb_mnemonic +
      params['board'][:number]
    if @board.update_attributes(params['board'])
      
      params['board_reviewers'].each { |role_id, reviewer_id|
        role = Role.find(role_id)
        board_reviewer = BoardReviewers.find(:first,
                                             :conditions => [ "board_id = ? and role_id = ?", @board.id, role.id ])

        if board_reviewer
          if board_reviewer.reviewer_id != reviewer_id
            board_reviewer.update_attribute("reviewer_id", reviewer_id)
          end
        else
          new_board_reviewer = 
            BoardReviewers.new(:board_id    => @board.id,
                               :reviewer_id => reviewer_id,
                               :role_id     => role_id)
          new_board_reviewer.save
        end
      }

      # Process the fab houses.
      params['fab_house'].each { |fab_house_id, selected|
        fab_house = FabHouse.find(fab_house_id)

        if not @board.fab_houses.include?(fab_house)
          @board.fab_houses << fab_house  if selected == '1'
        else
          @board.remove_fab_houses(fab_house) if selected == '0'
        end
      }
      

      flash['notice'] = 'Board was successfully updated.'
    else
      flash['notice'] = 'Board not updated'
    end
    redirect_to(:action => 'edit',
                :id     => params["board"]["id"])
  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method uses the information passed back from the user
  # to create a new board in the database
  #
  # Parameters from params
  # ['new_project'] - the information to be stored for the new board.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def create

    @board = Board.new(params['board'])

    # Verify that the prefix ID is in the request.  For some reason, 
    # 'validates_presence_of :prefix_id' is not working from the model.
    prefix_id_present = params['board']['prefix_id'] != ''

    # Verify that all of the reviewers have a been selected
    reviewers = params['board_reviewers']
    for reviewer in reviewers
      all_reviewers_selected = reviewer[1] != ''
      break if not all_reviewers_selected
    end

    if all_reviewers_selected and prefix_id_present

      @board.name = Prefix.find(@board.prefix_id).pcb_mnemonic + @board.number
      @board.save

      if @board.errors.empty?

        for reviewer in reviewers
          board_reviewer = 
            BoardReviewers.new(:board_id    => @board.id,
                               :reviewer_id => reviewer[1],
                               :role_id     => Role.find(reviewer[0]).id)
          board_reviewer.save
        end

        # Record any fab house selections
        params['fab_house'].each { |fab_house_id, selected|
          @board.fab_houses << FabHouse.find(fab_house_id) if selected == '1'
        }

        flash['notice'] = "Board was successfully created"
        redirect_to :action => 'list'
      else
        flash['notice'] = @board.errors.full_messages.pop
        redirect_to :action => 'add'
      end

    elsif not all_reviewers_selected
      flash['notice'] = "Please make a selection for all reviewers - No board added"
      redirect_to :action => 'add'
    else 
      flash['notice'] = "Prefix can not be blank"
      redirect_to :action => 'add'      
    end
  end


  ######################################################################
  #
  # show_boards
  #
  # Description:
  # 
  #
  # Parameters from params
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def show_boards

    board_list = Board.find_all
    boards = Hash.new
    
    for board in board_list 
      boards[board.prefix.pcb_mnemonic] = Array.new if ! boards[board.prefix.pcb_mnemonic]
      boards[board.prefix.pcb_mnemonic] << board
    end
    
    @boards = boards.sort
    
    for board_list in @boards
      board_list[1] = board_list[1].sort_by { |board| board.number }
    end

  end



  ######################################################################
  #
  # design_information
  #
  # Description:
  # 
  #
  # Parameters from params
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def design_information

    #Get the board information
    if params[:board] != nil
      @board = Board.find_by_name(params[:board][:name])
    else
      @board = Board.find(params['board_id'])
    end
    
    # First sort the designs by name, then sort the reviews by review order.
    if @board
      @board.designs.sort_by { |d| d.name }
      for design in @board.designs
        design[:sorted_design_reviews] = 
          design.design_reviews.sort_by { |dr| dr.review_type.sort_order }
        
        # Get the design audit
        design[:audit] = Audit.find_by_design_id(design.id)
      end
    else
      flash['notice'] = "Please provide a board number"
      redirect_to 'action' => 'show_boards'
    end

  end
  
  
  ######################################################################
  #
  # search_options
  #
  # Description:
  # This method provides the lists of options available for searching.
  #
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def search_options
  
    designer_role = Role.find_by_name('Designer')
    @designers = designer_role.users.sort_by { |u| u.last_name }
    @platforms = Platform.find_all.sort_by   { |p| p.name }
    @projects  = Project.find_all.sort_by    { |p| p.name }
    
    @designer = session[:user] if session[:user].roles.detect { |r| r.name == 'Designer' }
  
  end


  ######################################################################
  #
  # board_design_search
  #
  # Description:
  # This method responds to the search_options view/form.  It uses the
  # selections made by the user to execute a search on boards.  The 
  # search is used to populate the board_design_search view.
  #
  # Parameters from params
  # [:platform][:id]       - if not an empty string then use the id 
  #                          provided in the database query.
  # [:project][:id]        - if not an empty string then use the id
  #                          provided in the database query.
  # [:user][:id]           - if not an empty string then use the id
  #                          provided in the database query.
  # [:review_type][:phase] - if 'All' then display all designs.
  #                          Otherwise, display only the designs that 
  #                          have completed the phase identified by
  #                          the parameter.
  #
  ######################################################################
  #
  def board_design_search
  
    @project  = 'All Projects'
    @platform = 'All Platforms'
    @designer = 'All Designers'
    
    if    params[:platform][:id] == '' && params[:project][:id] == ''
      board_list = Board.find_all
    elsif params[:platform][:id] != '' && params[:project][:id] == ''
      board_list = Board.find_all_by_platform_id(params[:platform][:id])
      @platform  = Platform.find(params[:platform][:id]).name
    elsif params[:platform][:id] == '' && params[:project][:id] != ''
      board_list = Board.find_all_by_project_id(params[:project][:id])
      @project   = Project.find(params[:project][:id])
    else
      board_list = Board.find_all_by_platform_id_and_project_id(
                     params[:platform][:id],
                     params[:project][:id])
      @platform  = Platform.find(params[:platform][:id]).name
      @project   = Project.find(params[:project][:id])
    end
    
    release_rt = ReviewType.find_by_name('Release')
    final_rt   = ReviewType.find_by_name('Final')
    for board in board_list 
      for design in board.designs
        if !(design.phase_id == Design::COMPLETE ||
             design.phase_id == release_rt.id)
          design[:designer_name] = design.designer.name
          design[:designer_id]   = design.designer.id
        else 
          final_review = design.design_reviews.detect { |dr| 
                           dr.review_type_id == final_rt.id }
          design[:designer_name] = final_review.designer.name
          design[:designer_id]   = final_review.designer.id
        end
      end
    end

    # If the designer was specified  then filter the list.
    if params[:user][:id] != ''
      @designer = User.find(params[:user][:id]).name
      for board in board_list
        board.designs.delete_if { |d| d[:designer_id] != params[:user][:id].to_i}
      end
    end

    # If a phase of "Final" or "Release" was specified then filter the list.
    if params[:review_type][:phase] != 'All'
      review_types          = ReviewType.find_all
      completed_review_type = review_types.detect { |rt| 
                                rt.name == params[:review_type][:phase] }
      review_types.delete_if { |rt| rt.sort_order <= completed_review_type.sort_order }

      for board in board_list
        for design in board.designs
          if design.phase_id != Design::COMPLETE
            if !review_types.detect { |rt| rt.id == design.phase_id }
              design[:delete_me] = true
            end
          end
        end
        board.designs.delete_if { |d| d[:delete_me] }
      end
    
    end
    
    @board_list = board_list.sort_by { |b| b.name }
    
  end
  
  
end
