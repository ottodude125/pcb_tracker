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


  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_feb_pcbtr_session_id'


  # Do not allow any of the following listed actions unless the user is logged
  # in.
  before_filter :login_required, :only => [:append,
                                           :copy, 
                                           :destroy,
                                           :edit,
                                           :insert,
                                           :modify_checks,
                                           :move_down,
                                           :move_up, 
                                           :release]



  ######################################################################
  #
  # paginate_collection
  #
  # Description:
  # Updates the based on user input on the admin update screen.
  #
  # Parameters from params
  #
  # Return value:
  # pages - the paged listing.
  # slice - identifies the first and last element on the page from pages.
  #
  ######################################################################
  #
  def paginate_collection(collection, options ={})
    default_options = {:per_page => 15, :page => 1}
    options = default_options.merge options

    pages = Paginator.new(self,
                          collection.size, 
                          options[:per_page],
                          options[:page])
    first = pages.current.offset
    last  = [first + options[:per_page], collection.size].min
    slice = collection[first...last]
    return [pages, slice]
  end
  
  
  ######################################################################
  #
  # current_quarter
  #
  # Description:
  # Computes the current quarter.
  #
  # Parameters from params
  # date - A time stamp to base the current quarter on.
  #
  # Return value:
  # The current quarter.
  #
  ######################################################################
  #
  def current_quarter(date = Time.now)
  
    case date.month
    
    when 1..3: 1
    when 4..6: 2
    when 7..9: 3
    else       4
    end
    
  end

  
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
    unless session[:active_role] && session[:active_role].name == 'Admin'
      flash['notice'] = Pcbtr::MESSAGES[:admin_only]
      redirect_to(:controller => 'tracker',
                  :action     => "index")
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
    unless session[:user]
      flash['notice'] = Pcbtr::PCBTR_BASE_URL +
                        params["controller"] + '/' +
                        params["action"]     + 
                        " - unavailable unless logged in."
      redirect_to(:controller => 'tracker',
                  :action     => "index")
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
    admin   = Role.find_by_name('Admin')
    manager = Role.find_by_name('Manager')

    begin
      unless session[:roles].include?(admin) ||
             session[:roles].include?(manager)
        flash['notice'] = 'Access not allowed'
        redirect_to(:controller => 'tracker',
                    :action     => "index")
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

    valid_user = false
    role_list = ['Designer']

    if session[:user]
      roles = session[:user].roles.collect { |r| r.name }  
      valid_user = (roles & role_list).size > 0
      
      if valid_user
        employee_actions = ['oi_category_selection',
                            'process_assignment_details',
                            'process_assignments', 
                            'section_selection',
                            'report_card_list',
                            'view_assignments',
                            'view_assignment_report']
        if employee_actions.detect { |a| a == params[:action] }
          valid_user &= session[:user].employee?
        end
      end
    end
    
    if !valid_user
      flash['notice'] = 'You are not authorized to access this page'
      redirect_to(:controller => 'tracker', :action => 'index')
    end
  
  end
  
  
end
