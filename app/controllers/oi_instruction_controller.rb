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
    @oi_category_list = OiCategory.find_all.sort_by { |c| c.id }

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
      @sections = @category.oi_category_sections.sort_by { |s| s.id }
      @section_selection = flash[:section]
    else
      flash[:section] = { '32' => '1' }

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
  # id        - the id oi_category
  # design_id - the id of the design.
  # 
  # Information flash (for returns from process_assignments)
  # section - the selected section
  # user    - the record for the user
  #
  ######################################################################
  #
  def process_assignments

    flash[:section]   = params[:section] ? params[:section] : flash[:section]
    @instructions          = flash[:step_instructions]
    @selected_team_members = flash[:team_members]
    sections = flash[:section]

    # Make sure the user entered all of the information.  If not, return to the 
    # previous screen.  Verify that at least one section has been selected 
    # before proceeding.
    if !sections.detect { |k,v| v == '1'}   

      flash['notice'] = 'Please select the step(s)'

      redirect_to(:action    => 'section_selection',
                  :id        => params[:category][:id],
                  :design_id => params[:design][:id])
      return
      
    end
    
    # If processing makes it this far then there are no errors.
    design_id   = params[:design]   ? params[:design][:id]   : params[:design_id]
    category_id = params[:category] ? params[:category][:id] : params[:category_id]
    @design      = Design.find(design_id)
    @category    = OiCategory.find(category_id)

    team_members  = Role.find_by_name('Designer').users.delete_if { |u| u.employee? }
    @team_members = team_members.sort_by { |u| u.last_name }

    sections.each do |id, flag|
      @selected_steps = @category.oi_category_sections.delete_if do |section| 
        section.id.to_s == id && flag == "0"
      end
    end

    @common_fields = {
      :allegro_board_symbol_name => false,
      :outline_drawing_link      => false
    }

    @step_instructions = []
    @selected_steps.each do |step|
      step[:instruction] = OiInstruction.new(:oi_category_section_id => step.id,
                                             :design_id              => @design.id)
      if !flash[:step_instructions]
        step[:instruction].details = ""
      else
        step[:instruction].details = flash[:step_instructions][step.id]
      end
      
      @step_instructions[step.id] = step[:instruction]

      @common_fields[:allegro_board_symbol_name] |= step.allegro_board_symbol?
      @common_fields[:outline_drawing_link]      |= step.outline_drawing_link?
    end
    
    @common_field = @common_fields.detect { |k,v| v }

    if @common_fields[:outline_drawing_link]
      outline_drawing_document_type = DocumentType.find_by_name("Outline Drawing")
      @outline_drawing = DesignReviewDocument.find_by_design_id_and_document_type_id(
                           @design.id,
                           outline_drawing_document_type.id)
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

    # Preserve the step instructions for the redirect.
    step_instructions = []
    params.each do |key, value|
      next if !(key =~ /\Astep_instruction/)
      step_instructions[key.split('_')[2].to_i] = value
    end
    
    missing_allegro_board_symbol = false
    if params[:allegro_board_symbol]
      if params[:allegro_board_symbol][:name] == ''
        flash['notice'] = 'Please identify the Allegro Board Symbol'
        missing_allegro_board_symbol = true
      else
        flash[:allegro_board_symbol] = params[:allegro_board_symbol][:name]      
      end
    end
    
    team_members = {}
    params.each do |key, value|

      next if !(key =~ /\Ateam_member/)

      a, b, user_id, section_id = key.split('_')
      team_members[section_id] = []       if !team_members[section_id]
      team_members[section_id] << user_id if value[:selected] == '1'
    end
    
    all_team_members_selected = true
    team_members.each do |key, team_member_list|
      all_team_members_selected = team_member_list.size > 0
      if !all_team_members_selected
        if flash['notice']
          flash['notice'] += '<br />Please select team member(s) for each step'
        else
          flash['notice'] = 'Please select team member(s) for each step'
        end
        break
      end
    end
    

    if missing_allegro_board_symbol || !all_team_members_selected

      flash[:section]              = flash[:section]
      flash[:user]                 = flash[:user]
      flash[:allegro_board_symbol] = flash[:allegro_board_symbol]
      flash[:team_members]         = team_members
      flash[:step_instructions]    = step_instructions

      redirect_to(:action      => 'process_assignments',
                  :category_id => params[:category][:id],
                  :design_id   => params[:design][:id])
        
    else # Process the information that the user passed in.

      instructions         = {}
      design_id            = ''
      oi_category_id       = ''
      allegro_board_symbol = ''
      params.each do |key, value|
      
        next if (key == "action" || key== "controller")
        
        team_member      = key.split('team_member_')
        step_instruction = key.split('step_instructions_')
        if value[:selected] == '1' && team_member.size > 1
          user_id, section_id = team_member[1].split('_')
          instructions[section_id] = {} if !instructions[section_id]
          instructions[section_id][:member_list] = [] if !instructions[section_id][:member_list]
          instructions[section_id][:member_list] << user_id
        elsif step_instruction.size > 1
          instructions[step_instruction[1]] = {} if !instructions[step_instruction[1]]
          instructions[step_instruction[1]][:comment] = value
        elsif key == 'design'
          design_id = value['id']
        elsif key == 'category'
          oi_category_id = value[:id]
          @category = OiCategory.find(value[:id])
        elsif key == 'allegro_board_symbol'
          allegro_board_symbol = value[:name]
        end
      
      end
      
      instructions.each do |section_id, value|
      
        # Check to make sure the instruction does not already exist.
        existing_instruction = 
          OiInstruction.find_by_design_id_and_oi_category_section_id_and_user_id(
            design_id, section_id, session[:user].id)

        if !existing_instruction || @category.name == 'Other'
      
          oi_instruction = OiInstruction.new(:design_id              => design_id,
                                             :oi_category_section_id => section_id,
                                             :user_id                => session[:user].id)
          oi_instruction.allegro_board_symbol = allegro_board_symbol if allegro_board_symbol.size > 0
        
          oi_instruction.save
        
          # Add the comments and team members and send the assignment notification.
          if oi_instruction.errors.empty?
                
            value[:member_list].each do |member_id|
              assignment = OiAssignment.new(:oi_instruction_id => oi_instruction.id,
                                            :user_id           => member_id)
              assignment.save
            
              if value[:comment] != ''
                OiAssignmentComment.new(:oi_assignment_id => assignment.id,
                                        :user_id          => session[:user].id,
                                        :comment          => value[:comment]).save
              end
            end

            flash['notice'] = "The work assignments have been recorded - mail was sent"
            TrackerMailer::deliver_oi_assignment_notification(oi_instruction)
          
          end  #  If no errors storing the oi_instruction
        end  # not existing instruction
      end  # Each instruction
   
      redirect_to(:action    => 'oi_category_selection', 
                  :design_id => params[:design][:id])
    end
  
  end
  
  
  ######################################################################
  #
  # category_details
  #
  # Description:
  # This method retrieves the data needed for an category details view.
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
    @comments   = @assignment.oi_assignment_comments.sort_by { |c| c.created_on }.reverse
  
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
    
    post_comment = ''
    if params[:post_comment][:comment].size > 0 || completed || reset
      case
        when completed
          post_comment = "-- TASK COMPLETE --\n"
        when reset
          post_comment = "-- TASK REOPENED --\n"
      end
      post_comment += params[:post_comment][:comment]
       
      OiAssignmentComment.new(:comment          => post_comment,
                              :user_id          => session[:user].id,
                              :oi_assignment_id => assignment.id).save
    end
    

    if (completed || reset || post_comment != '')
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
    @report        = OiAssignmentReport.new
    @comments      = @assignment.oi_assignment_comments.sort_by { |c| c.created_on }.reverse
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
    
    if @report.score > 0
      @report.save
      flash['notice'] = "Your feedback has been recorded"
    
      redirect_to(:action    => 'oi_category_selection',
                  :design_id => @assignment.oi_instruction.design.id)
    else
      flash['notice'] = "Please select the grade - the report card was not created"
      @comments      = @assignment.oi_assignment_comments.sort_by { |c| c.created_on }.reverse
      @scoring_table = OiAssignmentReport.report_card_scoring
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
    @assignment = OiAssignment.find(params[:id])
    @comments      = @assignment.oi_assignment_comments.sort_by { |c| c.created_on }.reverse
    @scoring_table = OiAssignmentReport.report_card_scoring
    @current_score = @scoring_table.detect { |entry| entry[0] == @assignment.oi_assignment_report.score }[1]
    
    @assignment.oi_assignment_report.score
  end
  
  
  def static_view 
  
    @assignment = OiAssignment.find(params[:id])
    @section    = @assignment.oi_instruction.oi_category_section
    @design     = @assignment.oi_instruction.design
    @comments   = @assignment.oi_assignment_comments.sort_by { |c| c.created_on }.reverse
    
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
    
    score_update   = update.score != assignment.oi_assignment_report.score
    comment_update = update.comment.size > 0
  
    flash['notice'] = ''
    
    if score_update
      assignment.oi_assignment_report.score = update.score
      flash['notice'] = 'Score modified'
    end
    
    if comment_update
      assignment.oi_assignment_report.comment += "<br />" + update.comment
      flash['notice'] += ', ' if score_update
      flash['notice'] += 'Comment updated '
    end
    
    if score_update || comment_update
      assignment.oi_assignment_report.update
      flash['notice'] += " - Report update recorded"
    else
      flash['notice'] = "No Updates were recorded"
    end
  
    redirect_to(:action    => 'oi_category_selection',
                :design_id => assignment.oi_instruction.design.id)

  end
  
  
end
