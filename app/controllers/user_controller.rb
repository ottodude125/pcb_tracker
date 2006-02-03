########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: user_controller.rb
#
# This contains the logic to create and modify use information.
#
# $Id$
#
########################################################################

class UserController < ApplicationController

  before_filter(:verify_admin_role,
                :except => [:change_role,
                            :set_role,
                            :login, 
                            :logout])

  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of users from the database for
  # display.  The list is paginated and is limited to the number 
  # passed to the ":per_page" argument.
  #
  ######################################################################
  #
  def list

    @user_pages, @users = paginate(:users,
		                           :per_page => 15,
		                           :order_by => 'last_name ASC')
  end
  

  ######################################################################
  #
  # signup
  #
  # Description:
  # This method retrieves a list of roles from the database for
  # for the signup form.
  #
  ######################################################################
  #
  def signup
    @roles = Role.find_all(nil, 'name ASC')
  end


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves information from the database for
  # for the edit form.
  #
  # Parameters from @params
  # id - the id of the user information that will be edited.
  #
  ######################################################################
  #
  def edit

    @roles = Role.find_all(nil, 'name ASC')
    @user = User.find(@params['id'])
    user_roles = @user.roles

    @uroles = {}
    for u_role in user_roles
      @uroles[u_role.name] = u_role.id
    end

  end


  ######################################################################
  #
  # change_password
  #
  # Description:
  # This method retrieves a user record from the database for the 
  # person identified in the 'id' parameter for display on the 
  # change password form.
  #
  # Parameters from @params
  # id - the id of the user
  #
  ######################################################################
  #
  def change_password
    @user = User.find(@params['id'])
  end


  ######################################################################
  #
  # reset_password
  #
  # Description:
  # This method is called in response to the user submitting the form
  # from the Change Password form.  The password and the confirmation
  # are compared, if they are the same then the user's record is 
  # updated with the new password.
  #
  # Parameters from @params
  # new_password - the new password for the user.
  # new_password_confirmation - used to verify that the user did not typo
  # user['id'] - the id number of the user record to be updated.
  #
  ######################################################################
  #
  def reset_password
  
    updated = false
    if @params['new_password'] == @params['new_password_confirmation']
      user = User.find(@params['user']['id'])
      user.password = @params['new_password']
     
      if user.update
        flash['notice'] = "The password for #{user.name} was updated"
        updated = true
      else
        flash['notice'] = "The password for #{user.name} was not updated"
      end
    else
      flash['notice'] = 'No Update - the new password and the confirmation do not match'
    end
    
    if updated
      redirect_to(:action => :list)
    else
      redirect_to(:action => :change_password,
                  :id     => @params['user']['id'])
    end
 
  end


  ######################################################################
  #
  # update
  #
  # Description:
  # This method updates the user information in the database with 
  # the data passed back from the edit form
  #
  # Parameters from @params
  # user - the user data from the edit form
  #
  ######################################################################
  #
  def update

    user_form = @params['user']
    @user = User.find(user_form['id'])

    if user_form['email'] == ''
      user_form['email'] = user_form['first_name'].downcase + '_' +
        user_form['last_name'].downcase + '@notes.teradyne.com'
    end

    # Go through the data on the form and update any attribute that was
    # modified
    update_good = true
    user_form.each { | key, value |

      next if key == 'id' || key == 'password'
      @user.password = ''
      
      if @user[key] != user_form[key]
        update_good = @user.update_attribute(key, value)
      end
      break if !update_good
    }
   
    # If no errors so far, update the roles for the user.
    if update_good
      @params['role'].each { | role_id, value |
        role = Role.find(role_id)
	      @user.remove_roles(role)
	      @user.roles << role if  value == '1'
      }
    end

    if update_good
      flash['notice'] = "The user information for #{@user.name} was updated"
    else
      flash['notice'] = 'The user information was not updated'
    end

    redirect_to(:action => "edit",
                :id     => @user[:id])
  end
  

  ######################################################################
  #
  # login
  #
  # Description:
  # Validate the user name and password.
  #
  # Parameters from @params
  # user_login    - the user's name 
  # user_password - the user's password
  #
  ######################################################################
  #
  def login
    case @request.method
      when :post
      if @session[:user] = User.authenticate(@params[:user_login], 
                                             @params[:user_password])
      
        @session[:roles]       = @session[:user].roles
        admin   = Role.find_by_name('Admin')
        manager = Role.find_by_name('Manager')
        if @session[:roles].include?(admin)
          @session[:active_role] = admin.name
        elsif @session[:roles].include?(manager)
          @session[:active_role] = manager.name
        else
          @session[:active_role] = @session[:roles].first.name
        end

        flash['notice']  = "Login successful"
        redirect_back_or_default(:controller => 'tracker',
                                 :action     => 'index')
      else
        flash.now['notice']  = "Login unsuccessful"

        @login = @params[:user_login]
      end
    end
  end


  ######################################################################
  #
  # set_role
  #
  # Description:
  # Sets the session role to the role that the user selected.
  #
  # Parameters from @params
  # role id - identifies the role that the use selected 
  #
  ######################################################################
  #
  def set_role

    @session[:active_role] = @session[:roles].find(@params['role']['id']).name
    redirect_back_or_default(:controller => "tracker",
                             :action     => "index")
  end
  

  ######################################################################
  #
  # create
  #
  # Description:
  # Creates a new user in the database
  #
  # Parameters from @params
  # user - information passed back from the view - goes into the 
  #        database.
  #
  ######################################################################
  #
  def create

    @user = User.new(@params[:user])
    
    # If the user left the login and/or email fields blank, set
    # to the default
    if @user.login == ''
      @user.login = @user.first_name[0..0].downcase + 
        @user.last_name.downcase
    end

    if @user.email == ''
      @user.email = @user.first_name.downcase + 
        '_' +
        @user.last_name.downcase +
        '@notes.teradyne.com'
    end

    if @request.post? and @user.save

      @params['role'].each { | role_id, value |
        role = Role.find(role_id)
        @user.roles << role if value == '1'
      }

      flash['notice']  = "Account created for #{@user.name}"
      redirect_back_or_default :action => "list"
    end      
  end  
  

  ######################################################################
  #
  # logout
  #
  # Description:
  # Ends the user's session
  #
  ######################################################################
  #
  def logout
    @session[:user]        = nil
    @session[:roles]       = nil
    @session[:return_to]   = nil
    @session[:active_role] = nil
    
    redirect_to(:controller => 'tracker',
		:action     => 'index')
  end
    


  ######################################################################
  #
  # welcome
  #
  # Description:
  # A default redirect used on the user library.
  #
  ######################################################################
  #
  def welcome
    redirect_back_or_default(:controller => "tracker",
                             :action     => "index")
  end
  

end
