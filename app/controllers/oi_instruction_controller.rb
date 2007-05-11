########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: oi_instruction_controller.rb
#
# This contains the logic to create and modify oi_instruction 
# information.
#
# $Id$
#
########################################################################


class OiInstructionController < ApplicationController

  before_filter(:verify_pcb_group)


  ######################################################################
  #
  # oi_category_selection
  #
  # Description:
  # This method retrieves the design and the oi categories for display.
  #
  # Parameters from params
  # design_id - the id of the design.
  #
  ######################################################################
  #
  def oi_category_selection

    @design           = Design.find(params[:design_id])
    @oi_category_list = OiCategory.list

  end
  
  
  ######################################################################
  #
  # section_selection
  #
  # Description:
  # This method collects the data for display in the section_selection
  # view.
  #
  # Parameters from params
  # id        - the id oi_category
  # design_id - the id of the design.
  # 
  # Information flash (for returns from process_assignments)
  # section - the selected section
  # user    - the record for the user
  #
  ######################################################################
  #
  def section_selection

    @category = OiCategory.find(params[:id])
    @design   = Design.find(params[:design_id])

    if @category.name != "Other"
      @sections   = @category.oi_category_sections
      @section_id = flash[:assignment] ? flash[:assignment][:selected_step].id : 0
    else
      flash[:section] = { OiCategory.other_category_section_id.to_s => '1' }

      redirect_to(:action      => :process_assignments,
                  :category_id => @category.id,
                  :design_id   => @design.id)
    end

  end
  
  
  ######################################################################
  #
  # process_assignments
  #
  # Description:
  # This method first validates that the user entered the correct
  # information.  If not the the previous view, section_selection, is
  # displayed.  If the required information was provided then the data
  # for the process_assignments view is gathered.
  #
  # Parameters from params
  # id         - the id oi_category
  # design_id  - the id of the design
  # section_id - the outsource instruction category section identifier
  # 
  # Information flash (for returns from process_assignments)
  # section - the selected section
  # user    - the record for the user
  #
  ######################################################################
  #
  def process_assignments

    # Verify that a section was selected before proceeding.
    if !(params[:section_id] || flash[:assignment])
    
      flash['notice'] = 'Please select the step'

      redirect_to(:action    => 'section_selection',
                  :id        => params[:category][:id],
                  :design_id => params[:design][:id])
                  
      flash[:assignment] = flash[:assignment]
      
      return
      
    end

    # If processing makes it this far then there are no errors.
    if !flash[:assignment]
    
      assignment = {}
      @design       = Design.find(params[:design]       ? params[:design][:id]   : params[:design_id])
      @category     = OiCategory.find(params[:category] ? params[:category][:id] : params[:category_id])
      @team_members = Role.lcr_designers
      @selected_step = @category.oi_category_sections.detect { |s| s.id == params[:section_id].to_i }
      @instruction   = OiInstruction.new(:oi_category_section_id => @selected_step.id,
                                         :design_id              => @design.id)
      @assignment    = OiAssignment.new(:due_date      => Time.now+1.day,
                                        :complexity_id => OiAssignment.complexity_id("Low"))
      @comment       = OiAssignmentComment.new
      
      assignment[:design]        = @design
      assignment[:category]      = @category
      assignment[:team_members]  = @team_members
      assignment[:selected_step] = @selected_step
      assignment[:instruction]   = @instruction
      assignment[:assignment]    = @assignment
      assignment[:comment]       = @comment

      if @selected_step.outline_drawing_link?
        outline_drawing_document_type = DocumentType.find_by_name("Outline Drawing")
        @outline_drawing = DesignReviewDocument.find(
                             :first,
                             :conditions => "design_id=#{@design.id} AND " +
                                            "document_type_id=#{outline_drawing_document_type.id}",
                             :order      => "id DESC")
        assignment[:outline_drawing] = @outline_drawing
      end
      
      flash[:assignment] = assignment
    else
      @design          = flash[:assignment][:design]
      @category        = flash[:assignment][:category]
      @team_members    = flash[:assignment][:team_members]
      @selected_step   = flash[:assignment][:selected_step]
      @instruction     = flash[:assignment][:instruction]
      @assignment      = flash[:assignment][:assignment]
      @comment         = flash[:assignment][:comment]
      @outline_drawing = flash[:assignment][:outline_drawing]

      flash[:assignment] = flash[:assignment]
    end


  end
  
  
  ######################################################################
  #
  # process_assignment_details
  #
  # Description:
  # This method first validates that the user entered the correct
  # information.  If not the the previous view, process_assignments, is
  # displayed.  If the required information was provided then the data
  # for the process_assignments view is processed.
  #
  # Parameters from params
  # id        - the id oi_category
  # design_id - the id of the design.
  # 
  # Information flash (for returns from process_assignments)
  # section - the selected section
  # user    - the record for the user
  #
  ######################################################################
  #
  def process_assignment_details

    oi_assignments = {}

    instruction     = OiInstruction.new(params[:instruction])
   
    missing_allegro_board_symbol = false
    category_section = OiCategorySection.find(instruction.oi_category_section_id)
    if (category_section.allegro_board_symbol? &&
        instruction.allegro_board_symbol == '')
      flash['notice'] = 'Please identify the Allegro Board Symbol'
      missing_allegro_board_symbol = true
    end
    
    team_members = []
    params[:team_member].each do |user_id, value|
      team_members << user_id.to_s if value == '1'
    end

    team_members_selected = team_members.size > 0
    if !team_members_selected
      member_message = 'Please select a team member or members'
      if flash['notice']
        flash['notice'] += '<br />' + member_message
      else
        flash['notice'] = member_message
      end
    end
    
    if missing_allegro_board_symbol || !team_members_selected
    
      flash[:assignment] = flash[:assignment]

      flash[:assignment][:instruction]       = instruction
      flash[:assignment][:member_selections] = params[:team_member]
      flash[:assignment][:comment]           = OiAssignmentComment.new(params[:comment])
      flash[:assignment][:assignment]        = OiAssignment.new(params[:assignment])

      redirect_to(:action      => 'process_assignments',
                  :category_id => params[:category][:id],
                  :design_id   => params[:design][:id])
        
    else # Process the information that the user passed in.

      # Fill out the Outsource Instruction record and save it.
      instruction.design_id = params[:design][:id]
      instruction.user_id   = session[:user].id
      instruction.save
      
      # Create an assignment record and optional assignment comment for each of the 
      # selected team members.
      if instruction.errors.empty?
      
        
        oi_assignments = {}
        team_members.each do |user_id|
        
          assignment                   = OiAssignment.new(params[:assignment])
          assignment.oi_instruction_id = instruction.id
          assignment.user_id           = user_id
          assignment.save
          
          if assignment.errors.empty?
          
            oi_assignments[user_id] = [] if !oi_assignments[user_id]
            oi_assignments[user_id].push(assignment)
            
            comment = OiAssignmentComment.new(params[:comment])
            if comment.comment.lstrip != ''
              comment.user_id          = session[:user].id
              comment.oi_assignment_id = assignment.id
              comment.save
            end

            flash['notice'] = "The work assignments have been recorded - mail was sent"
            
          end
        
        end # each team_member
      
      end
      
      # Send notification email for each of the assignments.
      oi_assignments.each do |member_id, oi_assignment_list|
        TrackerMailer::deliver_oi_assignment_notification(oi_assignment_list)
      end

      redirect_to(:action    => 'oi_category_selection', 
                  :design_id => params[:design][:id])
    end
  
  end
  
  
  ######################################################################
  #
  # category_details
  #
  # Description:
  # This method retrieves the data needed for the category details view.
  #
  # Parameters from params
  #  id        - the id of the design record
  # 
  ######################################################################
  #
  def category_details

    @design = Design.find(params[:id])
    my_assignments = @design.my_assignments(session[:user].id).sort_by do |i|
                       i.oi_instruction.oi_category_section.oi_category.id
    end
                      
    @category_list = {}
    my_assignments.each do |a|
      category = a.oi_instruction.oi_category_section.oi_category
      @category_list[category] = [] if !@category_list[category]
      @category_list[category] << a
    end
  
  end
  
  
  ######################################################################
  #
  # assignment_details
  #
  # Description:
  # This method retrieves the data needed for an assignment details view.
  #
  # Parameters from params
  #  id        - the id of the category record
  #  design_id - the id of the associated design
  # 
  ######################################################################
  #
  def assignment_details

    @category = OiCategory.find(params[:id])
    @design   = Design.find(params[:design_id])
    
    my_assignments = @design.my_assignments(session[:user].id).delete_if do |a| 
      a.oi_instruction.oi_category_section.oi_category_id != @category.id
    end
    
    @section_list = { :category => nil, :assignment_list => [] }
    my_assignments.each do |a|
      category = a.oi_instruction.oi_category_section.oi_category
      if !@section_list[:category]
        @section_list[:category] = category
      elsif @section_list[:category] != category
        raise(RuntimeError, 'Multiple categories when a single category was expected')
      end
      @section_list[:assignment_list] << a
    end
    
  end
  
  
  ######################################################################
  #
  # assignment_view
  #
  # Description:
  # This method retrieves the data needed for an assignment view.
  #
  # Parameters from params
  #  id - the id of the assignment
  # 
  ######################################################################
  #
  def assignment_view

    @assignment = OiAssignment.find(params[:id])
    @design     = @assignment.oi_instruction.design
    @category   = @assignment.oi_instruction.oi_category_section.oi_category
    @comments   = @assignment.oi_assignment_comments
  
    @post_comment = OiAssignmentComment.new
  
  end
  
  
  ######################################################################
  #
  # assignment_update
  #
  # Description:
  # This method records the user inputs for the assignment.
  #
  # Parameters from params
  # [assignment][id]        - the id of the assignment
  # [assignment][complete]  - the value of the complete check box.
  # [post_comment][comment] - the comment entered by the user
  # 
  ######################################################################
  #
  def assignment_update

    assignment = OiAssignment.find(params[:assignment][:id])
    completed  = !assignment.complete? && params[:assignment][:complete] == '1'
    reset      = assignment.complete?  && params[:assignment][:complete] == '0'

    if completed || reset
      assignment.complete     = completed ? 1 : 0
      assignment.completed_on = Time.now if completed
      assignment.update
    end
    
    post_comment = ""
    post_comment = "-- TASK COMPLETE --\n" if completed
    post_comment = "-- TASK REOPENED --\n" if reset
    post_comment += params[:post_comment][:comment]
    
    if post_comment.size > 0
    
      OiAssignmentComment.new(:comment          => post_comment,
                              :user_id          => session[:user].id,
                              :oi_assignment_id => assignment.id).save

      flash['notice'] = 'The work assignment has been updated - mail sent'
      TrackerMailer.deliver_oi_task_update(assignment, 
                                           session[:user],
                                           completed,
                                           reset)
    else
      flash['notice'] = 'No updates included with post - the work assignment has not been updated'
    end
    
    redirect_to(:action => 'assignment_view', :id => assignment.id)
  
  end
  
  
  ######################################################################
  #
  # view_assignments
  #
  # Description:
  # This method retrievs the data for the view assigments view
  #
  # Parameters from params
  #  id        - the id of the category record
  #  design_id - the id of the associated design
  # 
  ######################################################################
  #
  def view_assignments

    category  = OiCategory.find(params[:id])
    @design   = Design.find(params[:design_id])
    
    assignment_list = {}
    @design.all_assignments(category.id).each do |a|
      section = a.oi_instruction.oi_category_section
      assignment_list[section] = [] if !assignment_list[section]
      assignment_list[section] << a
    end
    
    @assignment_list = assignment_list.sort_by { |category, list| category.id }
    
    @assignment_list.each do |section|
      section[1] = section[1].sort_by { |a| a.user.last_name }
    end
    
  end
  
  
  ######################################################################
  #
  # report_card_list
  #
  # Description:
  # This method retrievs the data for the view assigments view
  #
  # Parameters from params
  #  id        - the id of the category record
  #  design_id - the id of the associated design
  # 
  ######################################################################
  #
  def report_card_list

    @category = OiCategory.find(params[:id])
    @design   = Design.find(params[:design_id])

    assignment_list = {}
    @design.all_assignments(@category.id).each do |a|
      section = a.oi_instruction.oi_category_section
      assignment_list[section] = [] if !assignment_list[section]
      assignment_list[section] << a if a.complete?
    end
    
    @assignment_list = assignment_list.sort_by { |category, list| category.id }
    
    @assignment_list.each do |section|
      section[1] = section[1].sort_by { |a| a.user.last_name }
    end
      
  end
  

  ######################################################################
  #
  # create_assignment_report
  #
  # Description:
  # This action retrieves the data for the create assignment report 
  # view
  #
  # Parameters from params
  #  id - the oi_assignment record identifier
  # 
  ######################################################################
  #
  def create_assignment_report
  
    @assignment    = OiAssignment.find(params[:id])
    @complexity_id = @assignment.complexity_id
    @report        = OiAssignmentReport.new(:score => OiAssignmentReport::NOT_SCORED)
    @comments      = @assignment.oi_assignment_comments
    @scoring_table = OiAssignmentReport.report_card_scoring
    
  end
  
  
  ######################################################################
  #
  # create_report
  #
  # Description:
  # This action processes the information entered on the create 
  # assignment report view
  #
  # Parameters from params
  #  report          - the oi_assignment record that will be 
  #                    stored in the database
  #  assignment[:id] - the oi_assignment record identifier
  # 
  ######################################################################
  #
  def create_report
  
    @report     = OiAssignmentReport.new(params[:report])
    @assignment = OiAssignment.find(params[:assignment][:id])
    
    @report.user_id          = session[:user].id
    @report.oi_assignment_id = @assignment.id
    
    if @report.score != OiAssignmentReport::NOT_SCORED
    
      @report.save
      flash['notice'] = "Your feedback has been recorded"
      
      # If the user updated the complexity of the task then record the update.
      if @assignment.complexity_id != params[:complexity][:id].to_i
        @assignment.update_attribute(:complexity_id, params[:complexity][:id].to_i)
      end
    
      redirect_to(:action    => 'oi_category_selection',
                  :design_id => @assignment.oi_instruction.design.id)
    else
      flash['notice'] = "Please select the grade - the report card was not created"
      @comments      = @assignment.oi_assignment_comments
      @scoring_table = OiAssignmentReport.report_card_scoring
      @complexity_id = params[:complexity][:id].to_i
      render_action('create_assignment_report')
    end
  
  end
  
  
  ######################################################################
  #
  # view_assignment_report
  #
  # Description:
  # This action retrieves the data for the view assignment report 
  # view
  #
  # Parameters from params
  #  id - the oi_assignment record identifier
  # 
  ######################################################################
  #
  def view_assignment_report
  
    @assignment    = OiAssignment.find(params[:id])
    @comments      = @assignment.oi_assignment_comments
    @scoring_table = OiAssignmentReport.report_card_scoring
    @current_score = @assignment.oi_assignment_report.score_value
 
  end
  
  
  ######################################################################
  #
  # static_view
  #
  # Description:
  # This action retrieves the data for the static view
  #
  # Parameters from params
  #  id - the oi_assignment record identifier
  # 
  ######################################################################
  #
  def static_view 
  
    @assignment = OiAssignment.find(params[:id])
    @section    = @assignment.oi_instruction.oi_category_section
    @design     = @assignment.oi_instruction.design
    @comments   = @assignment.oi_assignment_comments
    
    render(:layout => false)
  
  end
  
  
  ######################################################################
  #
  # update_report
  #
  # Description:
  # This action processes the information entered on the view 
  # assignment report view
  #
  # Parameters from params
  #  report          - the oi_assignment record that will be stored
  #                    in the database
  #  assignment[:id] - the oi_assignment record identifier
  # 
  ######################################################################
  #
  def update_report
  
    update     = OiAssignmentReport.new(params[:report])
    assignment = OiAssignment.find(params[:assignment][:id])
    
    score_update      = update.score != assignment.oi_assignment_report.score
    complexity_update = assignment.complexity_id != params[:complexity][:id].to_i
    comment_update    = update.comment.size > 0
  
    flash['notice'] = ''
    
    if score_update
      assignment.oi_assignment_report.score = update.score
      flash['notice'] = 'Score modified'
    end
    
    if comment_update
      assignment.oi_assignment_report.comment += "<br />" + update.comment
      flash['notice'] += ', ' if flash['notice'] != ''
      flash['notice'] += 'Comment updated'
    end
    
    if complexity_update
      assignment.complexity_id = params[:complexity][:id].to_i
      flash['notice'] += ', ' if flash['notice'] != ''
      flash['notice'] += 'Task Complexity updated'
    end
    
    if score_update || comment_update || complexity_update
      assignment.update
      assignment.oi_assignment_report.update
      flash['notice'] += " - Report update recorded"
    else
      flash['notice'] = "No Updates were recorded"
    end
  
    redirect_to(:action    => 'oi_category_selection',
                :design_id => assignment.oi_instruction.design.id)

  end
  
  
end
