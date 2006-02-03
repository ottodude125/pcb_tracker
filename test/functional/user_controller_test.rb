########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: user_controller_test.rb
#
# This file contains the functional tests for the user controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'user_controller'

# Set salt to 'change-me' because thats what the fixtures assume. 
User.salt = 'change-me'

# Raise errors beyond the default web-based presentation
class UserController; def rescue_action(e) raise e end; end

class UserControllerTest < Test::Unit::TestCase
  
  fixtures :users
  fixtures :roles
  fixtures :roles_users
  
  def setup
    @controller = UserController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "localhost"
  end


  def test_1_id
    print ("\n*** User Controller Test\n")
    print ("*** $Id$\n")
  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # Verify that the tracker will not allow a user that is not logged in to 
  # edit a user record.
  #
  #
  ######################################################################
  #
  def test_edit_without_user

    post(:edit, :id => users(:cathy_m).id)
    assert_redirected_to :action => "login"
    assert_equal("Please log in", flash[:notice])
  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # Verify that the tracker limits the user record edit function to an 
  # admin account
  #
  #
  ######################################################################
  #
  def test_auth_to_edit

    @request.session[:return_to] = "/bogus/location"
    cathy_m = users(:cathy_m)

    # Log in as a designer and try to edit a user record.
    post(:login,
         :user_login => "richm", 
         :user_password => "test")

    assert_equal('Login successful',
                 flash['notice'])
    
    post(:edit, :id => cathy_m.id)
    assert_redirected_to :action => "index", :controller => "tracker"
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Log in as a manager and try to edit a user record.
    post(:login,
         :user_login => "jim_l", 
         :user_password => "test")

    assert_equal('Login successful', flash['notice'])
    
    post(:edit, :id => cathy_m.id)
    assert_redirected_to :action => "index", :controller => "tracker"
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

  end


  ######################################################################
  #
  # test_admin_user_edit
  #
  # Description:
  # Verify that the admin an edit user accounts.
  #
  #
  ######################################################################
  #
  def test_admin_user_edit

    post(:login,
         :user_login => "cathy_m", 
         :user_password => "test")

    assert_equal('Login successful', flash['notice'])
    
    post(:edit, :id => users(:cathy_m).id)
    assert_template "user/edit"

  end

  
  ######################################################################
  #
  # test_auth_bob
  #
  # Description:
  # Verify that bob can login.
  #
  #
  ######################################################################
  #
  def test_auth_bob

    @request.session[:return_to] = "/bogus/location"

    post(:login,
	       :user_login => "bob", 
         :user_password => "test")

    assert_session_has :user
    assert_equal "bob", @response.session[:user].login

    assert_session_has :active_role
    assert_equal 'Admin', @response.session[:active_role]

    assert_session_has :roles
    assert_redirect_url "http://localhost/bogus/location"
  end

 
  ######################################################################
  #
  # test_signup
  #
  # Description:
  # Verify that the admin an edit user accounts.
  #
  #
  ######################################################################
  #
  def test_signup

    @request.session[:return_to] = "http://www.yahoo.com"

    # Make sure that a non-admin can not create a new user.
    post(:create,
         :user => {
           :login                 => "newbob", 
           :password              => "newpassword", 
           :password_confirmation => "newpassword",
           :first_name            => "Bob",
           :last_name             => "Squarepants",
           :email                 => "Bob_Squarepants@notes.teradyne.com",
           :active                => "1"},
         :role => {"1"=>"1", "2"=>"0", "4"=>"1"})


    assert_equal("Administrators only!  Check your role.", flash['notice'])
    assert_redirect_url "http://localhost/tracker"

    # Make sure that an admin can create a new user.
    set_admin
    post(:create,
         :user => {
           :login                 => "newbob", 
           :password              => "newpassword", 
           :password_confirmation => "newpassword",
           :first_name            => "Bob",
           :last_name             => "Squarepants",
           :email                 => "Bob_Squarepants@notes.teradyne.com",
           :active                => "1"},
         :role => {"1"=>"1", "2"=>"0", "4"=>"1"})


    assert_equal("Account created for Bob Squarepants", flash['notice'])
    assert_redirect_url "http://www.yahoo.com"

    new_user = User.find_by_last_name "Squarepants"
    assert_equal('newbob', new_user.login)

    # Make sure that the defaults are loaded properly.
    post(:create,
         :user => {
           :login                 => "", 
           :password              => "newpassword", 
           :password_confirmation => "newpassword",
           :first_name            => "Roberto",
           :last_name             => "Clemente",
           :email                 => "",
           :active                => "1"},
         :role => {"1"=>"1", "2"=>"0", "4"=>"1"})


    assert_equal("Account created for Roberto Clemente", flash['notice'])
    assert_redirected_to(:controller => 'user', :action => 'list')
    
    new_user = User.find_by_last_name "Clemente"
    assert_equal('rclemente',                           new_user.login)
    assert_equal('roberto_clemente@notes.teradyne.com', new_user.email)

  end


  ######################################################################
  #
  # test_bad_signup
  #
  # Description:
  # Verify that the admin an edit user accounts.
  #
  #
  ######################################################################
  #
  def test_bad_signup

    post(:create,
         :user => {
           :first_name => "Abe",
           :last_name  => "Lincoln",
           :login      => "",
           :email      => "",
           :active     => "1",
           :password   => "newpassword", 
           :password_confirmation => "wrongpassword" })
           
    assert_redirected_to :action => "index"
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    
    set_admin
    post :signup, 
         :user => { 
            :login                 => "yo",
            :password              => "newpassword", 
            :password_confirmation => "newpassword" }
    assert_success

  end

  ######################################################################
  #
  # test_invalid_login
  #
  # Description:
  # Verify the actions for an invalid login.
  #
  #
  ######################################################################
  #
  def test_invalid_login

    post :login, :user_login => "bob", :user_password => "not_correct"
     
    assert_session_has_no :user
    assert_template_has "login"
  end
  

  ######################################################################
  #
  # test_invalid_login
  #
  # Description:
  # Verify the behavior when a users logs in and then logs out.
  #
  #
  ######################################################################
  #
  def test_login_logoff

    post :login, :user_login => "bob", :user_password => "test"
    assert_session_has :user

    get :logout
    assert_session_has_no :user

  end


  ######################################################################
  #
  # test_invalid_login
  #
  # Description:
  # Verify the list of users is provided when the user list screen is
  # displayed.
  #
  #
  ######################################################################
  #
  def test_list

    set_admin
    post :list

    assert_response 200
    assert_equal(15, assigns(:users).size)
    
  end


  ######################################################################
  #
  # test_change_password
  #
  # Description:
  # Verify the user record is provided when the 'change password' link
  # is clicked.
  #
  #
  ######################################################################
  #
  def test_change_password

    post(:change_password, :id => users(:rich_m).id)
    assert_redirected_to :action => "index"
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    set_admin
    post(:change_password, :id => users(:rich_m).id)

    assert_response 200
    assert_session_has :user
    assert_equal(users(:rich_m).last_name, assigns(:user).last_name)
    assert_template "change_password"
    
  end


  ######################################################################
  #
  # test_reset_password
  #
  # Description:
  # Verify the behavior of the reset password method
  #
  #
  ######################################################################
  #
  def test_reset_password

    post(:reset_password, 
         :user                      => {:id => users(:rich_m).id},
         :new_password              => 'Go_Red_Sox',
         :new_password_confirmation => 'Go_Red_Sox')
    assert_redirected_to :action => "index"
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    set_admin
    post(:reset_password, 
         :user                      => {:id => users(:rich_m).id},
         :new_password              => 'Go_Red_Sox',
         :new_password_confirmation => 'Go_Red_Sox')

    assert_redirected_to :action => :list
    assert_equal('The password for Rich Miller was updated',
                 flash['notice'])

        post(:reset_password, 
         :user                      => {:id => users(:rich_m).id},
         :new_password              => 'Go_Red_Sox',
         :new_password_confirmation => 'Go_Yankees')

    assert_redirected_to :action => :change_password, :id => users(:rich_m).id
    assert_equal('No Update - the new password and the confirmation do not match',
                 flash['notice'])

  end

  
  ######################################################################
  #
  # test_update
  #
  # Description:
  # Verify the behavior of the update method.
  #
  #
  ######################################################################
  #
  def test_update

    post(:update, 
         :user                      => {:id => users(:rich_m).id})
    assert_redirected_to :action => "index"
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    set_admin
    rich_roles = users(:rich_m).roles
    assert_equal(2, rich_roles.size)
    
    post(:update, 
         :user => {:id         => users(:rich_m).id,
                   :first_name => 'Richard',
                   :last_name  => 'Miller',
                   :email      => ''},
         :role => {'1' => '1',
                   '2' => '1',
                   '6' => '0',
                   '9' => '1',
                   '8' => '0'})

    assert_redirected_to(:controller => 'user',
                         :action     => 'edit',
                         :id         => users(:rich_m).id)
    assert_equal('The user information for Richard Miller was updated',
                 flash['notice'])
    rich_roles = User.find(users(:rich_m).id).roles
    assert_equal(3, rich_roles.size)

  end

  
  ######################################################################
  #
  # test_set_role
  #
  # Description:
  # Verify the session information is updated with the selected role.
  #
  #
  ######################################################################
  #
  def test_set_role

    set_admin
    post(:set_role, :role => {'id' => '14'})

    assert_equal('PCB Input Gate', session[:active_role])
    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')

  end


end
