########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: change_types_controller_test.rb
#
# This file contains the functional tests for the change types controller
#
# $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ )

class ChangeTypesControllerTest < ActionController::TestCase
  
  fixtures :change_classes,
           :change_types,
           :roles,
           :users
         
  
  def setup
    @cathy_session   = set_session(users(:cathy_m), 'Admin')
    @change_class_1  = change_classes(:change_class_1)
    @change_type_1_1 = change_types(:change_type_1_1)
  end
  
  
  ######################################################################
  def test_should_get_index
    get(:index, { :change_class_id => @change_class_1.id }, @cathy_session)
    assert_response :success
    assert_not_nil assigns(:change_types)
    assert_equal(@change_class_1.change_types.size, assigns(:change_types).size)
    assert_nil(flash[:notice])
  end

  ######################################################################
  def test_should_get_redirect_instead_of_index
    get(:index, { :change_class_id => @change_class_1.id }, {})
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_get_new
    get(:new, { :change_class_id => @change_class_1.id }, @cathy_session)
    assert_response :success
  end

  ######################################################################
  def test_should_get_redirect_instead_of_new
    get(:new, { :change_class_id => @change_class_1.id }, {})
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_create_change_type
    assert_difference('ChangeType.count') do
      post(:create, 
           { :change_type     => { :name => 'test' },
             :change_class_id => @change_class_1.id },
           @cathy_session)
    end

    assert_redirected_to change_class_change_types_path(@change_class_1)
  end

  ######################################################################
  def test_should_get_redirect_instead_of_creating_change_class
    assert_no_difference('ChangeType.count') do
      post(:create, 
           { :change_type     => { :name => 'test' },
             :change_class_id => @change_class_1.id },
           {})
    end
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_render_new_create_change_type_on_error
    assert_no_difference('ChangeType.count') do
      # The validate presence of name will result in failure
      post(:create,
           { :change_type    => { }, 
             :change_class_id => @change_class_1.id },
           @cathy_session)
    end

    assert_template "new"
  end

  ######################################################################
  def test_should_get_edit
    get(:edit, 
        { :id              => @change_type_1_1.id, 
          :change_class_id => @change_class_1.id },
        @cathy_session)
    assert_response :success
  end

  ######################################################################
  def test_should_get_redirect_instead_of_edit
    get(:edit, 
        { :id              => @change_type_1_1.id, 
          :change_class_id => @change_class_1.id },
        {})
    assert_redirected_to(:controller => 'user', :action => 'login')
    assert_equal('Please log in', flash[:notice])
  end

  ######################################################################
  def test_should_update_change_type
    put(:update,
        { :id              => @change_type_1_1.id, 
          :change_type     => { :name => 'test' },
          :change_class_id => @change_class_1.id },
        @cathy_session)
   assert_redirected_to change_class_change_types_path(@change_class_1)
  end
  
  ######################################################################
  def test_should_should_get_redirect_instead_of_update_change_type
    put(:update, 
        { :id              => @change_type_1_1.id, 
          :change_type     => { :name => 'test' },
          :change_class_id => @change_class_1.id },
        {})
    validate_non_admin_redirect
  end

  ######################################################################
  def test_should_render_edit_change_type_on_error
    put(:update, 
        { :id              => @change_type_1_1.id, 
          :change_type     => { },
          :change_class_id => @change_class_1.id },
        @cathy_session)

    assert_template "edit"    
  end

end
