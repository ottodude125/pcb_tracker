########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: audit_controller.rb
#
# This contains the logic to create, modify, and delete audits.
#
# $Id$
#
########################################################################

class AuditController < ApplicationController

  before_filter(:verify_logged_in, :except => :print)


  ######################################################################
  #
  # update_design_checks
  #
  # Description:
  # This method takes in a list of design checks and processes each one
  # to determine if the check was updated and if it was then the database
  # is updated.
  #
  # Parameters:
  # [check_xxx] - where xxx identifies the check id of the design check
  #               being passed in.
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def update_design_checks

    audit = Audit.find(params[:audit][:id])

    # Go through the paramater list and pull out the checks.
    params.keys.grep(/^check_/).each { |params_key|

      design_check_update = params[params_key]
      design_check = DesignCheck.find(design_check_update[:design_check_id])

      if audit.self_update?(session[:user])
        result        = design_check.designer_result
        result_update = design_check_update[:designer_result]
      elsif audit.peer_update?(session[:user])
        result        = design_check.auditor_result
        result_update = design_check_update[:auditor_result]
      end

      if result_update && result_update != result

        # Make sure that the required comment has been added.
        if design_check_update[:comment].strip.size == 0 &&
           design_check.comment_required?(design_check_update[:designer_result], 
                                          design_check_update[:auditor_result])
         
          if audit.self_update?(session[:user])
            flash[design_check.id] = "A comment is required for a " +
              "#{design_check_update[:designer_result]} response."
          elsif audit.peer_update?(session[:user])
            flash[design_check.id] = "A comment is required for a " +
              "#{design_check_update[:auditor_result]} response."
          end
          flash['notice'] = 'Not all checks were updated - please review the form for errors.'
          next
        end

        check_count = audit.check_count
        if !audit.designer_complete? && audit.self_update?(session[:user])

          audit.process_self_audit_update(result_update, design_check, session[:user])
                     
        elsif !audit.auditor_complete? && audit.peer_update?(session[:user])

          audit.process_peer_audit_update(result_update, 
                                          design_check_update[:comment], 
                                          design_check, 
                                          session[:user])

        end

      end

      # If the user entered a comment, update the database.
      if design_check_update[:comment].strip.size > 0
        AuditComment.new(
          :comment         => design_check_update[:comment],
          :user_id         => session[:user].id,
          :design_check_id => design_check_update[:design_check_id]).create
      end
    }

    redirect_to(:action        => 'perform_checks',
                :audit_id      => params[:audit][:id],
                :subsection_id => params[:subsection][:id])
    
  end


  ######################################################################
  #
  # perform_checks
  #
  # Description:
  # Given a subsection id, gather the section and subscection names
  # along with all of the checks for display.
  #
  # Parameters:
  # [:id]            - identifies the audit
  # [:subsection_id] - subsection
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def perform_checks

    @audit        = Audit.find(params[:audit_id])
    @subsection   = Subsection.find(params[:subsection_id])
    @total_checks = @audit.check_count

    @arrows         = {}
    current_section = @subsection.section
    checklist       = @subsection.checklist
    
    # Build the navigation information.
    @audit.filtered_checklist(session[:user])
    nav_sections  = @audit.checklist.sections
    nav_section_i = nav_sections.index(current_section)

    if nav_section_i

      nav_subsection_i = nav_sections[nav_section_i].subsections.index(@subsection)
  
      if nav_subsection_i > 0
        @arrows[:previous] = nav_sections[nav_section_i].subsections[nav_subsection_i-1]
      elsif nav_section_i > 0
        @arrows[:previous] = nav_sections[nav_section_i-1].subsections.pop
      end
    
      if nav_subsection_i < (nav_sections[nav_section_i].subsections.size-1)
        @arrows[:next] = nav_sections[nav_section_i].subsections[nav_subsection_i+1]
      elsif nav_section_i < (nav_sections.size-1)
        @arrows[:next] = nav_sections[nav_section_i+1].subsections.shift
      end

      @completed_self_checks = @audit.completed_self_audit_check_count(@subsection)
      @completed_peer_checks = @audit.completed_peer_audit_check_count(@subsection)

      @able_to_check = @audit.section_auditor?(@subsection.section, session[:user])

      condition = ''
      if @audit.design.date_code?
        condition = ' and date_code_check=1'
      elsif @audit.design.dot_rev?
        condition = ' and dot_rev_check=1'
      end
    
      if @audit.is_self_audit? || @audit.design.designer_id == session[:user].id
        @checks = Check.find(:all,
                             :conditions => "subsection_id=#{@subsection.id}#{condition}",
                             :order      => 'position')
      else
        @checks = Check.find(:all,
                             :conditions => "subsection_id=#{@subsection.id} and " +
                                            "check_type='designer_auditor'"        +
                                            condition,
                             :order      => 'position')
      end

      # Add the design checks and comments for each of the checks.
      # The audit comments are included in the design check.
      @checks.each do |check|
        check[:design_check] = DesignCheck.find_by_check_id_and_audit_id(check.id, 
                                                                         @audit.id)
      end
    else
      redirect_to(:action => 'show_sections', :id => @audit.id)
    end
    
  end 

  ######################################################################
  #
  # show_sections
  #
  # Description:
  # Given an audit to identify the checklist, this method 
  # gathers the information to display the list from the
  # section level.
  #
  # Parameters:
  # [:id] - identifies the audit
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def show_sections

    @audit      = Audit.find(params[:id])
    @board_name = @audit.design.part_number.pcb_display_name
    
    @lead = @audit.designer_complete? ? @audit.design.peer : @audit.design.designer
    
    self_flag = !@audit.is_self_audit?
    @audit_team = @audit.audit_teammates.delete_if { |at| at.self? == self_flag }

    design_check_list = {}
    @audit.design_checks.each { |dc| design_check_list[dc.check_id] = dc }

    @checklist_index = []
    @audit.checklist.sections.each do |section|

      next if !@audit.design.belongs_to(section)
      
      section_index = { :section => section }
      
      subsects = []
      section.subsections.each do |subsection|

        next if !@audit.design.belongs_to(subsection)
                 
        subsect = { 'name'             => subsection.name,
                    'note'             => subsection.note,
                    'url'              => subsection.url,
                    'id'               => subsection.id,
                    'percent_complete' => 0.0 }

        condition = ''
        if @audit.design.date_code?
          condition = ' and date_code_check=1'
        elsif @audit.design.dot_rev?
          condition = ' and dot_rev_check=1'
        end
        
        if @audit.is_self_audit? || @audit.design.designer_id == session[:user].id
          subsection_checks = Check.find(:all,
                                         :conditions => "subsection_id=#{subsection.id}" +
                                                        condition)
        else
          subsection_checks = Check.find(:all,
                                         :conditions => "subsection_id=#{subsection.id} and " +
                                                        "check_type='designer_auditor'" +
                                                        condition)
        end
        subsect['checks'] = subsection_checks.size
        
        checks_completed = 0
        questions        = 0
        if @audit.is_self_audit? || @audit.design.designer_id == session[:user].id
          subsection_checks.each do |check|
            if design_check_list[check.id]
              checks_completed += 1 if design_check_list[check.id].designer_result != 'None'
              questions += 1 if design_check_list[check.id].auditor_result == 'Comment'
            end
          end
        else
          subsection_checks.each do |check|
            if design_check_list[check.id]
              checks_completed += 1 if design_check_list[check.id].auditor_result != 'None' and design_check_list[check.id].auditor_result != 'Comment'
              questions += 1 if design_check_list[check.id].auditor_result == 'Comment'
            end
          end
        end
        
        subsect['questions'] = questions
        if subsect['checks'] > 0
          subsect['percent_complete'] = checks_completed * 100.0 / subsect['checks']
        else
          subsect['percent_complete'] = 0.0
        end
        
        subsects.push(subsect)
      end
      section_index['subsections'] = subsects
      @checklist_index.push(section_index)
    end
    
  end # show_sections method


  ######################################################################
  #
  # print
  #
  # Description:
  # This method retrieves the check from the database for display.
  #
  # Parameters:
  # params['id'] - The ID of the check used to identify the check to bo
  #                be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  # Validates the user is an Admin before proceeding.
  #
  ######################################################################
  #
  def print

    @audit    = Audit.find(params[:id])
    @user_list = []
    
    design_check_list = DesignCheck.find(:all, 
                                         :conditions => "audit_id=#{@audit.id}",
                                         :include    => :audit_comments)

    @checklist = @audit.checklist
    
    # Remove the sections that are not used.
    case @audit.design.design_type
    when 'New'
      @audit.checklist.sections.delete_if { |section| !section.full_review? }
    when 'Dot Rev'
      @audit.checklist.sections.delete_if { |section| !section.dot_rev_check? }
    when 'Date Code'
      @audit.checklist.sections.delete_if { |section| !section.date_code_check? }
    end
    
    @audit.checklist.sections.each do |section|

      next if !@audit.design.belongs_to(section)
      
      # Remove the subsections that are not used.
      case @audit.design.design_type
      when 'New'
        section.subsections.delete_if { |subsection| !subsection.full_review? }
      when 'Dot Rev'
        section.subsections.delete_if { |subsection| !subsection.dot_rev_check? }
      when 'Date Code'
        section.subsections.delete_if { |subsection| !subsection.date_code_check? }
      end

      section.subsections.each do |subsection|

        next if !@audit.design.belongs_to(subsection)

        # Remove the checks that are not used.
        case @audit.design.design_type
        when 'New'
          subsection.checks.delete_if { |check| !check.full_review? }
        when 'Dot Rev'
          subsection.checks.delete_if { |check| !check.dot_rev_check? }
        when @audit.design.design_type == 'Date Code'
          subsection.checks.delete_if { |check| !check.date_code_check? }
        end

        subsection.checks.each do |check|

          next if !@audit.design.belongs_to(check)

          check[:design_check] = design_check_list.detect { |dc| dc.check_id == check.id }
          next if !check[:design_check]
    
          designer = @user_list.detect { |u| u.id == check[:design_check].designer_id }
          if !designer && check[:design_check].designer_id != 0
            designer = User.find(check[:design_check].designer_id) if check[:design_check].designer_id > 0
            @user_list << designer
          end
          check[:designer] = designer.name if designer

          if check[:design_check].auditor_id > 0
            auditor = @user_list.detect { |u| u.id == check[:design_check].auditor_id }
            if !auditor && check[:design_check].auditor_id != 0
              auditor = User.find(check[:design_check].auditor_id) if check[:design_check].auditor_id > 0
              @user_list << auditor
            end
            check[:auditor] = auditor.name if auditor
          end
        end
      end
    end
  end # print method


  ######################################################################
  #
  # auditor_list
  #
  # Description:
  # This method retrieves information needed to display the designers
  # assigned to the sections of the checklist.  This is for the 
  # self and peer audit. 
  #
  # Parameters:
  # params['id'] - The ID of the audit.
  #
  ######################################################################
  #
  def auditor_list
    
    @audit = Audit.find(params[:id])
    
    self_list = Role.active_designers
    peer_list = self_list.dup
    peer_list.delete_if { |u| u.id == @audit.design.designer_id }
    
    sections = []
    @audit.checklist.sections.each do |section|
   
      next if ((@audit.design.date_code? && !section.date_code_check?) ||
               (@audit.design.dot_rev?   && !section.dot_rev_check?))
               
      sect = { :section      => section,
               :self_auditor => @audit.design.designer,
               :peer_auditor => @audit.design.peer }
    
      self_auditor =
         @audit.audit_teammates.detect { |mate| mate.section_id == section.id && mate.self? }
      sect[:self_auditor] = self_auditor.user if self_auditor
      
      peer_auditor = 
        @audit.audit_teammates.detect { |mate| mate.section_id == section.id && !mate.self? }
      sect[:peer_auditor] = peer_auditor.user if peer_auditor
      
      sections << sect
      
    end
    
    @auditor_list = { :lead_designer => @audit.design.designer,
                      :self_list     => self_list,
                      :lead_peer     => @audit.design.peer,
                      :peer_list     => peer_list,
                      :sections      => sections }
  end
  
  
  ######################################################################
  #
  # update_auditor_list
  #
  # Description:
  # This method uses the information passed in from the user
  # to make updates to the audit teammate list.
  #
  # Parameters:
  # params[:audit][:id]   - The ID of the audit.
  # params[:self_auditor] - A list that contains pairs of section IDs
  #                         and user IDs used for assignment.
  # params[:peer_autitor] - A list that contains pairs of section IDs
  #                         and user IDs used for assignment.
  #
  ######################################################################
  #
  def update_auditor_list
  
    audit = Audit.find(params[:audit][:id])
    
    self_auditor_list = {}
    params[:self_auditor].each do |section_id_string, self_auditor|
      section_id                    = section_id_string.split('_')[2].to_i
      self_auditor_list[section_id] = self_auditor
    end
    
    peer_auditor_list = {}
    params[:peer_auditor].each do |section_id_string, peer_auditor|
      section_id                    = section_id_string.split('_')[2].to_i
      peer_auditor_list[section_id] = peer_auditor
    end
    
    audit.manage_auditor_list(self_auditor_list, peer_auditor_list, session[:user])
    flash['notice'] = audit.message if audit.message?

    redirect_to(:action => 'auditor_list', :id => audit.id)
  
  end


end # class AuditController
