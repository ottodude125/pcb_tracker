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
                          :show_boards,
                          :get_stackup_attachment] )
  

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
    part_number = params[:part_number]
    @designs = PartNum.get_designs(part_number,@type)
    
    flash['notice'] = 'Number of designs - ' + @designs.size.to_s
    # First sort the designs by name, then sort the reviews by review order.
    @designs = @designs.sort_by { |design| design.id }
    if @designs.size == 0
      @detailed_name = "Part number prefix #{part_number} not found"
    else
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
    @review_types = ReviewType.get_review_types
    
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
    
    @design_list = [] #list of designs with designer info for view
    
    designs = [] #list of designs with designer info for local use
    board_list.each do |board|
      board.designs.each do |design|
        if !(design.complete? || design.in_phase?(release_rt))
          designer_name = design.designer.name
          designer_id   = design.designer.id
        else 
          final_review = design.design_reviews.detect { |dr| 
                           dr.review_type_id == final_rt.id }
          designer_name = final_review.designer.name
          designer_id   = final_review.designer.id
        end
        designs << { :design => design, 
                          :designer_name => designer_name,
                          :designer_id   => designer_id,
                          :platform_name => board.platform.name,
                          :project_name  => board.project.name }
      end
    end
#logger.debug "--before filter--"
#logger.debug designs
    # If the designer was specified  then filter the list.
    user_id = params[:user][:id].to_i
    if user_id != 0
      designs.delete_if { | design |
         design[:designer_id] != user_id
      }
    end
    # If a phase was specified then filter the list.
    selected_ids = params[:review_types] || []
#logger.debug "--- selected ids ---"
#logger.debug selected_ids
    if selected_ids.include?('Complete')
      @design_list += designs.map { |design| 
        design if design[:design].complete?
      }
    end
    @selected_phases = selected_ids.map { | id |
        if id == "Complete"
          "Complete"
        else
          ReviewType.find(id).name
        end
    }
    @design_list += designs.map { |design| 
      design if selected_ids.include?(design[:design].phase_id.to_s)
    }
    @design_list.delete_if { |dl| dl == nil }  #map adds nil values
#logger.debug "--after filter--"
#logger.debug @design_list
  end 

  def get_stackup_attachment
    
    pnum = params[:pnum].nil? ? "" : params[:pnum]
    revision = params[:revision].nil? ? "" : params[:revision]

    board = PartNum.find_by_pnum(pnum).design.board
    if ( pnum =~ /[0-9]{3}-[0-9]{3}-[0-9]{2}/) 
      board = PartNum.find_by_pnum_and_revision(pnum, revision).design.board
    end

    dr_documents = board.design_review_documents

    doc_type_stackup = DocumentType.get_stackup_document_type
    docs = dr_documents.collect { |d| d if d.document_type_id == doc_type_stackup.id }.compact
    
    dr_stackup_doc = nil
    if docs.size > 0
      dr_stackup_doc = docs.sort_by { |d| d.document.created_on }.pop
    else
      nil
    end

    @document = Document.find(dr_stackup_doc.document_id)
    if @document.unpacked == 1
      send_data(@document.data.lines.to_a.pack("H*"),
        :filename    => @document.name,
        :type        => @document.content_type,
        :disposition => "inline")
    else
      send_data(@document.data,
        :filename    => @document.name,
        :type        => @document.content_type,
        :disposition => "inline")
    end



  end  
   
end
