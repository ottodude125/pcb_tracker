########################################################################
#
# Copyright 2008, by Teradyne, Inc., North Reading MA
#
# File: eco_tasks_controller_test.rb
#
# This file contains the functional tests for the eco task type
# controller
#
# $Id$
#
########################################################################
#
require File.expand_path( "../../test_helper", __FILE__ )

class DesignChangesControllerTest < ActionController::TestCase

  fixtures(:design_changes,
           :change_classes,
           :change_details,
           :change_items,
           :change_types,
           :designs,
           :users)
  
  
  def setup
    @patrice_m = users(:patrice_m)
    @patrice_session = set_session(@patrice_m.id, "ECO Admin")

    @existing_design_changes = DesignChange.find(:all)

    @new_params = { :design_change => { :design_id        => 1,  #mx234a
                                        :designer_comment => 'This is a new design change',
                                        :change_class_id  => 1,
                                        :change_type_id   => 11,
                                        :change_item_id   => 113,
                                        :change_detail_id => 1133 } }

    @mx234a_design_change = design_changes(:mx234a_design_change)
    @update_params = { :id            => @mx234a_design_change.id,
                       :design_change => { :id               => @mx234a_design_change.id,
                                           :design_id        => @mx234a_design_change.design_id,
                                           :designer_comment => @mx234a_design_change.designer_comment,
                                           :change_class_id  => @mx234a_design_change.change_class_id,
                                           :change_type_id   => @mx234a_design_change.change_type_id,
                                           :change_item_id   => @mx234a_design_change.change_item_id,
                                           :change_detail_id => @mx234a_design_change.change_detail_id } }

    @change_class_2        = change_classes(:change_class_2)
    @change_type_2_2       = change_types(:change_type_2_2)
    @change_item_2_2_1     = change_items(:change_item_2_2_1)
    @change_detail_2_2_1_2 = change_details(:change_detail_2_2_1_2)
  end


  ##############################################################################
  #                                                                            #
  # create action                                                              #
  #                                                                            #
  ##############################################################################
  #

  def test_should_not_create_no_session
    post(:create, @new_params, {})
    assert_redirected_to(:controller => 'tracker')
    assert_equal(@existing_design_changes.size, DesignChange.count)
  end


  def test_should_not_create_no_comment
    @new_params[:design_change][:designer_comment] = ''
    post(:create, @new_params, scott_designer_session)
    assert_equal(@existing_design_changes.size, DesignChange.count)
    assert_equal('Comment is required', assigns(:design_change).errors[:designer_comment])
  end


  def test_should_not_create_comment_all_whitespace
    @new_params[:design_change][:designer_comment] = '       '
    post(:create, @new_params, scott_designer_session)
    assert_equal(@existing_design_changes.size, DesignChange.count)
    assert_equal('Comment is required', assigns(:design_change).errors[:designer_comment])
  end


  def test_should_not_create_change_class_not_defined

    @new_params[:design_change][:change_class_id] = nil
    post(:create, @new_params, scott_designer_session)
    assert_equal(@existing_design_changes.size, DesignChange.count)
    assert_equal('Change Class selection is required',
                 assigns(:design_change).errors[:change_class_id])

    @new_params[:design_change][:change_class_id] = 0
    post(:create, @new_params, scott_designer_session)
    assert_equal(@existing_design_changes.size, DesignChange.count)
    assert_equal('Change Class selection is required',
                 assigns(:design_change).errors[:change_class_id])

  end


  def test_should_not_create_change_type_not_defined

    @new_params[:design_change][:change_type_id] = nil
    post(:create, @new_params, scott_designer_session)
    assert_equal(@existing_design_changes.size, DesignChange.count)
    assert_equal('Change Type selection is required',
                 assigns(:design_change).errors[:change_type_id])

    @new_params[:design_change][:change_type_id] = 0
    post(:create, @new_params, scott_designer_session)
    assert_equal(@existing_design_changes.size, DesignChange.count)
    assert_equal('Change Type selection is required',
                 assigns(:design_change).errors[:change_type_id])

  end


  def test_should_not_create_change_item_not_defined

    @new_params[:design_change][:change_item_id] = nil
    post(:create, @new_params, scott_designer_session)
    assert_equal(@existing_design_changes.size, DesignChange.count)
    assert_equal('Change Item selection is required',
                 assigns(:design_change).errors[:change_item_id])

    @new_params[:design_change][:change_item_id] = 0
    post(:create, @new_params, scott_designer_session)
    assert_equal(@existing_design_changes.size, DesignChange.count)
    assert_equal('Change Item selection is required',
                 assigns(:design_change).errors[:change_item_id])

  end


  def test_should_not_create_change_detail_not_defined

    @new_params[:design_change][:change_detail_id] = nil
    post(:create, @new_params, scott_designer_session)
    assert_equal(@existing_design_changes.size, DesignChange.count)
    assert_equal('Change Detail selection is required',
                 assigns(:design_change).errors[:change_detail_id])

    @new_params[:design_change][:change_detail_id] = 0
    post(:create, @new_params, scott_designer_session)
    assert_equal(@existing_design_changes.size, DesignChange.count)
    assert_equal('Change Detail selection is required',
                 assigns(:design_change).errors[:change_detail_id])

  end


  def test_should_create
    post(:create, @new_params, scott_designer_session)
    assert_equal(@existing_design_changes.size+1, DesignChange.count)
  end


  ##############################################################################
  #                                                                            #
  # display_design_change_form action                                          #
  #                                                                            #
  ##############################################################################
  #
  
  def test_change_class_id_set_designer
    get(:display_design_change_form, 
        { :change_class_id => @change_class_2.id },
        scott_designer_session)
    assert_response :success
    assert_equal(@change_class_2.id, assigns(:design_change).change_class_id)
  end


  def test_change_type_id_set
    get(:display_design_change_form,
        { :change_type_id => @change_type_2_2.id },
        scott_designer_session)
    assert_response :success
    assert_equal(@change_type_2_2.id, assigns(:design_change).change_type_id)
  end


  def test_change_item_id_set
    get(:display_design_change_form,
        { :change_item_id => @change_item_2_2_1.id },
        scott_designer_session)
    assert_response :success
    assert_equal(@change_item_2_2_1.id, assigns(:design_change).change_item_id)
  end


  def test_change_detail_id_set
    get(:display_design_change_form,
        { :change_detail_id => @change_detail_2_2_1_2.id },
        scott_designer_session)
    assert_response :success
    assert_equal(@change_detail_2_2_1_2.id, assigns(:design_change).change_detail_id)
  end


  def test_should_not_get_form
    get(:display_design_change_form, { :change_class_id => change_classes(:change_class_2).id }, {})
    assert_redirected_to(:controller => 'tracker')
  end


  ##############################################################################
  #                                                                            #
  # edit action                                                                #
  #                                                                            #
  ##############################################################################
  #

  def test_should_not_get_edit_not_logged_in
    get(:edit, { :id => @mx234a_design_change.id }, {})
    assert_redirected_to(:controller => 'user', :action => 'login')
  end


  def test_should_get_edit_logged_in
    get(:edit, { :id => @mx234a_design_change.id }, scott_designer_session)
    assert_response :success
    assert_equal(@mx234a_design_change, assigns(:design_change))
  end


  ##############################################################################
  #                                                                            #
  # index action                                                               #
  #                                                                            #
  ##############################################################################
  #

  def test_should_get_index_not_signed_in
    get(:index, { :id => designs(:mx234a).id }, {})
    assert_response :success
    assert_not_nil assigns(:design)
  end


  def test_should_get_index
    get(:index, { :id => designs(:mx234a).id }, @patrice_session)
    assert_response :success
    assert_not_nil assigns(:design)
  end


  ##############################################################################
  #                                                                            #
  # new action                                                                 #
  #                                                                            #
  ##############################################################################
  #

  def test_should_not_get_new
    get(:new, { :design_id => designs(:mx234a).id }, {})
    assert_response :redirect
    assert(flash['notice'].include?('unavailable unless logged in.'))
    assert_nil assigns(:design)
    assert_nil assigns(:design_change)
    assert_nil assigns(:change_classes)
  end


  def test_should_get_new
    get(:new, { :design_id => designs(:mx234a).id }, @patrice_session)
    assert_response :success
    assert_not_nil assigns(:design)
    assert_not_nil assigns(:design_change)
    assert_not_nil assigns(:change_classes)
  end


  ##############################################################################
  #                                                                            #
  # pending_list action                                                        #
  #                                                                            #
  ##############################################################################
  #

  def test_should_not_get_pending_list_non_manager_session
    get(:pending_list, { }, scott_designer_session)
    assert_redirected_to(:controller => 'tracker')
  end


  def test_should_not_get_pending_list_not_logged_in
    get(:pending_list, { }, {})
    assert_redirected_to(:controller => 'tracker')
  end


  def test_should_get_pending_list_manager_session
    get(:pending_list, { }, jim_manager_session)
    assert_response :success
  end


  ##############################################################################
  #                                                                            #
  # show action                                                                #
  #                                                                            #
  ##############################################################################
  #


  def test_should_allow_access_to_show_not_logged_in
    get(:show, { :id => @mx234a_design_change.id }, {})
    assert_response :success
    assert_nil(assigns(:logged_in_user))
  end


  def test_should_allow_access_to_show_non_manager_session
    get(:show, { :id => @mx234a_design_change.id }, scott_designer_session)
    assert_response :success
    assert_equal(users(:scott_g), assigns(:logged_in_user))
  end


  def test_should_allow_access_to_show_manager_session
    get(:show, { :id => @mx234a_design_change.id }, jim_manager_session)
    assert_response :success
    assert_equal(users(:jim_l), assigns(:logged_in_user))
  end


  ##############################################################################
  #                                                                            #
  # update action                                                              #
  #                                                                            #
  ##############################################################################
  #

  def test_should_not_update_no_session
    post(:update, @update_params, {})
    assert_redirected_to(:controller => 'tracker')
  end


  def test_should_not_update_no_comment
    @update_params[:design_change][:designer_comment] = ''
    post(:update, @update_params, scott_designer_session)
    assert_equal('Comment is required', assigns(:design_change).errors[:designer_comment])
  end


  def test_should_not_update_comment_all_whitespace
    @update_params[:design_change][:designer_comment] = '       '
    post(:update, @update_params, scott_designer_session)
    assert_equal('Comment is required', assigns(:design_change).errors[:designer_comment])
  end


  def test_should_not_update_change_class_not_defined

    @update_params[:design_change][:change_class_id] = nil
    post(:update, @update_params, scott_designer_session)
    assert_equal('Change Class selection is required',
                 assigns(:design_change).errors[:change_class_id])

    @update_params[:design_change][:change_class_id] = 0
    post(:update, @update_params, scott_designer_session)
    assert_equal('Change Class selection is required',
                 assigns(:design_change).errors[:change_class_id])

  end


  def test_should_not_update_change_type_not_defined

    @update_params[:design_change][:change_type_id] = nil
    post(:update, @update_params, scott_designer_session)
    assert_equal('Change Type selection is required',
                 assigns(:design_change).errors[:change_type_id])

    @update_params[:design_change][:change_type_id] = 0
    post(:update, @update_params, scott_designer_session)
    assert_equal('Change Type selection is required',
                 assigns(:design_change).errors[:change_type_id])

  end


  def test_should_not_update_change_item_not_defined

    @update_params[:design_change][:change_item_id] = nil
    post(:update, @update_params, scott_designer_session)
    assert_equal('Change Item selection is required',
                 assigns(:design_change).errors[:change_item_id])

    @update_params[:design_change][:change_item_id] = 0
    post(:update, @update_params, scott_designer_session)
    assert_equal('Change Item selection is required',
                 assigns(:design_change).errors[:change_item_id])

  end


  def test_should_not_update_change_detail_not_defined

    @update_params[:design_change][:change_detail_id] = nil
    post(:update, @update_params, scott_designer_session)
    assert_equal('Change Detail selection is required',
                 assigns(:design_change).errors[:change_detail_id])

    @update_params[:design_change][:change_detail_id] = 0
    post(:update, @update_params, scott_designer_session)
    assert_equal('Change Detail selection is required',
                 assigns(:design_change).errors[:change_detail_id])
               
  end


  def test_should_update_change_detail_id
    @update_params[:design_change][:change_detail_id] = 1132
    post(:update, @update_params, scott_designer_session)

    assert_equal(1133, @mx234a_design_change.change_detail_id)
    @mx234a_design_change.reload
    assert_equal(1132, @mx234a_design_change.change_detail_id)
  end

  
  def test_should_update_approval

    @update_params[:design_change][:approved] = '1'
    post(:update, @update_params, scott_designer_session)

    assert(!@mx234a_design_change.approved)
    @mx234a_design_change.reload
    assert( @mx234a_design_change.approved)

    @update_params[:design_change][:approved] = '0'
    post(:update, @update_params, scott_designer_session)

    @mx234a_design_change.reload
    assert(!@mx234a_design_change.approved)

  end

end