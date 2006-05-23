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
  model :user

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
  # Parameters from @params
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
                                     @session.instance_variable_get("@data"),
                                     @params,
                                     @request.env)
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
    unless session[:active_role] == 'Admin'
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
                        @params["controller"] + '/' +
                        @params["action"]     + 
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
      redirect_to(:controller => 'tracker',
                    :action     => "index")
    end
  end

end
