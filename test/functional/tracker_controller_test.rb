########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: tracker_controller_test.rb
#
# This file contains the functional tests for the tracker controller
#
# $Id$
#
########################################################################
#

require File.dirname(__FILE__) + '/../test_helper'
require 'tracker_controller'

# Re-raise errors caught by the controller.
class TrackerController; def rescue_action(e) raise e end; end

class TrackerControllerTest < Test::Unit::TestCase


  def setup
    @controller = TrackerController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end


  fixtures(:audits,
           :boards,
           :designs,
           :design_review_results,
           :design_reviews,
           :prefixes,
           :platforms,
           :priorities,
           :projects,
           :review_statuses,
           :roles,
           :users)


  ######################################################################
  #
  # test_manager_home
  #
  # Description:
  # This method does the functional testing for the manager methods
  #
  ######################################################################
  #
  def test_manager_home
  
    post('index')
    assert_response(:success)
    assert_template('tracker/index')
    
    set_user(users(:jim_l).id, 'Manager')

    post('index')
    assert_response(:success)
    assert_template('tracker/manager_home')

    assert_equal('DESC', assigns(:sort_order)[:priority])

    active_reviews   = assigns(:active_reviews)
    inactive_reviews = assigns(:inactive_reviews)

    expected_active_design_reviews = [ design_reviews(:mx999c_pre_artwork),
                                       design_reviews(:mx999b_pre_artwork),
                                       design_reviews(:mx999a_pre_artwork),
                                       design_reviews(:la454c3_placement),
                                       design_reviews(:mx234a_pre_artwork),
                                       design_reviews(:design_reviews_129),
                                       design_reviews(:la453a1_placement),
                                       design_reviews(:mx600a_pre_artwork) ]

    assert_equal(expected_active_design_reviews.size, active_reviews.size)
    assert_equal(expected_active_design_reviews,      active_reviews)

    expected_inactive_design_reviews = [ design_reviews(:mx234b_placement),
                                         design_reviews(:mx234c_routing),
                                         design_reviews(:mx700b_pre_artwork),
                                         design_reviews(:la453a_eco1_final),
                                         design_reviews(:la453b_placement) ]
                                         
    assert_equal(expected_inactive_design_reviews.size, inactive_reviews.size)
    assert_equal(expected_inactive_design_reviews,      inactive_reviews)
    
    post('manager_list_by_priority', :order => 'DESC')
    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    assert_equal('ASC',                            assigns(:sort_order)[:priority])
    assert_equal(expected_active_design_reviews,   assigns(:active_reviews))
    assert_equal(expected_inactive_design_reviews, assigns(:inactive_reviews))

    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    post('manager_list_by_priority', :order => 'ASC')
    assert_equal('DESC',                           assigns(:sort_order)[:priority])
    assert_equal(expected_active_design_reviews,   assigns(:active_reviews))
    assert_equal(expected_inactive_design_reviews, assigns(:inactive_reviews))

    post('manager_list_by_design', :order => 'DESC')
    expected_active_design_reviews = 
      expected_active_design_reviews.sort_by { |design_review| [design_review.design.name, design_review.age] }
    expected_inactive_design_reviews = 
      expected_inactive_design_reviews.sort_by { |design_review| [design_review.design.name, design_review.age] }
    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    assert_equal('ASC',                            assigns(:sort_order)[:design])
    assert_equal(expected_active_design_reviews,   assigns(:active_reviews))
    assert_equal(expected_inactive_design_reviews, assigns(:inactive_reviews))

    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    post('manager_list_by_design', :order => 'ASC')
    assert_equal('DESC',                           assigns(:sort_order)[:design])
    assert_equal(expected_active_design_reviews,   assigns(:active_reviews))
    assert_equal(expected_inactive_design_reviews, assigns(:inactive_reviews))

    post('manager_list_by_type', :order => 'DESC')
    expected_active_design_reviews = 
      expected_active_design_reviews.sort_by { |design_review| [design_review.review_type.name, design_review.age] }
    expected_inactive_design_reviews = 
      expected_inactive_design_reviews.sort_by { |design_review| [design_review.review_type.name, design_review.age] }
    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    assert_equal('ASC',                            assigns(:sort_order)[:type])
    assert_equal(expected_active_design_reviews,   assigns(:active_reviews))
    assert_equal(expected_inactive_design_reviews, assigns(:inactive_reviews))

    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    post('manager_list_by_type', :order => 'ASC')
    assert_equal('DESC',                           assigns(:sort_order)[:type])
    assert_equal(expected_active_design_reviews,   assigns(:active_reviews))
    assert_equal(expected_inactive_design_reviews, assigns(:inactive_reviews))

    post('manager_list_by_designer', :order => 'DESC')
    expected_active_design_reviews = 
      expected_active_design_reviews.sort_by { |design_review| [design_review.designer.last_name, design_review.age] }
    expected_inactive_design_reviews = 
      expected_inactive_design_reviews.sort_by { |design_review| [design_review.designer.last_name, design_review.age] }
    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    assert_equal('ASC',                            assigns(:sort_order)[:designer])
    assert_equal(expected_active_design_reviews,   assigns(:active_reviews))
    assert_equal(expected_inactive_design_reviews, assigns(:inactive_reviews))

    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    post('manager_list_by_designer', :order => 'ASC')
    assert_equal('DESC',                           assigns(:sort_order)[:designer])
    assert_equal(expected_active_design_reviews,   assigns(:active_reviews))
    assert_equal(expected_inactive_design_reviews, assigns(:inactive_reviews))

    post('manager_list_by_peer', :order => 'DESC')
    expected_active_design_reviews = 
      expected_active_design_reviews.sort_by { |design_review| [design_review.design.peer.last_name, design_review.age] }
    expected_inactive_design_reviews = 
      expected_inactive_design_reviews.sort_by { |design_review| [design_review.design.peer.last_name, design_review.age] }
    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    assert_equal('ASC',                            assigns(:sort_order)[:peer])
    assert_equal(expected_active_design_reviews,   assigns(:active_reviews))
    assert_equal(expected_inactive_design_reviews, assigns(:inactive_reviews))

    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    post('manager_list_by_peer', :order => 'ASC')
    assert_equal('DESC',                           assigns(:sort_order)[:peer])
    assert_equal(expected_active_design_reviews,   assigns(:active_reviews))
    assert_equal(expected_inactive_design_reviews, assigns(:inactive_reviews))

    post('manager_list_by_age', :order => 'DESC')
    expected_active_design_reviews = 
      expected_active_design_reviews.sort_by { |design_review| [design_review.age, design_review.priority.value] }
    expected_inactive_design_reviews = 
      expected_inactive_design_reviews.sort_by { |design_review| [design_review.age, design_review.priority.value] }
    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    assert_equal('ASC',                            assigns(:sort_order)[:date])
    assert_equal(expected_active_design_reviews,   assigns(:active_reviews))
    assert_equal(expected_inactive_design_reviews, assigns(:inactive_reviews))

    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    post('manager_list_by_age', :order => 'ASC')
    assert_equal('DESC',                           assigns(:sort_order)[:date])
    assert_equal(expected_active_design_reviews,   assigns(:active_reviews))
    assert_equal(expected_inactive_design_reviews, assigns(:inactive_reviews))

  end
  
  
  ######################################################################
  #
  # test_index
  #
  # Description:
  # This method does the functional testing for the index method.
  #
  ######################################################################
  #
  def test_index

    # First verify the screen when not logged in.
    get :index
    assert_response(:success)
    assert_template 'tracker/index'

    set_admin()
    get :index
    assert_response(:success)
    assert_template('tracker/manager_home')

    set_designer()
    get :index
    assert_response(:success)
    assert_template('tracker/designer_home')

    set_manager()
    get :index
    assert_response(:success)
    assert_template('tracker/manager_home')

    set_reviewer()
    get :index
    assert_response(:success)
    assert_template('tracker/reviewer_home')

    set_user(users(:patrice_m).id, 'PCB Admin')
    get :index
    assert_response(:success)
    assert_template('tracker/pcb_admin_home')

    
  end
  
  
  ######################################################################
  #
  # test_designer_home
  #
  # Description:
  # This method does the functional testing for the designer methods
  #
  ######################################################################
  #
  def test_designer_home

    post('index')
    assert_response(:success)
    assert_template('tracker/index')

    set_user(users(:bob_g).id, 'Designer')
    post('index')
    assert_response(:success)
    assert_template('tracker/designer_home')

  end
  

  ######################################################################
  #
  # test_reviewer_home
  #
  # Description:
  # This method does the functional testing for the reviewer methods
  #
  ######################################################################
  #
  def test_reviewer_home

    post('index')
    assert_response(:success)
    
    set_user(users(:lee_s).id, 'HWENG')
    post('index')
    assert_response(:success)
    assert_template('tracker/reviewer_home')

    #follow_redirect
    #assert_no_tag :content => "POST Placement Review"

  end
  
  
  ######################################################################
  #
  # test_home_page_redirects
  #
  # Description:
  # This method does the functional testing for the home page redirects.
  #
  ######################################################################
  #
  def test_home_page_redirects
  
    post('admin_home')
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    
    post('reviewer_home')
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    
    post('manager_home')
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    
    post('pcb_admin_home')
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    
    post('designer_home')
    assert_redirected_to(:controller => 'tracker', :action => 'index')
  
  end
  
  
end
