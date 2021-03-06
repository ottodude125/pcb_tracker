########################################################################
#
# Copyright 2006, by Teradyne, Inc., Boston MA
#
# File: application.rb
#
# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
#
# $Id$
#
########################################################################


require_dependency "login_system"



class ApplicationController < ActionController::Base


  include LoginSystem
#  include Sitealizer
#  before_filter :use_sitealizer
#  model :user
  helper :time

  # Do not allow any of the following listed actions unless the user is logged
  # in.  The login_required method is located in lib/login_system.rb
  before_filter :login_required, :only => [:append,
                                           :copy, 
                                           :destroy,
                                           :edit,
                                           :insert,
                                           :modify_checks,
                                           :move_down,
                                           :move_up, 
                                           :release]

  before_filter :set_instance_variables
  
  before_filter :load_valid_system_messages

  before_filter :set_access

  protected
  
  ######################################################################
  #
  # log_error
  #
  # Description:
  # Sends mail to DTG whenever a user encounters an error.
  #
  ######################################################################
  #
  def log_error(exception)
    begin
      ApplicationMailer.snapshot(exception,
                                     clean_backtrace(exception),
                                     session.instance_variable_get("@data"),
                                     params,
                                     request.env)
    rescue => e
      logger.error(e)
    end
  end
  
  ######################################################################
  #
  # load_valid_system_messages
  #
  # Description:
  # Loads the system messages which the user has not yet seen.
  #
  ######################################################################
  def load_valid_system_messages
    @message = ""
    if @logged_in_user
      messages  = SystemMessage.users_valid_messages(Time.now, @logged_in_user)
    
      if messages != []
        @message = ""
        
        messages.each do |m|
          @message << "<b>" + m.title + " - " + m.updated_at.format_month_dd_yyyy + 
                      "</b><br/>" + m.body + "<br/>-- " + User.find(m.user_id).name + "<br/><br/>"
        end
      end
    end    
    @message
  end

  # Record the last time a user accessed a page
  #
  # :call-seq:
  #    set_access
  #
  #  Sets @logged_in_user.access to NOW
  def set_access
    if @logged_in_user
      @logged_in_user.update_column(:access, Time.now)
    end
  end


  private

  ######################################################################
  #
  # verify_admin_role
  #
  # Description:
  # Verifies that the user is an administrator
  #
  # Return value:
  # TRUE if the user is an admin, false otherwise
  #
  # Additional Information:
  # Set flash['notice'] if the user is not an admin for the message to
  # be displayed.
  #
  ######################################################################
  #
  def verify_admin_role
    unless @logged_in_user && @logged_in_user.is_a_role_member?('Admin')
      flash['notice'] = Pcbtr::MESSAGES[:admin_only]
      redirect_to(:controller => 'tracker', :action => "index")
    end
  end

  ######################################################################
  #
  # verify_logged_in
  #
  # Description:
  # Verifies that the user logged in.
  #
  # Return value:
  # TRUE if the user is logged in, false otherwise
  #
  # Additional Information:
  # Set flash['notice'] if the user is not logged in.
  #
  ######################################################################
  #
  def verify_logged_in
    unless @logged_in_user
      flash['notice'] = Pcbtr::PCBTR_BASE_URL +
                        params["controller"] + '/' +
                        params["action"]     + 
                        " - unavailable unless logged in."
      redirect_to(:controller => 'tracker', :action => "index")
    end
  end

  ######################################################################
  #
  # verify_manager_admin_privs
  #
  # Description:
  # Verifies that the user is either an administrator or a PCB manager.
  #
  # Return value:
  # TRUE if the user is an admin or a PCB manager, false otherwise
  #
  # Additional Information:
  # Set flash['notice'] if the user is not an admin or PCB Manager for the 
  # message to be displayed.
  #
  ######################################################################
  #
  def verify_manager_admin_privs

    begin
      unless @logged_in_user.is_manager? || @logged_in_user.is_a_role_member?('Admin')
        flash['notice'] = 'Access not allowed'
        redirect_to(:controller => 'tracker', :action => "index")
      end
    rescue
      flash['notice'] = 'Update not allowed - Must be admin or manager'
      redirect_to(:controller => 'tracker', :action => "index")
    end
  end


  ######################################################################
  #
  # verify_approve_fab_house_privs
  #
  # Description:
  # Verifies that the user is either an administrator or a PCB manager.
  #
  # Return value:
  # TRUE if the user is an admin or a PCB manager, false otherwise
  #
  # Additional Information:
  # Set flash['notice'] if the user is not an admin or PCB Manager for the 
  # message to be displayed.
  #
  ######################################################################
  #
  def verify_approve_fab_house_privs

    begin
      
      unless @logged_in_user.is_a_role_member?(Role.get_npp_role.name)
        flash['notice'] = 'Access to approve Fab Houses not allowed'
        redirect_to(:controller => 'tracker', :action => "index")
      end
    rescue
      flash['notice'] = 'Update not allowed - Must belong to New Product Planner group'
      redirect_to(:controller => 'tracker', :action => "index")
    end
  end  
  
  ######################################################################
  #
  # verify_pcb_group
  #
  # Description:
  # Verifies that the user is a member of the PCB Group.  In addition,
  # any action listed in employee_actions is limited to users that are
  # employees (vs. contractors/outsource).
  #
  # Return value:
  # TRUE for the following conditions:
  # 
  #   - the user is a member of the PCB Design Group and the action is
  #     not listed in employee_actions
  #   - the user is a member of the PCB Design Group, an employee, and 
  #     the action is listed in employee_actions
  #     
  #  Otherwise false is returned.
  #
  # Additional Information:
  # Set flash['notice'] if the user is not a valid user
  #
  ######################################################################
  #
  def verify_pcb_group

    valid_user = false

    if @logged_in_user

      roles = @logged_in_user.roles.collect { |r| r.name }  
      role_list = ['Designer', 'Manager']
      valid_user = (roles & role_list).size > 0
      
      if valid_user
        employee_actions = ['oi_category_selection',
                            'process_assignment_details',
                            'process_assignments', 
                            'section_selection',
                            'report_card_list',
                            'static_view',
                            'view_assignments',
                            'view_assignment_report']
        if employee_actions.detect { |a| a == params[:action] }
          valid_user &= @logged_in_user.employee?
        end
      end
    end
    
    if !valid_user
      flash['notice'] = 'You are not authorized to access this page'
      redirect_to(:controller => 'tracker', :action => 'index')
    end
  
  end
  
  
  # Set the stored return target
  #
  # :call-seq:
  #   set_stored() -> nil
  #
  #  Sets the "return_to" field in the session variable.
  def set_stored
    session[:return_to] = request.fullpath
  end
  
  
  # Redirect to the stored return target
  #
  # :call-seq:
  #   redirect_to_stored() -> string
  #
  #  If a return target url was stored provide that url, otherwise send the
  #  tracker back to the home page
  def redirect_to_stored
    if return_to = session[:return_to]
      session[:return_to] = nil
      redirect_to(return_to)
    else
      redirect_to( :controller => 'tracker' )
    end
  end
  
  
  # Load the instance variables used throughout the code.
  #
  # :call-seq:
  #   set_instance_variables() -> nil
  #
  #  Sets instance variables used by several actions/views.
  def set_instance_variables
    if session[:user_id]
      @logged_in_user = User.find(session[:user_id])
    end
  end

end

