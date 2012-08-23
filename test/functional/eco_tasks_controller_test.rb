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

class EcoTasksControllerTest < ActionController::TestCase

  fixtures(:eco_tasks,
           :eco_types,
           :roles,
           :roles_users,
           :users)
  
  
  def setup
    @patrice_m = users(:patrice_m)
    @patrice_session = set_session(@patrice_m.id, "ECO Admin")
  end
  
  
  def test_should_get_index_not_signed_in
    get(:index, {}, {})
    assert_response :success
    assert_not_nil assigns(:eco_tasks)
  end

  def test_should_get_index
    get(:index, {}, @patrice_session)
    assert_response :success
    assert_not_nil assigns(:eco_tasks)
  end

  def test_should_not_get_new
    get(:new, {}, {})
    assert_response :redirect
    assert(flash['notice'].include?('unavailable unless logged in.'))
    assert_nil assigns(:eco_task)
    assert_nil assigns(:eco_document)
    assert_nil assigns(:eco_comment)
    assert_nil assigns(:eco_types)
  end

  def test_should_get_new
    get(:new, {}, @patrice_session)
    assert_response :success
    assert_not_nil assigns(:eco_task)
    assert_not_nil assigns(:eco_document)
    assert_not_nil assigns(:eco_comment)
    assert_not_nil assigns(:eco_types)
  end

  def test_should_not_create_eco_task
    assert_no_difference('EcoTask.count') do
      post :create, :eco_task => { }
    end
  end
  
  def test_should_create_eco_task
    assert_difference('EcoTask.count') do
      post(:create,
           { :eco_task     => { :number           => 'p21',
                                :pcb_revision     => 'B',
                                :pcba_part_number => '500-010-00',
                                :eco_type_ids     => ["1", "2"] },
             :eco_document => { :document => '' },
             :eco_comment  => { :comment => ''} },
         @patrice_session)
    end

    assert_redirected_to eco_tasks_url
  end

  
  def test_should_show_eco_task_not_signed_in
    get :show, { :id => eco_tasks(:task_one).id }, {}
    assert_response :redirect
  end


  def test_should_show_eco_task
    get :show, { :id => eco_tasks(:task_one).id }, @patrice_session
    assert_response :redirect
  end


  def test_should_get_edit
    @patrice_session[:return_to] = 'wrewqe'
    get :edit, { :id => eco_tasks(:task_one).id }, @patrice_session
    assert_equal(eco_tasks(:task_one).id, assigns(:eco_task).id)
    assert_response :success
  end

  def test_should_update_eco_task
    eco_task = eco_tasks(:task_one)
    comment_count = eco_task.eco_comments.size
    put(:update, 
        { :id       => eco_task.id, 
          :eco_task => { :number           => 'p2108',
                         :pcb_revision     => 'C',
                         :pcba_part_number => '500-010-00',
                         :eco_type_ids     => ["1", "2"] },
                         :eco_document     => { :document => '' },
                         :eco_comment      => { :comment => 'New Comment'} },
        @patrice_session)
    assert_redirected_to eco_tasks_url
    eco_task.reload
    assert_equal(comment_count+1, eco_task.eco_comments.size)
  end

  def test_eco_task_updates

    baseline_eco_task = EcoTask.find(eco_tasks(:task_one).id)
    comment_count = baseline_eco_task.eco_comments.size
    eco_type_list = [eco_types(:schematic), eco_types(:assembly_drawing)]

    assert_equal([], baseline_eco_task.eco_types)

    # Change the eco_types
    put(:update, 
        { :id       => baseline_eco_task.id, 
          :eco_task => { :number           => 'P2000',
                         :pcb_revision     => 'A',
                         :pcba_part_number => "600-500-00",
                         :eco_type_ids     => ["1", "2"],
                         :completed        => '1',
                         :closed           => '1',
                         :document_link    => nil } },
        @patrice_session)
    assert_redirected_to eco_tasks_url
    eco_task = EcoTask.find(baseline_eco_task.id)

    assert_equal(baseline_eco_task.number,           eco_task.number)
    assert_equal(baseline_eco_task.pcb_revision,     eco_task.pcb_revision)
    assert_equal(baseline_eco_task.pcba_part_number, eco_task.pcba_part_number)
    assert_equal(baseline_eco_task.completed?,       eco_task.completed?)
    assert_equal(baseline_eco_task.closed?,          eco_task.closed?)
    assert_equal(baseline_eco_task.document_link,    eco_task.document_link)
    assert_equal(eco_type_list,                      eco_task.eco_types)
    
    baseline_eco_task.reload
    assert_equal(eco_type_list, baseline_eco_task.eco_types)    
    
    # Change the eco number
    put(:update, 
        { :id       => baseline_eco_task.id, 
          :eco_task => { :number           => 'P4000',
                         :pcb_revision     => 'A',
                         :pcba_part_number => "600-500-00",
                         :eco_type_ids     => ["1", "2"],
                         :completed        => '1',
                         :closed           => '1',
                         :document_link    => nil } },
        @patrice_session)
    assert_redirected_to eco_tasks_url
    eco_task = EcoTask.find(baseline_eco_task.id)

    assert_equal('P4000',                            eco_task.number)
    assert_equal(baseline_eco_task.pcb_revision,     eco_task.pcb_revision)
    assert_equal(baseline_eco_task.pcba_part_number, eco_task.pcba_part_number)
    assert_equal(baseline_eco_task.completed?,       eco_task.completed?)
    assert_equal(baseline_eco_task.closed?,          eco_task.closed?)
    assert_equal(baseline_eco_task.document_link,    eco_task.document_link)
    assert_equal(eco_type_list,                      baseline_eco_task.eco_types)
    
    baseline_eco_task.reload
    
    # Change the pcb part number
    put(:update, 
        { :id       => baseline_eco_task.id, 
          :eco_task => { :number           => 'P4000',
                         :pcb_revision     => 'C',
                         :pcba_part_number => "600-500-00",
                         :eco_type_ids     => ["1", "2"],
                         :completed        => '1',
                         :closed           => '1',
                         :document_link    => nil } },
        @patrice_session)
    assert_redirected_to eco_tasks_url
    eco_task = EcoTask.find(baseline_eco_task.id)

    assert_equal(baseline_eco_task.number,           eco_task.number)
    assert_equal('C',                                eco_task.pcb_revision)
    assert_equal(baseline_eco_task.pcba_part_number, eco_task.pcba_part_number)
    assert_equal(baseline_eco_task.completed?,       eco_task.completed?)
    assert_equal(baseline_eco_task.closed?,          eco_task.closed?)
    assert_equal(baseline_eco_task.document_link,    eco_task.document_link)
    assert_equal(eco_type_list,                      baseline_eco_task.eco_types)
    
    baseline_eco_task.reload
    
    # Change the pcba part number
    put(:update, 
        { :id       => baseline_eco_task.id, 
          :eco_task => { :number           => 'P4000',
                         :pcb_revision     => 'C',
                         :pcba_part_number => "600-555-00",
                         :eco_type_ids     => ["1", "2"],
                         :completed        => '1',
                         :closed           => '1',
                         :document_link    => nil } },
        @patrice_session)
    assert_redirected_to eco_tasks_url
    eco_task = EcoTask.find(baseline_eco_task.id)

    assert_equal(baseline_eco_task.number,         eco_task.number)
    assert_equal(baseline_eco_task.pcb_revision,   eco_task.pcb_revision)
    assert_equal("600-555-00",                     eco_task.pcba_part_number)
    assert_equal(baseline_eco_task.completed?,     eco_task.completed?)
    assert_equal(baseline_eco_task.closed?,        eco_task.closed?)
    assert_equal(baseline_eco_task.document_link,  eco_task.document_link)
    assert_equal(eco_type_list,                    baseline_eco_task.eco_types)
    
    baseline_eco_task.reload
    
    # Change the closed flag
    put(:update, 
        { :id       => baseline_eco_task.id, 
          :eco_task => { :number           => 'P4000',
                         :pcb_revision     => 'C',
                         :pcba_part_number => "600-555-00",
                         :eco_type_ids     => ["1", "2"],
                         :completed        => '1',
                         :closed           => '0',
                         :document_link    => nil } },
        @patrice_session)
    assert_redirected_to eco_tasks_url
    eco_task = EcoTask.find(baseline_eco_task.id)

    assert_equal(baseline_eco_task.number,           eco_task.number)
    assert_equal(baseline_eco_task.pcb_revision,     eco_task.pcb_revision)
    assert_equal(baseline_eco_task.pcba_part_number, eco_task.pcba_part_number)
    assert_equal(baseline_eco_task.completed?,       eco_task.completed?)
    assert_equal(false,                              eco_task.closed?)
    assert_equal(baseline_eco_task.document_link,    eco_task.document_link)
    assert_equal(eco_type_list,                      baseline_eco_task.eco_types)
    
    baseline_eco_task.reload
    
    # Change the completed flag
    put(:update, 
        { :id       => baseline_eco_task.id, 
          :eco_task => { :number           => 'P4000',
                         :pcb_revision     => 'C',
                         :pcba_part_number => "600-555-00",
                         :eco_type_ids     => ["1", "2"],
                         :completed        => '0',
                         :closed           => '0',
                         :document_link    => nil } },
        @patrice_session)
    assert_redirected_to eco_tasks_url
    eco_task = EcoTask.find(baseline_eco_task.id)

    assert_equal(baseline_eco_task.number,           eco_task.number)
    assert_equal(baseline_eco_task.pcb_revision,     eco_task.pcb_revision)
    assert_equal(baseline_eco_task.pcba_part_number, eco_task.pcba_part_number)
    assert_equal(false,                              eco_task.completed?)
    assert_equal(baseline_eco_task.closed?,          eco_task.closed?)
    assert_equal(baseline_eco_task.document_link,    eco_task.document_link)
    assert_equal(eco_type_list,                      baseline_eco_task.eco_types)
    
    baseline_eco_task.reload
    
    # Change the baseline
    put(:update, 
        { :id       => baseline_eco_task.id, 
          :eco_task => { :number           => 'P4000',
                         :pcb_revision     => 'C',
                         :pcba_part_number => "600-555-00",
                         :eco_type_ids     => ["1", "2"],
                         :completed        => '0',
                         :closed           => '0',
                         :document_link    => '/hwnet/dtg_rules' } },
        @patrice_session)
    assert_redirected_to eco_tasks_url
    eco_task = EcoTask.find(baseline_eco_task.id)

    assert_equal(baseline_eco_task.number,           eco_task.number)
    assert_equal(baseline_eco_task.pcb_revision,     eco_task.pcb_revision)
    assert_equal(baseline_eco_task.pcba_part_number, eco_task.pcba_part_number)
    assert_equal(baseline_eco_task.completed?,       eco_task.completed?)
    assert_equal(baseline_eco_task.closed?,          eco_task.closed?)
    assert_equal('/hwnet/dtg_rules',                 eco_task.document_link)
    assert_equal(eco_type_list,                      baseline_eco_task.eco_types)
    
    baseline_eco_task.reload
    
  end

=begin DESTROY IS NOT USED
  def test_should_destroy_eco_task
    assert_difference('EcoTask.count', -1) do
      delete :destroy, :id => eco_tasks(:task_one).id
    end

    assert_redirected_to eco_tasks_path
  end
=end
  
end
