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
  
    get('index', {}, {})
    assert_response(:success)
    assert_template('tracker/index')

    manager_session = jim_manager_session
    get('index', {}, manager_session)
    assert_equal('DESC', assigns(:sort_order)[:priority])

    active_reviews   = assigns(:active_reviews)
    inactive_reviews = assigns(:inactive_reviews)

    expected_active_design_reviews = [ design_reviews(:mx600a_pre_artwork),
                                       design_reviews(:mx234a_pre_artwork),
                                       design_reviews(:la454c3_placement),
                                       design_reviews(:mx999a_pre_artwork),
                                       design_reviews(:mx999b_pre_artwork),
                                       design_reviews(:mx999c_pre_artwork),
                                       design_reviews(:la453a1_placement),
                                       design_reviews(:design_reviews_129)]

    assert_equal(expected_active_design_reviews.size,    active_reviews.size)
    assert_equal(expected_active_design_reviews.collect { |dr| dr.design.directory_name }, 
                 active_reviews.collect { |dr| dr.design.directory_name })

    expected_inactive_design_reviews = [ design_reviews(:mx234b_placement),
                                         design_reviews(:mx700b_pre_artwork),
                                         design_reviews(:la455b_final),
                                         design_reviews(:mx234c_routing),
                                         design_reviews(:la453b_placement) ]
 
    assert_equal(expected_inactive_design_reviews.size, inactive_reviews.size)
    assert_equal(expected_inactive_design_reviews,      inactive_reviews)
    

    manager_session['flash'] = 'ASC'
    post('manager_list_by_priority', { :order => 'DESC' }, manager_session)
    
    expected_active_design_reviews = expected_active_design_reviews.sort_by { |dr| [dr.priority.value, dr.age] }.reverse
    expected_inactive_design_reviews.reverse!
    assert_equal('ASC',                            assigns(:sort_order)[:priority])
    assert_equal(expected_active_design_reviews.collect { |dr| dr.design.directory_name + ': ' + dr.priority.name }, 
                 assigns(:active_reviews).collect { |dr| dr.design.directory_name + ': ' + dr.priority.name })
    assert_equal(expected_inactive_design_reviews.collect { |dr| dr.design.directory_name + ': ' + dr.priority.name }, 
                 assigns(:inactive_reviews).collect { |dr| dr.design.directory_name + ': ' + dr.priority.name })

    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    post('manager_list_by_priority', { :order => 'ASC' }, manager_session)
    assert_equal('DESC',                           assigns(:sort_order)[:priority])
    assert_equal(expected_active_design_reviews.collect { |dr| dr.design.directory_name + ': ' + dr.priority.name },   
                 assigns(:active_reviews).collect { |dr| dr.design.directory_name + ': ' + dr.priority.name })
    assert_equal(expected_inactive_design_reviews.collect { |dr| dr.design.directory_name + ': ' + dr.priority.name },
                 assigns(:inactive_reviews).collect { |dr| dr.design.directory_name + ': ' + dr.priority.name })

    post('manager_list_by_design', { :order => 'DESC' }, manager_session)
    expected_active_design_reviews = 
      expected_active_design_reviews.sort_by { |dr| [dr.design.part_number.pcb_display_name, dr.age] }
    expected_inactive_design_reviews = 
      expected_inactive_design_reviews.sort_by { |dr| [dr.design.part_number.pcb_display_name, dr.age] }
    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    assert_equal('ASC',                            assigns(:sort_order)[:design])
    assert_equal(expected_active_design_reviews.collect { |dr| dr.design.part_number.pcb_display_name },
                 assigns(:active_reviews).collect { |dr| dr.design.part_number.pcb_display_name })
    assert_equal(expected_inactive_design_reviews.collect { |dr| dr.design.part_number.pcb_display_name }, 
                 assigns(:inactive_reviews).collect { |dr| dr.design.part_number.pcb_display_name })

    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    post('manager_list_by_design', { :order => 'ASC' }, manager_session)
    assert_equal('DESC',                           assigns(:sort_order)[:design])
    assert_equal(expected_active_design_reviews.collect { |dr| dr.design.part_number.pcb_display_name },  
                 assigns(:active_reviews).collect { |dr| dr.design.part_number.pcb_display_name })
    assert_equal(expected_inactive_design_reviews.collect { |dr| dr.design.part_number.pcb_display_name }, 
                 assigns(:inactive_reviews).collect { |dr| dr.design.part_number.pcb_display_name })

    post('manager_list_by_type', { :order => 'DESC' }, manager_session)
    expected_active_design_reviews = 
      expected_active_design_reviews.sort_by { |dr| [dr.review_type.sort_order, dr.age] }
    expected_inactive_design_reviews = 
      expected_inactive_design_reviews.sort_by { |dr| [dr.review_type.sort_order, dr.age] }
    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    assert_equal('ASC',                            assigns(:sort_order)[:type])
    assert_equal(expected_active_design_reviews.collect { |dr| dr.design.directory_name + ': ' + dr.review_type.name },
                 assigns(:active_reviews).collect { |dr| dr.design.directory_name + ': ' + dr.review_type.name })
    assert_equal(expected_inactive_design_reviews.collect { |dr| dr.design.directory_name + ': ' + dr.review_type.name }, 
                 assigns(:inactive_reviews).collect { |dr| dr.design.directory_name + ': ' + dr.review_type.name })

    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    post('manager_list_by_type', { :order => 'ASC' }, manager_session)
    assert_equal('DESC', assigns(:sort_order)[:type])
    assert_equal(expected_active_design_reviews.collect { |dr| dr.design.directory_name + ': ' + dr.review_type.name },   
                 assigns(:active_reviews).collect { |dr| dr.design.directory_name + ': ' + dr.review_type.name })
    assert_equal(expected_inactive_design_reviews.collect { |dr| dr.design.directory_name + ': ' + dr.review_type.name }, 
                 assigns(:inactive_reviews).collect { |dr| dr.design.directory_name + ': ' + dr.review_type.name })

    post('manager_list_by_designer', { :order => 'DESC' }, manager_session)
    expected_active_design_reviews = 
      expected_active_design_reviews.sort_by { |dr| [dr.designer.last_name, dr.age] }
    expected_inactive_design_reviews = 
      expected_inactive_design_reviews.sort_by { |dr| [dr.designer.last_name, dr.age] }
    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    assert_equal('ASC', assigns(:sort_order)[:designer])
    assert_equal(expected_active_design_reviews.collect { |dr| dr.design.directory_name + ': ' + dr.designer.last_name },   
                 assigns(:active_reviews).collect { |dr| dr.design.directory_name + ': ' + dr.designer.last_name })
    assert_equal(expected_inactive_design_reviews.collect { |dr| dr.design.directory_name + ': ' + dr.designer.last_name },
                 assigns(:inactive_reviews).collect { |dr| dr.design.directory_name + ': ' + dr.designer.last_name })

    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    post('manager_list_by_designer', { :order => 'ASC' }, manager_session)
    assert_equal('DESC', assigns(:sort_order)[:designer])
    assert_equal(expected_active_design_reviews.collect { |dr| dr.design.directory_name + ': ' + dr.designer.last_name },   
                 assigns(:active_reviews).collect { |dr| dr.design.directory_name + ': ' + dr.designer.last_name })
    assert_equal(expected_inactive_design_reviews.collect { |dr| dr.design.directory_name + ': ' + dr.designer.last_name }, 
                 assigns(:inactive_reviews).collect { |dr| dr.design.directory_name + ': ' + dr.designer.last_name })

    post('manager_list_by_peer', { :order => 'DESC' }, manager_session)
    expected_active_design_reviews = 
      expected_active_design_reviews.sort_by { |dr| [dr.design.peer.last_name, dr.age] }
    expected_inactive_design_reviews = 
      expected_inactive_design_reviews.sort_by { |dr| [dr.design.peer.last_name, dr.age] }
    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    assert_equal('ASC', assigns(:sort_order)[:peer])
    assert_equal(expected_active_design_reviews.collect { |dr| dr.design.directory_name + ': ' + dr.design.peer.last_name },   
                 assigns(:active_reviews).collect { |dr| dr.design.directory_name + ': ' + dr.design.peer.last_name })
    assert_equal(expected_inactive_design_reviews.collect { |dr| dr.design.directory_name + ': ' + dr.design.peer.last_name }, 
                 assigns(:inactive_reviews).collect { |dr| dr.design.directory_name + ': ' + dr.design.peer.last_name })

    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    post('manager_list_by_peer', { :order => 'ASC' }, manager_session)
    assert_equal('DESC', assigns(:sort_order)[:peer])
    assert_equal(expected_active_design_reviews.collect { |dr| dr.design.directory_name + ': ' + dr.design.peer.last_name },   
                 assigns(:active_reviews).collect { |dr| dr.design.directory_name + ': ' + dr.design.peer.last_name })
    assert_equal(expected_inactive_design_reviews.collect { |dr| dr.design.directory_name + ': ' + dr.design.peer.last_name }, 
                 assigns(:inactive_reviews).collect { |dr| dr.design.directory_name + ': ' + dr.design.peer.last_name })

    post('manager_list_by_age', { :order => 'DESC' }, manager_session)
    expected_active_design_reviews = 
      expected_active_design_reviews.sort_by { |dr| [dr.age, dr.priority.value] }
    expected_inactive_design_reviews = 
      expected_inactive_design_reviews.sort_by { |dr| [dr.age, dr.priority.value] }
    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    assert_equal('ASC', assigns(:sort_order)[:date])
    assert_equal(expected_active_design_reviews.collect { |dr| dr.design.directory_name },   
                 assigns(:active_reviews).collect { |dr| dr.design.directory_name })
    assert_equal(expected_inactive_design_reviews.collect { |dr| dr.design.directory_name }, 
                 assigns(:inactive_reviews).collect { |dr| dr.design.directory_name })

    expected_active_design_reviews.reverse!
    expected_inactive_design_reviews.reverse!
    post('manager_list_by_age', { :order => 'ASC' }, manager_session)
    assert_equal('DESC', assigns(:sort_order)[:date])
    assert_equal(expected_active_design_reviews.collect { |dr| dr.design.directory_name },   
                 assigns(:active_reviews).collect { |dr| dr.design.directory_name })
    assert_equal(expected_inactive_design_reviews.collect { |dr| dr.design.directory_name }, 
                 assigns(:inactive_reviews).collect { |dr| dr.design.directory_name })

  end
  
  
  ######################################################################
  def test_should_get_index_template
    get(:index, {}, {})
    assert_response(:success)
    assert_template 'tracker/index'
  end
  
  
  ######################################################################
  def test_should_get_manager_home_template
    get(:index, {}, cathy_admin_session )
    assert_response(:success)
    assert_template('tracker/manager_home')
  end
  
  
  ######################################################################
  def test_should_get_designer_home_template
    get(:index, {}, rich_designer_session)
    assert_response(:success)
    assert_template('tracker/designer_home')
  end
  
  
  ######################################################################
  def test_should_get_manager_home_template
    get(:index, {}, jim_manager_session)
    assert_response(:success)
    assert_template('tracker/manager_home')
  end  


  ######################################################################
  def test_should_get_reviewer_home_template
    get(:index, {}, pat_dfm_session)
    assert_response(:success)
    assert_template('tracker/reviewer_home')
  end  
  
  
  ######################################################################
  def test_should_get_pcb_admin_template
    get(:index, {}, patrice_pcb_admin_session)
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

    post('index', {}, {})
    assert_response(:success)
    assert_template('tracker/index')

    post('index', {}, bob_designer_session)
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

    post('index', {}, {})
    assert_response(:success)
    assert_template('tracker/index')
    
    post('index', {}, lee_hweng_session)
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
  
    post('admin_home', {}, {})
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    
    post('reviewer_home', {}, {})
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    
    post('manager_home', {}, {})
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    
    post('pcb_admin_home', {}, {})
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    
    post('designer_home', {}, {})
    assert_redirected_to(:controller => 'tracker', :action => 'index')
  
  end
  
  
end
