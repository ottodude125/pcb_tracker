########################################################################
#
# Copyright 2006, by Teradyne, Inc., Boston MA
#
# File: application.rb
#
# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
#
# TODO: THIS FILE IS IN TRANSITION.  IT IS BEING USED TO WEAN THE TRACKER OFF 
#       OF THE USE OF SESSION[:USER], SESSION[:ACTIVE_ROLE], AND SESSION[:ROLES].
#       THE SESSION ENTRIES ARE BEING REPLACED BY SESSION[:USER_ID] WHICH IS SET 
#       IN THE USER_CONTROLLER.  THE SET_INSTANCE_VARIABLES METHOD, DECLARED AS A
#       BEFORE FILTER BELOW USES SESSION[:USER_ID] TO SET @logged_in_user.  THIS BEFORE FILTER 
#       IS CALLED UNCONDITIONALLY.  THE @logged_in_user VARIABLE PROVIEDS ACCESS TO THE USER'S 
#       ACTIVE_ROLE AS WELL AS THE ROLES.
#       
#       THE LOGGING NEEDS TO BE REMOVED FROM THE FOLLOWING METHODS
#       
#               verify_admin_role()
#               verify_logged_in()
#               verify_manager_admin_privs()
#               verify_pcb_group()
#               
#        THE set_instance_variables() method is documented to indicate the 
#        lines that need to be removed.
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


  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_feb_pcbtr_session_id'


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
      TrackerMailer.deliver_snapshot(exception,
                                     clean_backtrace(exception),
                                     session.instance_variable_get("@data"),
                                     params,
                                     request.env)
    rescue => e
      logger.error(e)
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
    # logger.info '################# verify_admin_role #################'
    # logger.info '## USER: ' + @logged_in_user.name  if @logged_in_user
    # logger.info '>> @logged_in_user IS NOT DEFINED' if !@logged_in_user
    # logger.info '-----------------------------------------------------'
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
    # logger.info '################# verify_logged_in #################'
    # logger.info '## USER: ' + @logged_in_user.name  if @logged_in_user
    # logger.info '>> @logged_in_user IS NOT DEFINED' if !@logged_in_user
    # logger.info '----------------------------------------------------'
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
    # logger.info '################# verify_manager_admin_privs #################'
    # logger.info '## USER: ' + @logged_in_user.name  if @logged_in_user
    # logger.info '>> @logged_in_user IS NOT DEFINED' if !@logged_in_user
    # logger.info '--------------------------------------------------------------'

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

    # logger.info '################# verify_pcb_group #################'
    # logger.info '## USER: ' + @logged_in_user.name  if @logged_in_user
    # logger.info '>> @logged_in_user IS NOT DEFINED' if !@logged_in_user
    # logger.info '----------------------------------------------------'
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
    session[:return_to] = request.request_uri
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
    @logged_in_user = session[:user_id] ? User.find(session[:user_id]) : session[:user]
    
    
    # THE CODE BELOW THIS LINE IN THIS METHOD WILL BE REMOVED WHEN THE TRANSITION
    # IS COMPLETE
    remove_obsolete_session_variables = true
    
    if remove_obsolete_session_variables
      session[:user]        = nil
      session[:roles]       = nil
      session[:active_role] = nil
    elsif @logged_in_user
      session[:user]        = @logged_in_user
      session[:roles]       = @logged_in_user.roles
      session[:active_role] = @logged_in_user.active_role
    end
    
    # logger.info '################# set_instance_variables #################'
    # logger.info '## USER:                  ' + @logged_in_user.name             if @logged_in_user
    # logger.info '## ACTIVE_ROLE:           ' + @logged_in_user.active_role.name if @logged_in_user
    # logger.info '## NUMBER OF ROLES:       ' + @logged_in_user.roles.size.to_s  if @logged_in_user
    # logger.info '## session[:user]:        ' + session[:user].name        if session[:user]
    # logger.info '## session[:active_role]: ' + session[:active_role].name if session[:active_role]
    # logger.info '## session[:roles].size:  ' + session[:roles].size.to_s  if session[:roles]
    # logger.info '>> @logged_in_user       IS NOT DEFINED' if !@logged_in_user
    # logger.info '>> session[:user]        IS NOT DEFINED' if !session[:user]
    # logger.info '>> session[:active_role] IS NOT DEFINED' if !session[:active_role]
    # logger.info '>> session[:roles]       IS NOT DEFINED' if !session[:roles]
    # logger.info '---------------------------------------------------------'
  end

  
end