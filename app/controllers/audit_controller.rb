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
          :design_check_id => design_check_update[:design_check_id]).save
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
      else
        condition = ' and full_review=1'
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
    if @audit.is_self_audit?
      @audit.trim_checklist_for_self_audit
    else
      @audit.trim_checklist_for_peer_audit
    end
    @audit.get_design_checks
        
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

    @audit = Audit.find(params[:id])
    @audit.trim_checklist_for_design_type
    @audit.get_design_checks
    
    @checklist = @audit.checklist
    
  end


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
    @audit.trim_checklist_for_design_type
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
