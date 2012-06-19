########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: change_class_controller_test.rb
#
# This file contains the functional tests for the change class controller
#
# $Id$
#
########################################################################

require File.dirname(__FILE__) +'/../test_helper'

class ChangeClassesControllerTest < ActionController::TestCase
  
  fixtures :change_classes,
           :roles,
           :roles_users,
           :users
         
  
  def setup
    @cathy_session = set_session(users(:cathy_m), 'Admin')
  end
  
  
  ######################################################################
  def test_should_get_index
    get(:index, {}, @cathy_session)
    assert_response :success
    assert_not_nil assigns(:change_classes)
    assert_equal(ChangeClass.count, assigns(:change_classes).size)
    assert_nil(flash[:notice])
  end

  ######################################################################
  def test_should_get_redirect_instead_of_index
    get(:index, {}, {})
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_get_new
    get(:new, {}, @cathy_session)
    assert_response :success
  end

  ######################################################################
  def test_should_get_redirect_instead_of_new
    get(:new, {}, {})
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_create_change_class
    assert_difference('ChangeClass.count') do
      post(:create, { :change_class => { :name => 'test' } }, @cathy_session)
    end

    assert_redirected_to change_classes_path()
  end

  ######################################################################
  def test_should_get_redirect_instead_of_creating_change_class
    assert_no_difference('ChangeClass.count') do
      post(:create, { :change_class => { } }, {})
    end
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_render_new_create_change_class_on_error
    assert_no_difference('ChangeClass.count') do
      # The validate presence of name will result in failuer
      post(:create, {:change_class => {} }, @cathy_session)
    end

    assert_template "new"
  end

  ######################################################################
  def test_should_get_edit
    get(:edit, { :id => change_classes(:change_class_1).id }, @cathy_session)
    assert_response :success
  end

  ######################################################################
  def test_should_get_redirect_instead_of_edit
    get(:edit, { :id => change_classes(:change_class_1).id }, {})
    assert_redirected_to(:controller => 'user')
    assert_equal('Please log in', flash[:notice])
  end

  ######################################################################
  def test_should_update_change_class
    put(:update,
        { :id           => change_classes(:change_class_1).id, 
          :change_class => { :name => 'test'} },
        @cathy_session)
    assert_redirected_to change_classes_path()
  end
  
  ######################################################################
  def test_should_should_get_redirect_instead_of_update_change_class
    put(:update, 
        { :id           => change_classes(:change_class_1).id, 
          :change_class => { :name => 'test' } },
        {})
    validate_non_admin_redirect
  end
  
  ######################################################################
  def test_should_render_edit_change_class_on_error
    put(:update, 
        { :id           => change_classes(:change_class_1).id, 
          :change_class => { } },
        @cathy_session)

    assert_template "edit"    
  end
  
end
