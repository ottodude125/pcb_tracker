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


  ## Verify that the tracker will not allow a user that is not logged in to 
  ## edit a user record.
  def test_edit_without_user

    post(:edit, :id => users(:cathy_m).id)
    assert_redirected_to :action => "login"
    assert_equal("Please log in", flash[:notice])
  end

  ## Verify that the tracker limits the user record edit function to an 
  ## admin account
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


  def test_admin_user_edit

    post(:login,
         :user_login => "cathy_m", 
         :user_password => "test")

    assert_equal('Login successful', flash['notice'])
    
    post(:edit, :id => users(:cathy_m).id)
    assert_template "user/edit"

  end
  
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

 
  def test_signup

    @request.session[:return_to] = "http://www.yahoo.com"

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
    
  end

  def test_bad_signup

    print ("user::bad_signup - test is incomplete")
    
    @request.session[:return_to] = "/bogus/location"

    return
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
    post(:create,
         :user => {
           :first_name => "Abe",
           :last_name  => "Lincoln",
           :login      => "",
           :email      => "",
           :active     => "1",
           :password   => "newpassword", 
           :password_confirmation => "wrongpassword" },
         :role => {})
           
    assert_redirected_to :action => "index"
    assert_equal("The password and the confirmation do not match.", 
		             flash['notice'])
    
    post :signup, 
         :user => { 
            :login                 => "yo",
            :password              => "newpassword", 
            :password_confirmation => "newpassword" }
    assert_invalid_column_on_record "user", :login
    assert_success

    post :signup, :user => { :login => "yo", :password => "newpassword", :password_confirmation => "wrong" }
    assert_invalid_column_on_record "user", [:login, :password]
    assert_success
  end

  def test_invalid_login

    post :login, :user_login => "bob", :user_password => "not_correct"
     
    assert_session_has_no :user
    
    assert_template_has "login"
  end
  
  def test_login_logoff

    post :login, :user_login => "bob", :user_password => "test"
    assert_session_has :user

    get :logout
    assert_session_has_no :user

  end
  
end
