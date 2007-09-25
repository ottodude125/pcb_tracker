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
  ######################################################################
  #
  def list

    queried_boards = Board.find(:all)

    prefix_list = []
    temp_boards = {}
    queried_boards.each do |board|
      prefix_list[board.prefix_id] = board.prefix.pcb_mnemonic if !prefix_list[board.prefix_id]
      temp_boards[prefix_list[board.prefix_id].to_s + board.number.to_s] = board
    end

    @board_pages, @boards = paginate_collection(temp_boards.sort.collect { |sb| sb.pop },
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

    # Save the filter information for paging
    flash[:prefix_filter]   = flash[:prefix_filter]   ? flash[:prefix_filter]   : params[:filter][:prefix_id]
    flash[:platform_filter] = flash[:platform_filter] ? flash[:platform_filter] : params[:filter][:platform_id]
    flash[:project_filter]  = flash[:project_filter]  ? flash[:project_filter]  : params[:filter][:project_id]

    if flash[:prefix_filter] != ''
      conditions = "prefix_id=#{params[:filter][:prefix_id]}"
    end
    if flash[:platform_filter] != ''
      conditions += ' and ' if conditions != ''
      conditions += "platform_id=#{params[:filter][:platform_id]}"
    end
    if flash[:project_filter] != ''
      conditions += ' and ' if conditions != ''
      conditions += "project_id=#{params[:filter][:project_id]}"
    end

    if conditions == ''
      queried_boards = Board.find(:all)
    else
      queried_boards = Board.find_all(conditions)
    end

    prefix_list = []
    temp_boards = {}
    queried_boards.each do |board|
      prefix_list[board.prefix_id] = board.prefix.pcb_mnemonic if !prefix_list[board.prefix_id]
      temp_boards[prefix_list[board.prefix_id].to_s + board.number.to_s] = board
    end

    @board_pages, @boards = paginate_collection(temp_boards.sort.collect { |sb| sb.pop },
                                                :page => params[:page])

    render(:action => 'list')
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
  ######################################################################
  #
  def edit

    @board         = Board.find(params[:id])
    
    @fab_house_ids = @board.fab_houses.collect { |fh| fh.id }
    @fab_houses    = FabHouse.get_all_active
    @platforms     = Platform.get_all_active
    @projects      = Project.get_active_projects
    @prefixes      = Prefix.get_active_prefixes
    @review_roles  = Role.get_review_roles

    board_reviewers = {}
    @board.board_reviewers.each { |br| board_reviewers[br.role.name] = br.reviewer_id }

    @reviewers = []
    @review_roles.each do |role|
      board_reviewer = @board.role_reviewer(role.id)
      @reviewers.push({ :group       => role.name,
                        :id          => role.id,
                        :reviewers   => Role.find_by_name(role.name).active_users,
                        :reviewer_id => board_reviewers[role.name] })
    end

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
  ######################################################################
  #
  def update

    @board = Board.find(params[:board][:id])

    params[:board][:name] = Prefix.find(params[:board][:prefix_id]).pcb_mnemonic + params[:board][:number]
    
    if @board.update_attributes(params[:board])
      
      params[:board_reviewers].each do |role_id, reviewer_id|

        board_reviewer = @board.role_reviewer(role_id.to_i)
  
        if board_reviewer
          if board_reviewer.reviewer_id != reviewer_id
            board_reviewer.update_attribute("reviewer_id", reviewer_id)
          end
        else
          BoardReviewer.new(:board_id    => @board.id,
                            :reviewer_id => reviewer_id,
                            :role_id     => role_id).save
        end
        
      end

      # Process the fab houses.
      included_fab_houses = []
      excluded_fab_houses = []
      params[:fab_house].each do |fab_house_id, selected|
        fab_house = FabHouse.find(fab_house_id)

        if !@board.fab_houses.include?(fab_house)
          included_fab_houses << fab_house  if selected == '1'
        else
          excluded_fab_houses << fab_house  if selected == '0'
        end
      end
      @board.fab_houses << included_fab_houses
      @board.fab_houses.delete(excluded_fab_houses)

      flash['notice'] = 'Board was successfully updated.'
    else
      flash['notice'] = 'Board not updated'
    end
    
    redirect_to(:action => 'edit', :id => params[:board][:id])
    
  end


  ######################################################################
  #
  # show_boards
  #
  # Description:
  # Collects the data to display the show boards page.
  # 
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def show_boards
    
    flash['notice'] = ''
    unique_pcb_part_numbers = Design.get_unique_pcb_numbers

    @columns = 8
    @rows    = (unique_pcb_part_numbers.size) / @columns
    @rows   += 1 if unique_pcb_part_numbers.size.remainder(@columns) > 0

    @part_numbers = []
    0.upto(@rows-1) { |row| @part_numbers[row] = [] }

    # Convert the information into a structure that can easily be displayed
    # in a table.
    col = 0
    row = 0
    unique_pcb_part_numbers.each_with_index do |element, i|

      @part_numbers[row][col] = element

      row += 1
      if row == @rows
        row  = 0
        col += 1
      end
      
    end

  end



  ######################################################################
  #
  # design_information
  #
  # Description:
  # Handles the processing when a user clicks on a part number on the 
  # show boards page.
  #
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def design_information

    #Get the board information
    @designs = PartNumber.get_designs(params[:part_number])
    
    flash['notice'] = 'Number of designs - ' + @designs.size.to_s
    if @designs.size.to_s == 0
      redirect_to(:action => 'show_boards')
    else
      # First sort the designs by name, then sort the reviews by review order.
      @designs = @designs.sort_by { |design| design.id }
      @designs.each do |design|
        design[:sorted_design_reviews] = 
          design.design_reviews.sort_by { |dr| dr.review_type.sort_order }
        @detailed_name = design.detailed_name  
      end
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
    @platforms = Platform.find(:all, :order => :name)
    @projects  = Project.get_projects
    
    if (session[:user] && 
        session[:user].roles.detect { |r| r.name == 'Designer' })
      @designer = session[:user]
    else
      @designer = nil
    end

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
    
    if params[:platform][:id] != ''
      platform  = Platform.find(params[:platform][:id])
      @platform = platform.name
    end
    
    if params[:project][:id] != ''
      project  = Project.find(params[:project][:id])
      @project = project.name
    end
    
    conditions  = 'prefix_id>0'
    conditions += " AND platform_id=#{platform.id}" if platform
    conditions += " and project_id=#{project.id}"   if project
    board_list = Board.find(:all, :conditions => conditions)
   
    release_rt = ReviewType.get_release
    final_rt   = ReviewType.get_final
    board_list.each do |board|
      board.designs.each do |design|
        if !(design.complete? || design.in_phase?(release_rt))
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
      board_list.each do |board|
        board.designs.delete_if { |d| d[:designer_id] != params[:user][:id].to_i}
      end
    end

    # If a phase of "Final" or "Release" was specified then filter the list.
    if params[:review_type][:phase] != 'All'
      review_types          = ReviewType.get_review_types
      completed_review_type = review_types.detect { |rt| 
                                rt.name == params[:review_type][:phase] }
      review_types.delete_if { |rt| rt.sort_order <= completed_review_type.sort_order }

      board_list.each do |board|
        board.designs.delete_if do |design| 
          (!design.complete? && !review_types.detect { |rt| rt.id == design.phase_id })
        end
      end
    
    end

    @board_list = board_list.sort_by { |b| [b.name, b.id] }
    
  end
  
  
end
