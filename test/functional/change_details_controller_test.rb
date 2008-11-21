########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: change_details_controller_test.rb
#
# This file contains the functional tests for the change details controller
#
# $Id$
#
########################################################################

require File.dirname(__FILE__) +'/../test_helper'

class ChangeDetailsControllerTest < ActionController::TestCase
  
  fixtures :change_details,
           :change_items,
           :change_types,
           :roles,
           :roles_users,
           :users
         
  
  def setup
    @cathy_session          = set_session(users(:cathy_m), 'Admin')
    @change_detail_1_1_3_1  = change_details(:change_detail_1_1_3_1)
    @change_item_1_1_3      = change_items(:change_item_1_1_3)
  end
  
  
  ######################################################################
  def test_should_get_index
    get(:index, { :change_item_id => @change_item_1_1_3.id }, @cathy_session)
    assert_response :success
    assert_not_nil assigns(:change_details)
    assert_equal(@change_item_1_1_3.change_details.size, assigns(:change_details).size)
    assert_nil(flash[:notice])
  end

  ######################################################################
  def test_should_get_redirect_instead_of_index
    get(:index, { :change_item_id => @change_item_1_1_3.id }, {})
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_get_new
   get(:new, { :change_item_id => @change_item_1_1_3.id }, @cathy_session)
    assert_response :success
  end

  ######################################################################
  def test_should_get_redirect_instead_of_new
    get(:new, { :change_item_id => @change_item_1_1_3.id }, {})
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_create_change_detail
    assert_difference('ChangeDetail.count') do
      post(:create, 
           { :change_detail  => { :name => 'test' },
             :change_item_id => @change_item_1_1_3.id },
           @cathy_session)
    end

    assert_redirected_to change_item_change_details_path(@change_item_1_1_3.id)
  end
  
  ######################################################################
  def test_should_get_redirect_instead_of_creating_change_detail
    assert_no_difference('ChangeDetail.count') do
      post(:create,
           { :change_detail  => { :name => 'test' },
             :change_item_id => @change_item_1_1_3.id },
           {})
    end
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_render_new_create_change_detail_on_error
    assert_no_difference('ChangeDetail.count') do
      # The validate presence of name will result in failure
      post(:create, 
           { :change_detail    => { }, 
             :change_item_id => @change_item_1_1_3.id },
           @cathy_session)
    end

    assert_template "new"
  end

  ######################################################################
  def test_should_get_edit
    get(:edit,
        { :id             => @change_detail_1_1_3_1.id,
          :change_item_id => @change_item_1_1_3.id },
        @cathy_session)
    assert_response :success
  end

  ######################################################################
  def test_should_get_redirect_instead_of_edit
    get(:edit, 
        { :id             => @change_detail_1_1_3_1.id,
          :change_item_id => @change_item_1_1_3.id },
        {})
    assert_redirected_to(:controller => 'user')
    assert_equal('Please log in', flash[:notice])
  end

  ######################################################################
  def test_should_update_change_detail
    put(:update, 
        { :id             => @change_detail_1_1_3_1.id,
          :change_detail  => { :name => 'TEST' },
          :change_item_id => @change_item_1_1_3.id },
        @cathy_session)
    assert_redirected_to change_item_change_details_path(@change_item_1_1_3.id)
  end

  ######################################################################
  def test_should_get_redirect_instead_of_update_change_detail
    put(:update, 
        { :id             => @change_detail_1_1_3_1.id,
          :change_detail  => { :name => 'TEST' },
          :change_item_id => @change_item_1_1_3.id },
        {})
    validate_non_admin_redirect
  end
  
  ######################################################################
  def test_should_render_edit_change_detail_on_error
    put(:update,
        { :id             => @change_detail_1_1_3_1.id, 
          :change_detail  => { },
          :change_item_id => @change_item_1_1_3.id },
        @cathy_session)

    assert_template "edit"    
  end

end
