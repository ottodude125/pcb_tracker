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


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves audits from the database to display
  # a list.
  #
  # Parameters from @params
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  # Validates the user is an Admin or Manager before proceeding.
  #
  ######################################################################
  #
  def list

    if (@session[:active_role] != "Admin" &&
        @session[:active_role] != "Manager")
      flash['notice'] = 'You are not authorized to view or modify audit information - check your role'
      redirect_to(:controller => 'tracker',
                  :action     => "index")
    else

      # Save the page number.
      @session[:page] = @params[:page]

      #      @audit_pages, @audits = paginate(:audits,
      #                                       :per_page   => 2,
      #                                       :order_by   => 'id DESC')
      raw_audits = Audit.find_all

      for audit in raw_audits 

        board = audit.design.board

        audit[:display_name] = audit.design.name
        audit[:platform] = Platform.find(board.platform_id).name
        audit[:project]  = Project.find(board.project_id).name
        audit[:designer] = User.find(audit.design.designer_id).name
        audit[:auditor]  = User.find(audit.design.peer_id).name
      end


      temp_audits = Hash.new
      for audit in raw_audits
        temp_audits[audit[:display_name]] = audit
      end

      sorted_audits = temp_audits.sort
      i = 0
      sorted_audits.each { |k, v|
        raw_audits[i] = v
        i += 1
      }

      @audit_pages, @audits = paginate_collection(raw_audits, 
                                                  :page => @params[:page])

    end

  end # list method


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the audit from the database for display.
  #
  # Parameters from @params
  # ['id'] - Used to identify the audit to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def edit

    @audit = Audit.find(@params[:id])

    # Get a list of designers.
    @designers = Role.find_by_name("Designer").users.sort_by { |u| u.last_name }

    # Only consider active designers
    @designers.delete_if { |designer| ! designer.active? }

  end # edit method


  ######################################################################
  #
  # update
  #
  # Description:
  # This method is called when the user submits from the edit audit
  # screen.  The database is updated with the changes made by the user.
  #
  # Parameters from @params
  # ['audit'] - Contains the udpated audit data.
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def update

    if @params['audit']['designer_id'] != @params['audit']['auditor_id']

      @audit = Audit.find(@params['audit']['id'])

      design = @audit.design
      design.designer_id = @params['audit']['designer_id']
      design.peer_id     = @params['audit']['auditor_id']
      
      if design.save
        flash['notice'] = 'Audit was successfully updated.'
        redirect_to(:action => 'list',
                    :page   => @session[:page])
        @session[:page] = nil
      else
	flash['notice'] = 'Audit was not updated.'
	redirect_to(:action => 'edit',
		    :id     => @params['audit']['id'])
      end
    else
      flash['notice'] = 'The designer and auditor must be different.'
      redirect_to(:action => 'edit',
                  :id     => @params['audit']['id'])
    end

  end # update method


  ######################################################################
  #
  # create
  #
  # Description:
  # This method retrieves the boards and designers for selection to add
  # an audit.  Once the data is retrieved, the add audit screen is displayed.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  # Validates the user is an Admin or Manager before proceeding.
  #
  ######################################################################
  #
  def create

    new_audit = @params[:new_audit]

    # Verify that the audit is not already in the system.
    if (new_audit[:board_type] == 'Date Code' ||
        new_audit[:board_type] == 'Dot Rev')
      audit = Audit.find_all("board_id=#{new_audit[:board_id]} and " +
                             "revision_id=#{new_audit[:revision_id]} and " +
                             "board_type='#{new_audit[:board_type]}' and " +
                             "suffix_id=#{new_audit[:suffix_id]}")
    elsif new_audit[:board_type] == 'New Board'
      audit = Audit.find_all("board_id=#{new_audit[:board_id]} and " +
                             "revision_id=#{new_audit[:revision_id]} and " +
                             "board_type='#{new_audit[:board_type]}'")
    end
    
    if audit != nil && audit.size > 0

      @board = Board.find(new_audit[:board_id])
      
      if new_audit[:board_type] == 'Date Code'

        flash['notice'] = "The audit exists for " +
          "#{@board.prefix.pcb_mnemonic}#{@board.number}" +
        "#{Revision.find(new_audit[:revision_id]).name}" +
        '_eco' +
          "#{Suffix.find(new_audit[:suffix_id]).name}"
        redirect_to(:designer_id => new_audit[:designer_id],
                    :auditor_id  => new_audit[:auditor_id],
                    :board_id    => new_audit[:board_id],
                    :board_type  => 'Date Code',
                    :action      => 'select_date_code_revision')
      elsif new_audit[:board_type] == 'Dot Rev'
        flash['notice'] = "The audit exists for " +
          "#{@board.prefix.pcb_mnemonic}#{@board.number}" +
        "#{Revision.find(new_audit[:revision_id]).name}" +
        "#{Suffix.find(new_audit[:suffix_id]).name}"
        redirect_to(:designer_id => new_audit[:designer_id],
                    :auditor_id  => new_audit[:auditor_id],
                    :board_id    => new_audit[:board_id],
                    :board_type  => 'Dot Rev',
                    :action      => 'select_dot_rev_revision')
      end
    else
      
      # Get the most recently released checklist.
      checklist = Checklist.find_all("released=1", 
                                     "major_rev_number ASC").pop
      
      params_audit = @params[:new_audit]
      if params_audit[:suffix_id] == nil
        params_audit[:suffix_id] = 0
      end
      
      new_audit = Hash.new
      new_audit['board_type']   = params_audit[:board_type]
      new_audit['board_id']     = params_audit[:board_id]
      new_audit['revision_id']  = params_audit[:revision_id]
      if params_audit[:board_type] == 'New Board'
        new_audit['suffix_id']    = 0
      else
        new_audit['suffix_id']    = params_audit[:suffix_id]
      end
      new_audit['checklist_id'] = checklist.id
      new_audit['designer_id']  = params_audit[:designer_id]
      new_audit['auditor_id']   = params_audit[:auditor_id]
      new_audit['complete']     = 0
      
      @audit = Audit.new(new_audit)
      
      if @audit.save
        create_checklist(@audit.id)
        flash['notice'] = "Audit was successfully created."
        redirect_to :action => 'list'
      else
        flash['notice'] = "Audit was not created."
        redirect_to :action => 'list'
      end
    end

  rescue
    flash[:notice] = "Audit could not be saved."
    redirect_to :action => 'list'
  end # end create method

  
  ######################################################################
  #
  # designer_list
  #
  # Description:
  # Called from the tracker index to list both the designs that 
  # the designer has in audit and the designs that the designer
  # is auditing.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def designer_list

    my_designs = Design.find_all("designer_id=#{@session[:user][:id]}",
				 'revision_id ASC, suffix_id ASC')
    my_audits  = Design.find_all("peer_id=#{@session[:user][:id]}",
				 'revision_id ASC, suffix_id ASC')

    @my_designs = Array.new
    for design in my_designs
      @my_designs.push(design.audit)
    end

    @my_audits = Array.new
    for design in my_audits
      @my_audits.push(design.audit)
    end
    
    # Gather the information to display the designer's boards that are in audit.
    for audit in @my_designs
      audit[:my_design_metrics] = collect_dashboard_data(audit)
    end

    # Gather the information to display the designer's boards that are in audit.
    for audit in @my_audits
      audit[:my_audit_metrics] = collect_dashboard_data(audit)
    end

  end # designer_list method


  ######################################################################
  #
  # update_design_checks
  #
  # Description:
  # This method takes in a list of design checks and processes each on
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

            AuditMailer.deliver_alert_peer(audit) if audit.designer_complete?
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

            AuditMailer.deliver_alert_designer(audit) if audit.auditor_complete?
          end
        end

        result =
          design_check.update_attributes(:auditor_result     => result_update,
                                         :auditor_checked_on => Time.now,
                                         :auditor_id         => @session[:user].id)
        
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
    @summary[:designer] = User.find(audit.design.designer_id).name
    @summary[:auditor]  = User.find(audit.design.peer_id).name

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


  ######################################################################
  #
  # collect_dashboard_data
  #
  # Description:
  # Gathers the data to be displayed in the designers list of 
  # peer audit reviews.
  #
  # Parameters:
  # audit  - identifies the audit 
  #
  # Return value:
  # metric data  - the summary information displayed on the 
  #                designer's list.
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def collect_dashboard_data(audit)

    metrics = Hash.new()

    metrics[:display_name] = audit.design.name
    metrics[:designer]     = User.find(audit.design.designer_id).name
    metrics[:auditor]      = User.find(audit.design.peer_id).name

    total_checks = total_checks(audit)

    metrics[:designer_check_count]      = total_checks[:designer]
    metrics[:designer_percent_complete] = audit.designer_completed_checks*100.0/total_checks[:designer]

    metrics[:auditor_check_count] = total_checks[:auditor]
    metrics[:auditor_check_complete] = audit.auditor_completed_checks*100.0/total_checks[:auditor]

    metrics[:auditor_questions] = 
      DesignCheck.find_all("audit_id=#{audit.id} and " +
                           "auditor_result='Comment'").size

    return metrics
    
  end # collect_dashboard_data method


end # class AuditController
