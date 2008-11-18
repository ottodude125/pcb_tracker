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

    audit         = Audit.find(params[:audit][:id])
    subsection_id = params[:subsection][:id]
    
    # Keep track of the audit state to determine where to redirect to
    original_state = audit.audit_state
    
    # Process thechecks passed in.
    params.keys.grep(/^check_/).each do |key|

      audit.update_design_check(params[key], @logged_in_user)

      if audit.errors.on(:comment_required)
        flash[params[key][:design_check_id].to_i] = audit.errors.on(:comment_required)
        flash['notice'] = 'Not all checks were updated - please review the form for errors.'
      end
      
    end

    if original_state == audit.audit_state
      flash['notice'] = 'Processed design checks.' if !flash['notice']
      redirect_to(:action        => 'perform_checks',
                  :audit_id      => audit.id,
                  :subsection_id => subsection_id)
    else
      phase = audit.is_complete? ? 'Peer' : 'Self'
      flash['notice'] = "The #{phase} audit is complete"
      redirect_to(:controller => 'tracker', :action => 'index')
    end
    
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
    @total_checks = @audit.check_count

    if @audit.is_self_audit?
      @audit.trim_checklist_for_self_audit
    else
      @audit.trim_checklist_for_peer_audit
    end
    @audit.get_design_checks

    # Locate the subsection in the checklist.
    @audit.checklist.sections.each do |section|
      @subsection = section.subsections.detect { |ss| ss.id == params[:subsection_id].to_i }
      break if @subsection
    end

    @arrows = { :previous => @audit.previous_subsection(@subsection),
                :next => @audit.next_subsection(@subsection) }
    @completed_self_checks = @audit.completed_self_audit_check_count(@subsection)
    @completed_peer_checks = @audit.completed_peer_audit_check_count(@subsection)

    @able_to_check = @audit.section_auditor?(@subsection.section, @logged_in_user)
    
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
    
    if !@audit.is_complete?
      if @audit.is_self_audit?
        @audit.trim_checklist_for_self_audit
      else
        @audit.trim_checklist_for_peer_audit
      end
      @audit.get_design_checks
    else
      redirect_to( :controller => "tracker", :action => 'index' )
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
    
    audit.manage_auditor_list(self_auditor_list, peer_auditor_list, @logged_in_user)
    flash['notice'] = audit.message if audit.message?

    redirect_to(:action => 'auditor_list', :id => audit.id)
  
  end


end # class AuditController
