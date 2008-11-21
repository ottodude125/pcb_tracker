########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: change_items_controller_test.rb
#
# This file contains the functional tests for the change items controller
#
# $Id$
#
########################################################################

require File.dirname(__FILE__) +'/../test_helper'

class ChangeItemsControllerTest < ActionController::TestCase
  
  fixtures :change_items,
           :change_types,
           :roles,
           :users
         
  
  def setup
    @cathy_session     = set_session(users(:cathy_m), 'Admin')
    @change_item_1_1_1 = change_items(:change_item_1_1_1)
    @change_type_1_1   = change_types(:change_type_1_1)
  end
  
  
  ######################################################################
  def test_should_get_index
    get(:index, { :change_type_id => @change_type_1_1.id }, @cathy_session)
    assert_response :success
    assert_not_nil assigns(:change_items)
    assert_equal(@change_type_1_1.change_items.size, assigns(:change_items).size)
    assert_nil(flash[:notice])
  end

  ######################################################################
  def test_should_get_redirect_instead_of_index
    get(:index, { :change_type_id => @change_type_1_1.id }, {})
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_get_new
    get(:new, { :change_type_id => @change_type_1_1.id }, @cathy_session)
    assert_response :success
  end

  ######################################################################
  def test_should_get_redirect_instead_of_new
    get(:new, { :change_type_id => @change_type_1_1.id }, {})
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_create_change_item
    assert_difference('ChangeItem.count') do
      post(:create,
           { :change_item    => { :name => 'test'},
             :change_type_id => @change_type_1_1.id },
           @cathy_session)
    end

    assert_redirected_to change_type_change_items_path(@change_type_1_1)
  end

  ######################################################################
  def test_should_get_redirect_instead_of_creating_change_item
    assert_no_difference('ChangeItem.count') do
      post(:create,
           { :change_item    => { :name => 'test'},
             :change_type_id => @change_type_1_1.id },
           {})
    end
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_render_new_create_change_item_on_error
    assert_no_difference('ChangeItem.count') do
      # The validate presence of name will result in failure
      post(:create,
           { :change_item    => { }, 
             :change_type_id => @change_type_1_1.id },
           @cathy_session)
    end

    assert_template "new"
  end

  ######################################################################
  def test_should_get_edit
    get(:edit, 
        { :id             => @change_item_1_1_1.id, 
          :change_type_id => @change_type_1_1.id },
        @cathy_session)
    assert_response :success
  end

  ######################################################################
  def test_should_get_redirect_instead_of_edit
    get(:edit, 
        { :id             => @change_item_1_1_1.id, 
          :change_type_id => @change_type_1_1.id },
        {})
    assert_redirected_to(:controller => 'user')
    assert_equal('Please log in', flash[:notice])
  end

  ######################################################################
  def test_should_update_change_item
    put(:update,
        { :id             => @change_item_1_1_1.id, 
          :change_item    => { :name => 'test'},
          :change_type_id => @change_type_1_1.id },
        @cathy_session)
    assert_redirected_to change_type_change_items_path(@change_type_1_1)
  end

  ######################################################################
  def test_should_should_get_redirect_instead_of_update_change_item
    put(:update,
        { :id             => @change_item_1_1_1.id, 
          :change_item    => { :name => 'test'},
          :change_type_id => @change_type_1_1.id },
        {})
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_render_edit_change_item_on_error
    put(:update,
        { :id             => @change_item_1_1_1.id, 
          :change_item    => { },
          :change_type_id => @change_type_1_1.id },
        @cathy_session)

    assert_template "edit"    
  end
  
end
