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

#  before_filter(:verify_admin_role,
#                :except => [:designer_list]}


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

    audit = Audit.find(@params[:audit][:id])

    self_audit_update = (audit.is_self_auditor?(@session[:user]) && 
                         audit.is_self_audit?)
    peer_audit_update = (audit.is_peer_auditor?(@session[:user]) && 
                         audit.is_peer_audit?)

    # Go through the paramater list and pull out the checks.
    @params.keys.grep(/^check_/).each { |params_key|

      design_check_update = @params[params_key]
      design_check = DesignCheck.find(design_check_update[:design_check_id])

      if self_audit_update
        result        = design_check.designer_result
        result_update = design_check_update[:designer_result]
      elsif peer_audit_update
        result        = design_check.auditor_result
        result_update = design_check_update[:auditor_result]
      end

      if result_update && result_update != result

        # Make sure that the required comment has been added.
        if (design_check_update[:comment].strip.size == 0 &&
            ((design_check.check.yes_no? &&
              design_check_update[:designer_result] == 'No') ||
             
             ((design_check.check.designer_only? ||
               design_check.check.designer_auditor?) &&
              (design_check_update[:designer_result] == 'Waived' ||
               design_check_update[:auditor_result] == 'Waived' ||
               design_check_update[:auditor_result] == 'Comment'))))
         
          if self_audit_update
            flash[design_check.id] = "A comment is required for a " +
              "#{design_check_update[:designer_result]} response."
          elsif peer_audit_update
            flash[design_check.id] = "A comment is required for a " +
              "#{design_check_update[:auditor_result]} response."
          end
          flash['notice'] = 'Not all checks were updated - please review the form for errors.'
          next
        end

        check_count = audit.check_count
        if self_audit_update && !audit.designer_complete?

          if result == "None"
            begin
              completed_checks = audit.designer_completed_checks + 1
              total_checks     = check_count[:designer]
              audit.update_attributes(
                :designer_completed_checks => completed_checks,
                :designer_complete         => (completed_checks == total_checks))
            rescue ActiveRecord::StaleObjectError
              audit.reload
              retry
            end

            TrackerMailer.deliver_self_audit_complete(audit) if audit.designer_complete?
          end
          result = design_check.update_attributes(
                     :designer_result     => result_update,
                     :designer_checked_on => Time.now,
                     :designer_id         => @session[:user].id)
                     
        elsif peer_audit_update && !audit.auditor_complete?

          complete   = ['Verified', 'N/A', 'Waived']
          incomplete = ['None', 'Comment']

          if result_update == 'Comment' && complete.include?(result)
            incr = -1
          elsif complete.include?(result_update) && incomplete.include?(result)
            incr = 1
          else
            incr = 0
          end

          if incr != 0
            begin
              completed_checks = audit.auditor_completed_checks + incr
              total_checks     = check_count[:peer]
              audit.update_attributes(
                :auditor_completed_checks => completed_checks,
                :auditor_complete         => (completed_checks == total_checks))
            rescue ActiveRecord::StaleObjectError
              audit.reload
              retry
            end

            if audit.auditor_complete?
              TrackerMailer.deliver_peer_audit_complete(audit)
              AuditTeammate.delete_all(["audit_id = ?", audit.id])
            end
          end

          result = design_check.update_attributes(
                     :auditor_result     => result_update,
                     :auditor_checked_on => Time.now,
                     :auditor_id         => @session[:user].id)
                     
          if result_update == 'Comment'
          
            TrackerMailer::deliver_audit_update(design_check,
                                                design_check_update[:comment],
                                                audit.design.designer,
                                                @session[:user])
          end
          
        end

      end

      # If the user entered a comment, update the database.
      if design_check_update[:comment].strip.size > 0
        audit_comment = AuditComment.new
        audit_comment.comment         = design_check_update[:comment]
        audit_comment.user_id         = @session[:user][:id]
        audit_comment.design_check_id = design_check_update[:design_check_id]
        audit_comment.create
      end
    }

    redirect_to(:action        => 'perform_checks',
                :audit_id      => @params[:audit][:id],
                :subsection_id => @params[:subsection][:id])
    
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

    @audit        = Audit.find(@params[:audit_id])
    @subsection   = Subsection.find(@params[:subsection_id])
    @total_checks = @audit.check_count
    
    @arrows         = {}
    current_section = @subsection.section
    checklist       = @subsection.checklist
    
    # Build the navigation information.
    nav_sections  = checklist.sections.dup
    if @audit.design.date_code?
      nav_sections.delete_if { |sec| !sec.date_code_check? }
      for section in nav_sections
        section.subsections.delete_if { |subsec| !subsec.date_code_check? }
      end
    elsif @audit.design.dot_rev?
      nav_sections.delete_if { |sec| !sec.dot_rev_check? }
      for section in nav_sections
        section.subsections.delete_if { |subsec| !subsec.dot_rev_check? }
      end
    end
    
    if @audit.is_peer_audit? && @audit.is_peer_auditor?(session[:user])
      nav_sections.delete_if { |sec| sec.designer_auditor_checks == 0 }
      for section in nav_sections
        section.subsections.delete_if { |subsec| subsec.designer_auditor_checks == 0 }
      end
    end

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

      design_checks = []
      for check in @subsection.checks
        design_check = DesignCheck.find_by_audit_id_and_check_id(
                         @audit.id, check.id)
        design_checks << design_check if design_check 
      end

      @completed_self_checks = design_checks.find_all { |dc| 
                                 dc.designer_result != 'None' }.size
      @completed_peer_checks = design_checks.find_all { |dc|
                                 dc.auditor_result != 'None' &&
                                 dc.auditor_result != 'Comment' }.size
    

      teammate = AuditTeammate.find_by_audit_id_and_section_id_and_self(
                   @audit.id,
                   @subsection.section.id,
                   @audit.is_self_audit? ? 1 : 0)
      user_id = @session[:user].id

      if @audit.is_self_audit?
        @able_to_check = ((!teammate && user_id == @audit.design.designer_id) ||
                          ( teammate && user_id == teammate.user_id))
      else
        @able_to_check = ((!teammate && user_id == @audit.design.peer_id) ||
                          ( teammate && user_id == teammate.user_id))  &&
                         !@audit.is_complete?
      end

      condition = ''
      if @audit.design.date_code?
        condition = ' and date_code_check=1'
      elsif @audit.design.dot_rev?
        condition = ' and dot_rev_check=1'
      end
    
      if @audit.is_self_audit? || @audit.design.designer_id == @session[:user].id
        @checks = Check.find_all("subsection_id=#{@subsection.id}" +
                                 condition,
                                 'sort_order ASC')
      else
        @checks = Check.find_all("subsection_id=#{@subsection.id} and " +
                                 "check_type='designer_auditor'" +
                                 condition,
                                 'sort_order ASC')
      end

      # Add the design checks and comments for each of the checks.
      # The audit comments are included in the design check.
      for check in @checks
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

    @audit      = Audit.find(@params[:id])
    @board_name = @audit.design.name
    
    @lead = @audit.designer_complete? ? @audit.design.peer : @audit.design.designer
    
    self_flag = !@audit.is_self_audit?
    @audit_team = @audit.audit_teammates.delete_if { |at| at.self? == self_flag }

    design_check_list = Hash.new
    for design_check in @audit.design_checks
      design_check_list[design_check.check_id] = design_check
    end

    @checklist_index = Array.new
    for section in @audit.checklist.sections

      next if !@audit.design.belongs_to(section)
      
      section_index = { :section => section }
      
      subsects = Array.new
      for subsection in section.subsections

        next if !@audit.design.belongs_to(subsection)
                 
        subsect = Hash.new
        subsect['name']             = subsection.name
        subsect['note']             = subsection.note
        subsect['url']              = subsection.url
        subsect['id']               = subsection.id
        subsect['percent_complete'] = 0.0
        
        condition = ''
        if @audit.design.date_code?
          condition = ' and date_code_check=1'
        elsif @audit.design.dot_rev?
          condition = ' and dot_rev_check=1'
        end
        
        if @audit.is_self_audit? || @audit.design.designer_id == @session[:user].id
          subsection_checks = 
            Check.find_all("subsection_id=#{subsection.id}" +
                           condition)
        #elsif @audit.is_peer_audit?
        else
          subsection_checks = 
            Check.find_all("subsection_id=#{subsection.id} and " +
                           "check_type='designer_auditor'" +
                           condition)
        end
        subsect['checks'] = subsection_checks.size
        
        checks_completed = 0
        questions        = 0
        if @audit.is_self_audit? || @audit.design.designer_id == @session[:user].id

          for check in subsection_checks
            if design_check_list[check.id]
              checks_completed += 1 if design_check_list[check.id].designer_result != 'None'
              questions += 1 if design_check_list[check.id].auditor_result == 'Comment'
            end
          end
        else
          for check in subsection_checks
            if design_check_list[check.id]
              checks_completed += 1 if design_check_list[check.id].auditor_result != 'None' and design_check_list[check.id].auditor_result != 'Comment'
              questions += 1 if design_check_list[check.id].auditor_result == 'Comment'
            end
          end
        end
        
        subsect['questions'] = questions
        if subsect['checks']
          subsect['percent_complete'] = 
            checks_completed * 100.0 / subsect['checks']
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
  # @params['id'] - The ID of the check used to identify the check to bo
  #                 be retrieved.
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

    @audit   = Audit.find(@params[:id])
    @summary = Hash.new
    @summary[:board_number]  = @audit.design.name
    @summary[:designer]      = @audit.design.designer.name
    @summary[:auditor]       = @audit.design.peer.name
    @summary[:checklist_rev] =
      @audit.checklist.major_rev_number.to_s +
      '.' +
      @audit.checklist.minor_rev_number.to_s

    @display       = Array.new
    for section in @audit.checklist.sections
      
      next if !@audit.design.belongs_to(section)

      for subsection in section.subsections

        next if !@audit.design.belongs_to(subsection)

        box = Hash.new
        design_checks = Array.new
        for check in subsection.checks

          next if !@audit.design.belongs_to(check)

          check_info = Hash.new
          check_info[:check]        = check

          check_info[:design_check] = 
            DesignCheck.find_by_check_id_and_audit_id(check.id, @audit.id)

          design_checks.push(check_info)

        end

        box[:section]    = section
        box[:subsect]    = subsection
        box[:check_info] = design_checks

        @display.push(box)
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
  # @params['id'] - The ID of the audit.
  #
  ######################################################################
  #
  def auditor_list
    
    @audit = Audit.find(@params[:id])
    
    lead_designer = @audit.design.designer
    lead_peer     = @audit.design.peer

    self_list = Role.find_by_name('Designer').active_users
    peer_list = self_list.dup

    peer_list.delete_if { |u| u.id == @audit.design.designer_id }
    
    checklist_sections = @audit.checklist.sections
    checklist_sections = checklist_sections.sort_by { |s| s.sort_order }

    audit_teammates = @audit.audit_teammates

    sections = []
    for section in checklist_sections
    
    next if ((@audit.design.date_code? && !section.date_code_check?) ||
             (@audit.design.dot_rev?   && !section.dot_rev_check?))
      sect = {
        :section      => section,
        :self_auditor => lead_designer,
        :peer_auditor => lead_peer
      }
    
      self_auditor =
         audit_teammates.detect { |mate| mate.section_id == section.id && mate.self? }
      sect[:self_auditor] = self_auditor.user if self_auditor
      
      peer_auditor = 
        audit_teammates.detect { | mate| mate.section_id == section.id && !mate.self? }
      sect[:peer_auditor] = peer_auditor.user if peer_auditor
      
      sections << sect
      
    end
    
    @auditor_list = {
      :lead_designer => lead_designer,
      :self_list     => self_list,
      :lead_peer     => lead_peer,
      :peer_list     => peer_list,
      :sections      => sections
    }
    
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
    
    lead_designer = audit.design.designer
    lead_peer     = audit.design.peer

    self_auditor_list = params[:self_auditor]
    peer_auditor_list = params[:peer_auditor]
    
    lead_designer_assignments = {}
    lead_designer_assignments.default = false
    self_auditor_list.each { |key, self_auditor|
      if lead_designer.id == self_auditor.to_i
        lead_designer_assignments[key.split('_')[2].to_i] = true
      end
    }

    lead_peer_assignments = {}
    lead_peer_assignments.default = false
    peer_auditor_list.each { |key, peer_auditor|
      if lead_peer.id == peer_auditor.to_i
        lead_peer_assignments[key.split('_')[2].to_i] = true
      end
    }
    
    teammate_list_updates = { 'self' => [], 'peer' => [] }
    
    self_auditor_list.delete_if { |k,v| v.to_i == lead_designer.id }
    peer_auditor_list.delete_if { |k,v| v.to_i == lead_peer.id }

    audit_teammates = audit.audit_teammates
    
    for audit_teammate in audit_teammates
      if ((audit_teammate.self? &&
           lead_designer_assignments[audit_teammate.section_id]) ||
          (!audit_teammate.self? &&
           lead_peer_assignments[audit_teammate.section_id]))

        key = audit_teammate.self? ? 'self' : 'peer'

        teammate_list_updates[key] << {:action   => 'Removed ',
                                       :teammate => audit_teammate.dup}
        audit_teammate.destroy
      end
    end
    
    # Go through the assignments and make sure the same person has
    # not been assigned to the same section for peer and self audits.
    flash['notice'] = ''
    self_auditor_list.each { |key, self_auditor|

      next if self_auditor == ''

      if ((self_auditor == peer_auditor_list[key]) ||
          (!peer_auditor_list[key] && self_auditor.to_i == audit.design.peer_id))
        flash['notice']  = 'WARNING: Assignments not made <br />' if flash['notice'] == ''
        section = Section.find(key.split('_')[2].to_i)
        auditor = User.find(self_auditor)
        flash['notice'] += "         #{auditor.name} can not be both " +
                           "self and peer auditor for #{section.name}<br />"
        self_auditor_list[key] = ''
        peer_auditor_list[key] = ''
      end
      
    }


    self_auditor_list.each { |key, self_auditor|
    
      next if self_auditor == ''
      section_id = key.split('_')[2].to_i
      
      next if audit_teammates.detect{ |t|
        t.self? && t.section_id == section_id && t.user_id == self_auditor.to_i
      }

      audit_teammate = AuditTeammate.new(:audit_id   => audit.id,
                                         :section_id => section_id,
                                         :user_id    => self_auditor,
                                         :self       => 1)
      
      teammate_list_updates['self'] << {:action   => 'Added ',
                                        :teammate => audit_teammate}
      audit_teammate.save

    }

    peer_auditor_list.each { |key, peer_auditor|
    
      next if peer_auditor == ''
      section_id = key.split('_')[2].to_i

      next if audit_teammates.detect{ |t|
        !t.self? && t.section_id == section_id && t.user_id == peer_auditor.to_i
      }  

      audit_teammate = AuditTeammate.new(:audit_id   => audit.id,
                                         :section_id => section_id,
                                         :user_id    => peer_auditor,
                                         :self       => 0)

      teammate_list_updates['peer'] << {:action   => 'Added ',
                                        :teammate => audit_teammate}
      audit_teammate.save
      
    }

    if (teammate_list_updates['self'].size + 
        teammate_list_updates['peer'].size) > 0
    
      flash['notice'] += "Updates to the audit team for the " +
                         "#{audit.design.name} have been recorded - " +
                         "mail was sent"
    
      audit.reload
      TrackerMailer::deliver_audit_team_updates(@session[:user],
                                                audit,
                                                teammate_list_updates)
    end

    redirect_to(:action => 'auditor_list', :id => audit.id)
  
  end


end # class AuditController
