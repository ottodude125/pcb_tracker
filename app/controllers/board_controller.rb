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
              :except => [:board_design_search,
                          :design_information,
                          :search_options,
                          :show_boards] )
  

  ######################################################################
  #
  # show_boards
  #
  # Description:
  # Collects the data to display the show boards page.
  # 
  # Parameters from params
  # type (pcb vs pcba)
  #
  ######################################################################
  #
  def show_boards

    @type = params[:type] || 'pcb'
    @type2 = @type=="pcb"?"pcba":"pcb"
    
    flash['notice'] = ''
    unique_part_numbers = PartNum.get_unique_part_numbers(@type)

    @columns = 8
    @rows    = (unique_part_numbers.size) / @columns
    @rows   += 1 if unique_part_numbers.size.remainder(@columns) > 0

    @part_numbers = []
    0.upto(@rows-1) { |row| @part_numbers[row] = [] }

    # Convert the information into a structure that can easily be displayed
    # in a table.
    col = 0
    row = 0
    unique_part_numbers.each_with_index do |element, i|

      @part_numbers[row][col] = element.number

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
    @type = params[:type] || 'pcb'
    @designs = PartNum.get_designs(params[:part_number],@type)
    
    flash['notice'] = 'Number of designs - ' + @designs.size.to_s
    if @designs.size.to_s == 0
      redirect_to(:action => 'show_boards')
    else
      # First sort the designs by name, then sort the reviews by review order.
      @designs = @designs.sort_by { |design| design.id }
      @detailed_name = @designs[0].detailed_name
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
    
    if (@logged_in_user && @logged_in_user.is_designer?)
      @designer = @logged_in_user
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
    
    condition = []
    condition << "platform_id=#{platform.id}" if platform
    condition << "project_id=#{project.id}"   if project
    conditions = condition.join(' AND ')
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

    #@board_list = board_list.sort_by { |b| [b.directory_name, b.id] }
    @board_list = board_list
    
  end
  
  
end
