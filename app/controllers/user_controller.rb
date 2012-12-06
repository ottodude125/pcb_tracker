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
                :except => [:auto_complete_for_user_last_name,
                            :change_role,
                            :login,
                            :login_information,
                            :logout,
                            :send_password,
                            :set_role,
                            :show_users,
                            :user_set_password,
                            :user_store_password,
                            :update_ldap])

  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of users from the database for
  # display.  If the 'alpha' param is passed in the value is used to
  # determine which uses to display, otherwise users whose name begins
  # with 'A' are displayed by default.
  #
  ######################################################################
  #
  def list

    alpha = params[:alpha] ? params[:alpha] : 'A'

    users = User.find(:all, :order => 'last_name ASC')

    @alpha_list = {}
    for user in users
      index = user.last_name.slice(0..0).upcase
      @alpha_list[index] = 0 if !@alpha_list[index]
      @alpha_list[index] += 1
    end

    @users = User.find(:all,
                       :conditions => "LOWER(last_name) LIKE '#{alpha.downcase}%'",
                       :order      => 'last_name ASC')

  end


  ######################################################################
  #
  # send_password
  #
  # Description:
  # This method is called in response the the users clicking the
  # "Send Password" button.  The user's record is retrieve and
  # the password is emailed to the user.
  #
  ######################################################################
  #
  def send_password

    user = User.find(params[:id])
    UserMailer.user_password(user).deliver

    redirect_to(:action  => 'login_information',
                :user_id => user.id)
  end


  ######################################################################
  #
  # login_information
  #
  # Description:
  # This method is called under two conditions.
  #
  # 1) the user has clicked the "Login Help" button to retrieve
  # user information based on the last name provided by the user.
  # All user records with that match the last name are displayed
  # along with a button to request the password be emailed to the
  # user.
  #
  # 2) the user has requested the password via email.  The user's
  # record will be displayed along with a message indicating that
  # the password has been emailed.
  #
  ######################################################################
  #
  def login_information

    if params[:user_id]
      @user_list = [User.find(params[:user_id])]
      flash['notice'] = 'Your password has been sent to the email address listed below'
    elsif params[:user].blank? || params[:user][:last_name].blank?
      flash['notice'] = "Please provide a last name"
      redirect_to(:action => 'show_users')
    else
      last_name  = params[:user][:last_name]
      @user_list = User.find_all_by_last_name(last_name)
      if @user_list.size == 0
        flash['notice'] = "#{last_name} was not found"
        redirect_to(:action => 'show_users')
      end
    end
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
    @roles    = Role.find_all_active
    @new_user = User.new(:employee => '1', :active => '1')
  end


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves information from the database for
  # for the edit form.
  #
  # Parameters from params
  # id - the id of the user information that will be edited.
  #
  ######################################################################
  #
  def edit

    @roles     = Role.find_all_active
    @user      = User.find(params[:id])
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
  # Parameters from params
  # id - the id of the user
  #
  ######################################################################
  #
  def change_password
    @user = User.find(params[:id])
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
  # Parameters from params
  # new_password - the new password for the user.
  # new_password_confirmation - used to verify that the user did not typo
  # user['id'] - the id number of the user record to be updated.
  #
  ######################################################################
  #
  def reset_password

    updated = false
    if params[:new_password] == params[:new_password_confirmation]
      user = User.find(params[:user][:id])
      user.password              = params[:new_password]
      user.password_confirmation = params[:new_password]
      user.passwd                = params[:new_password]

      if user.save
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
                  :id     => params[:user][:id])
    end

  end


  ######################################################################
  #
  # user_store_password
  #
  # Description:
  # This method updates the user's password.
  #
  ######################################################################
  #
  def user_store_password

    updated = false
    if params[:new_password].size < 5
      flash['notice'] = 'No Update - the password must be at least 5 characters'
    elsif params[:new_password] == params[:new_password_confirmation]
      @logged_in_user.password = params[:new_password]
      @logged_in_user.passwd   = params[:new_password] if not params[:new_password].empty?
      @logged_in_user.password_confirmation = params[:new_password_confirmation]

      if @logged_in_user.save
        if not params[:new_password].empty?
          flash['notice'] = "The password for #{@logged_in_user.name} was updated"
          updated = true
        else
          flash['notice'] = 'No Update - no password was entered'
        end
      else
        flash['notice'] = "The password for #{@logged_in_user.name} was not updated"
      end
    else
      flash['notice'] = 'No Update - the new password and the confirmation do not match'
    end

    if updated
      redirect_to(:controller => 'tracker')
    else
      redirect_to(:action => :user_set_password)
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
  # Parameters from params
  # user - the user data from the edit form
  #
  ######################################################################
  #
  def update

    user_form = params[:user]
    @user = User.find(user_form['id'])

    if params[:user][:email] == ''
      params[:user][:email] = params[:user][:first_name].downcase + '.' +
        params[:user][:last_name].downcase + '@teradyne.com'
    end

    assigned_roles = params[:role].select { |id,value| value == '1' }.size > 0


    # Go through the data on the form and update any attribute that was
    # modified
    update_good = nil
    
    params[:user][:password] = @user.passwd
    params[:user][:password_confirmation] = @user.passwd
    
    if assigned_roles
      update_good = @user.update_attributes(params[:user])
    end

    # If no errors so far, update the roles for the user.
    if update_good

      params[:role].each { | role_id, value |
        role = Role.find(role_id)
        if @user.roles.include?(role)
	      @user.roles.delete(role) if value == '0'
	    else
	      @user.roles << role      if value == '1'
	    end
      }

      role_count = @user.roles.size
      @user.roles << Role.find_by_name("Basic User") if role_count == 0

    end

    if update_good
      flash[:notice] = "The user information for #{@user.name} was updated"
    elsif !assigned_roles
      flash[:notice] = "The user information for #{@user.name} was not updated - assign to at least one role."
    else
      flash[:notice] = 'The user information was not updated'
    end
    if @user.errors[:email] != [] || @user.errors.size > 0
      flash[:error] = []
      @user.errors.each do |key,value|
        flash[:error] <<  "ERROR: #{key}" + " " + "#{value}"
      end
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
  # Parameters from params
  # user_login    - the user's name
  # user_password - the user's password
  #
  ######################################################################
  #
  def login
    case request.method
    when "POST"
      if user = User.authenticate(params[:user_login], params[:user_password])
  
        # TODO: Remove the dependence on these variables.
        session[:user_id]  = user.id
  
        admin    = Role.find_by_name('Admin')
        manager  = Role.find_by_name('Manager')
        designer = Role.find_by_name('Designer')
  
        case
        when user.roles.include?(admin)    then user.active_role = admin
        when user.roles.include?(manager)  then user.active_role = manager
        when user.roles.include?(designer) then user.active_role = designer
        else                                    user.active_role = user.roles.first
        end
  
        flash['notice']  = "Login successful"
        if user.ldap_account.blank? && ! user.ldap_optout? && ! Rails.env.development?
          @user = user
          render(:action => "update_ldap")
        else
          redirect_back_or_default(:controller => 'tracker', :action => 'index')
        end
      else
        flash.now['notice']  = "Login unsuccessful"
  
        @login = params[:user_login]
      end
    else
      # probably from "before_filter :login_required"
      flash['notice'] = "Please Login"
      # TODO: Change this so the user gets back to the original page
      #       after logging in
      redirect_to(:controller => 'tracker', :action => 'index')
    end
  end

  ######################################################################
  #
  # update_ldap
  #
  # Description:
  # Saves the ldap user name
  #
  # Parameters from params
  #    ldap_name
  #    ldap_password
  ######################################################################
  #
  def update_ldap
    login = params[:ldap_name]
    pass  = params[:ldap_password]
    optout= params[:optout]
   
    @user  = User.find(params[:id])
    
    if optout 
      @user.update_attribute(:ldap_optout,true)
      flash['notice'] = "TER domain login OPT OUT set"
       redirect_back_or_default(:controller => 'tracker', :action => 'index')
    elsif ldap_authenticated?(login,pass) # || Rails.env.development?
       @user.update_attribute( :ldap_account, login.upcase )
       flash['notice']  = "TER domain login saved"
       redirect_back_or_default(:controller => 'tracker', :action => 'index')
    else
       flash['notice']  = "TER domain authentication failed"
    end
  end
 
  ######################################################################
  #
  # set_role
  #
  # Description:
  # Sets the session role to the role that the user selected.
  #
  # Parameters from params
  # id - identifies the role that the use selected
  #
  ######################################################################
  #
  def set_role
    @logged_in_user.active_role = @logged_in_user.roles.detect { |role| role.id == params[:id].to_i }
    redirect_to(:controller => "tracker")
  end


  ######################################################################
  #
  # create
  #
  # Description:
  # Creates a new user in the database
  #
  # Parameters from params
  # user - information passed back from the view - goes into the
  #        database.
  #
  ######################################################################
  #
  def create

    @user        = User.new(params[:new_user])
    @user.passwd = @user.password

    # If the user left the login, email or design_center_id fields blank, set
    # to the default
    if @user.login == ''
      @user.login = @user.last_name.downcase + @user.first_name[0..0].downcase
    end

    if params[:new_user][:email] == ''
      @user.email = @user.first_name.downcase + "." + @user.last_name.downcase + "@teradyne.com"
    end

    if request.post? and @user.save

      role_count = 0
      params[:role].each { | role_id, value |
        next if value == '0'
        @user.roles << Role.find(role_id)
        role_count += 1
      }

      for user_role in @user.roles
        if user_role.reviewer?
          UserMailer::tracker_invite(@user).deliver
          @user.invited  = 1
          @user.password = @user.passwd
          @user.save
          break
        end
      end

      @user.roles << Role.find_by_name("Basic User") if role_count == 0

      flash[:notice]  = "Account created for #{@user.name}"
      redirect_to(:action => "list",
        :alpha  => @user.last_name[0..0])
      else
        flash[:error] = nil
        #@roles    = Role.find_all_by_active('1', 'display_name ASC')
        @roles    = Role.find_all_active
        @new_user = @user
        
        if User.find_by_login(@user.login)
          flash[:notice] = "#{@user.login} duplicates an existing login - please change"
        else
          flash[:notice]  = "Unable to create an account for #{@user.name}"
        end
        if @user.errors[:email] != [] || @user.errors.size > 0
          flash[:error] = []
          @user.errors.each do |key,value|
            flash[:error] <<  "ERROR: #{key}" + " " + "#{value}"
          end
        end
        render(:action => "signup")     
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
    session[:user_id]     = nil

    redirect_to(:controller => 'tracker')
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
