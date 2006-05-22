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
    is_designer = @session[:user][:id] == audit.design.designer_id

    # Go through the paramater list and pull out the checks.
    @params.keys.grep(/^check_/).each { |params_key|

      design_check_update = @params[params_key]
      design_check = DesignCheck.find(design_check_update[:design_check_id])

      if is_designer
        result        = design_check.designer_result
        result_update = design_check_update[:designer_result]
      else
        result        = design_check.auditor_result
        result_update = design_check_update[:auditor_result]
      end

      if result_update != nil and 
          result_update != result

        # Make sure that the required comment has been added.
        if (design_check_update[:comment].strip.size == 0 and 

            ((design_check.check.check_type == 'yes_no' and
              design_check_update[:designer_result] == 'No') or
             
             ((design_check.check.check_type == 'designer_only' or
               design_check.check.check_type == 'designer_auditor') and
              (design_check_update[:designer_result] == 'Waived' or
               design_check_update[:auditor_result] == 'Waived' or
               design_check_update[:auditor_result] == 'Comment'))))
          
          if is_designer
            flash[design_check.id] = "A comment is required for a " +
              "#{design_check_update[:designer_result]}" +
            " response."
          else
            flash[design_check.id] = "A comment is required for a " +
              "#{design_check_update[:auditor_result]}" +
            " response."
          end
          flash['notice'] = 'Not all checks were updated - please review the form for errors.'
          next
        end

        check_count = Audit.check_count(audit.id)
        if is_designer and !audit.designer_complete?
          if result == "None"
           completed_checks = audit.designer_completed_checks + 1
           total_checks     = check_count[:designer]
            audit.update_attributes(
              :designer_completed_checks => completed_checks,
              :designer_complete         => (completed_checks == total_checks))

            TrackerMailer.deliver_self_audit_complete(audit) if audit.designer_complete?
          end
          
          result = design_check.update_attributes(
                     :designer_result     => result_update,
                     :designer_checked_on => Time.now,
                     :designer_id         => @session[:user].id)
                     
        elsif !is_designer and !audit.auditor_complete?

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
            completed_checks = audit.auditor_completed_checks + incr
            total_checks     = check_count[:peer]
            audit.update_attributes(
              :auditor_completed_checks => completed_checks,
              :auditor_complete         => (completed_checks == total_checks))

            TrackerMailer.deliver_peer_audit_complete(audit) if audit.auditor_complete?
          end

          result = design_check.update_attributes(
                     :auditor_result     => result_update,
                     :auditor_checked_on => Time.now,
                     :auditor_id         => @session[:user].id)
          if result_update == 'Comment'
            designer = User.find(audit.design.designer_id)
            TrackerMailer::deliver_audit_update(design_check,
                                                design_check_update[:comment],
                                                designer,
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

    @audit      = Audit.find(@params[:audit_id])
    @subsection = Subsection.find(@params[:subsection_id])
    @section    = Section.find(@subsection.section_id)
    @total_checks = total_checks(@audit)

    is_designer = @session[:user][:id] == @audit.design.designer_id

    condition = ''
    if @audit.design.design_type == 'Date Code'
      condition = ' and date_code_check=1'
    elsif @audit.design.design_type == 'Dot Rev'
      condition = ' and dot_rev_check=1'
    end
    
    if is_designer
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
    for check in @checks
      check[:design_check] = DesignCheck.find_all("check_id=#{check.id} and " +
                                                  "audit_id=#{@audit.id}").pop
      check[:comments] = AuditComment.find_all("design_check_id=#{check[:design_check].id}",
                                                 'created_on DESC')
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

    @audit = Audit.find(@params[:id])
    @board_name = @audit.design.name

    design_checks = DesignCheck.find_all("audit_id=#{@audit.id}")
      design_check_list = Hash.new
    for design_check in design_checks
      design_check_list[design_check.check_id] = design_check
    end

    is_designer = @session[:user][:id] == @audit.design.designer_id


    @checklist_index = Array.new
    sections = Section.find_all("checklist_id=#{@audit.checklist_id}",
                                'sort_order ASC')
    for section in sections

      next if (((not section.full_review?) and 
                (@audit.design.design_type == 'New')) or
               ((not section.date_code_check?) and
                (@audit.design.design_type == 'Date Code')) or
               ((not section.dot_rev_check?) and
                (@audit.design.design_type == 'Dot Rev')))
      section_index = Hash.new
      section_index['section_name'] = section.name
      section_index['section_url']  = section.url
      section_index['bg_color']     = section.background_color
      
      subsections = Subsection.find_all("section_id=#{section.id}",
                                        'sort_order ASC')
      subsects = Array.new
      for subsection in subsections

        next if (((not subsection.full_review?) and 
                  (@audit.design.design_type == 'New')) or
                 ((not subsection.date_code_check?) and
                  (@audit.design.design_type == 'Date Code')) or
                 ((not subsection.dot_rev_check?) and 
                  (@audit.design.design_type == 'Dot Rev')))
        subsect = Hash.new
        subsect['name']             = subsection.name
        subsect['note']             = subsection.note
        subsect['url']              = subsection.url
        subsect['id']               = subsection.id
        subsect['percent_complete'] = 0.0
        
        condition = ''
        if @audit.design.design_type == 'Date Code'
          condition = ' and date_code_check=1'
        elsif @audit.design.design_type == 'Dot Rev'
          condition = ' and dot_rev_check=1'
        end
        
        if is_designer
          subsection_checks = 
            Check.find_all("subsection_id=#{subsection.id}" +
                           condition)
        else
          subsection_checks = 
            Check.find_all("subsection_id=#{subsection.id} and " +
                           "check_type='designer_auditor'" +
                           condition)
        end
        subsect['checks'] = subsection_checks.size
        
        checks_completed = 0
        questions        = 0
        if is_designer

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

    audit     = Audit.find(@params[:id])
    sections  = Section.find_all("checklist_id=#{audit.checklist_id}",
                                 'sort_order ASC')
    @summary = Hash.new
    @summary[:board_number] = audit.design.name
    if audit.design.designer_id > 0
      @summary[:designer] = User.find(audit.design.designer_id).name
    else
      @summary[:designer] = 'Not Set'
    end
    if audit.design.peer_id > 0
      @summary[:auditor] = User.find(audit.design.peer_id).name
    else
      @summary[:auditor] = 'Not Set'
    end

    @summary[:checklist_rev] =
      audit.checklist.major_rev_number.to_s +
      '.' +
      audit.checklist.minor_rev_number.to_s

    designer_names = Hash.new
    @display       = Array.new
    for section in sections
      
      next if ((audit.design.design_type == 'New' and
                not section.full_review?)            or
               (audit.design.design_type == 'Date Code' and 
                not section.date_code_check?)        or
               (audit.design.design_type == 'Dot Rev'   and 
                not section.dot_rev_check?))

      subsections = Subsection.find_all("section_id=#{section.id}",
                                        'sort_order ASC')

      for subsection in subsections

        next if ((audit.design.design_type == 'New' and
                  not subsection.full_review?)         or
                 (audit.design.design_type == 'Date Code' and 
                  not subsection.date_code_check?)     or
                 (audit.design.design_type == 'Dot Rev'   and 
                  not subsection.dot_rev_check?))

        box = Hash.new
        design_checks = Array.new
        checks  = Check.find_all("subsection_id=#{subsection.id}",
                                 'sort_order ASC')

        # JPA - There really should be a test to make sure that only one
        #       design check is found for the audit/check combination.
        for check in checks

          next if ((audit.design.design_type == 'New' and
                    not check.full_review?)             or
                   (audit.design.design_type == 'Date Code' and 
                    not check.date_code_check?)         or
                   (audit.design.design_type == 'Dot Rev'   and 
                    not check.dot_rev_check?))

          check_info = Hash.new
          check_info[:check]        = check

          check_info[:design_check] = 
            DesignCheck.find_all("check_id=#{check.id} and " +
                                 "audit_id=#{audit.id}").pop

            check_info[:comments] =
            AuditComment.find_all("design_check_id=#{check_info[:design_check].id}",
                                  'created_on DESC')

          if check_info[:design_check].designer_id > 0
            if designer_names[check_info[:design_check].designer_id] == nil
              designer_names[check_info[:design_check].designer_id] =
                User.find(check_info[:design_check].designer_id).name
            end
            check_info[:designer] = 
              designer_names[check_info[:design_check].designer_id]
          else
            check_info[:designer] = ''
          end
          if check_info[:design_check].auditor_id > 0
            if designer_names[check_info[:design_check].auditor_id] == nil
              designer_names[check_info[:design_check].auditor_id] =
                User.find(check_info[:design_check].auditor_id).name
            end
            check_info[:auditor] = 
              designer_names[check_info[:design_check].auditor_id]
          else
            check_info[:auditor] = ''
          end

          design_checks.push(check_info)
        end
        box[:section]    = section
        box[:subsect]    = subsection
        box[:check_info] = design_checks

        @display.push(box)
      end
    end
  end # print method


  ########################################################################
  private


  ######################################################################
  #
  # get_audit_list
  #
  # Description:
  # This method retrieves the checks for the subsection identified
  # by subsection_id
  #
  # Parameters:
  # audit_id      - identifies the audit 
  # subsection_id - identifies the subsection
  #
  # Return value:
  # A list of checks based on the subsection and board type.
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def get_audit_list(audit_id, subsection_id)

    case Audit.find(audit_id).design.design_type

    when 'New'
      checks = Check.find_all("subsection_id=#{subsection_id} and " +
                              "full_review=1",
                              'sort_order ASC')
    when 'Date Code'
      checks = Check.find_all("subsection_id=#{subsection_id} and " +
                              "date_code_check=1",
                              'sort_order ASC')
    when 'Dot Rev'
      checks = Check.find_all("subsection_id=#{subsection_id} and " +
                              "dot_rev_check=1",
                              'sort_order ASC')
    end

    
    i = 0;
    check_list = Array.new
    for check in checks
      design_check = DesignCheck.find_all("audit_id=#{audit_id} and " +
                                          "check_id=#{check.id}").pop
        check_list[i] = Hash.new
      check_list[i][:check]        = check
      check_list[i][:design_check] = design_check

      i += 1
    end
    
    return check_list

  end


  ######################################################################
  #
  # total_checks
  #
  # Description:
  # Computes the total number of checks for the designer and auditor
  # given the board type.
  #
  # Parameters:
  # audit  - identifies the audit 
  #
  # Return value:
  # checks - a hash containing the total checks for both the designer
  #          and the auditor.
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def total_checks(audit)

    # Compute the metrics for the designer's checks.
    checks = Hash.new
    if audit.design.design_type == 'New'
      checks[:designer] = audit.checklist.designer_only_count +
        audit.checklist.designer_auditor_count
      checks[:auditor]  = audit.checklist.designer_auditor_count
    elsif audit.design.design_type == 'Date Code'
      checks[:designer] = audit.checklist.dc_designer_only_count +
        audit.checklist.dc_designer_auditor_count
      checks[:auditor]  = audit.checklist.dc_designer_auditor_count
    elsif audit.design.design_type == 'Dot Rev'
      checks[:designer] = audit.checklist.dr_designer_only_count +
        audit.checklist.dr_designer_auditor_count
      checks[:auditor]  = audit.checklist.dr_designer_auditor_count
    end

    return checks

  end


end # class AuditController
