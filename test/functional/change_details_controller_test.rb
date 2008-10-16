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
           :users
         
  
  def setup
    @cathy_m                = users(:cathy_m)
    @change_detail_1_1_3_1  = change_details(:change_detail_1_1_3_1)
    @change_item_1_1_3      = change_items(:change_item_1_1_3)
  end
  
  
  ######################################################################
  def test_should_get_index
    set_user(@cathy_m.id, 'Admin')
    get(:index, { :change_item_id => @change_item_1_1_3.id })
    assert_response :success
    assert_not_nil assigns(:change_details)
    assert_equal(@change_item_1_1_3.change_details.size, assigns(:change_details).size)
    assert_nil(flash[:notice])
  end

  ######################################################################
  def test_should_get_redirect_instead_of_index
    get(:index, { :change_item_id => @change_item_1_1_3.id })
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_get_new
   set_user(@cathy_m.id, 'Admin')
   get(:new, { :change_item_id => @change_item_1_1_3.id })
    assert_response :success
  end

  ######################################################################
  def test_should_get_redirect_instead_of_new
    get(:new, { :change_item_id => @change_item_1_1_3.id })
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_create_change_detail
    set_user(@cathy_m.id, 'Admin')
    assert_difference('ChangeDetail.count') do
      post(:create, { :change_detail  => { :name => 'test' },
                      :change_item_id => @change_item_1_1_3.id })
    end

    assert_redirected_to change_item_change_details_path(@change_item_1_1_3.id)
  end
  
  ######################################################################
  def test_should_get_redirect_instead_of_creating_change_detail
    assert_no_difference('ChangeDetail.count') do
      post(:create, { :change_detail  => { :name => 'test' },
                      :change_item_id => @change_item_1_1_3.id })
    end
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_render_new_create_change_detail_on_error
    set_user(@cathy_m.id, 'Admin')
    assert_no_difference('ChangeDetail.count') do
      # The validate presence of name will result in failure
      post(:create, { :change_detail    => { }, 
                      :change_item_id => @change_item_1_1_3.id })
    end

    assert_template "new"
  end

  ######################################################################
  def test_should_get_edit
    set_user(@cathy_m.id, 'Admin')
    get(:edit, { :id             => @change_detail_1_1_3_1.id,
                 :change_item_id => @change_item_1_1_3.id })
    assert_response :success
  end

  ######################################################################
  def test_should_get_redirect_instead_of_edit
    get(:edit, { :id             => @change_detail_1_1_3_1.id,
                 :change_item_id => @change_item_1_1_3.id })
    assert_redirected_to(:controller => 'user')
    assert_equal('Please log in', flash[:notice])
  end

  ######################################################################
  def test_should_update_change_detail
    set_user(@cathy_m.id, 'Admin')
    put(:update, { :id             => @change_detail_1_1_3_1.id,
                   :change_detail  => { :name => 'TEST' },
                   :change_item_id => @change_item_1_1_3.id })
    assert_redirected_to change_item_change_details_path(@change_item_1_1_3.id)
  end

  ######################################################################
  def test_should_get_redirect_instead_of_update_change_detail
    put(:update, { :id             => @change_detail_1_1_3_1.id,
                   :change_detail  => { :name => 'TEST' },
                   :change_item_id => @change_item_1_1_3.id })
    validate_non_admin_redirect
  end
  
  ######################################################################
  def test_should_render_edit_change_detail_on_error
    set_user(users(:cathy_m).id, 'Admin')
    put(:update, { :id             => @change_detail_1_1_3_1.id, 
                   :change_detail  => { },
                   :change_item_id => @change_item_1_1_3.id })

    assert_template "edit"    
  end

end
