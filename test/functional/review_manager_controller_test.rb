########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: review_manager_controller_test.rb
#
# This file contains the functional tests for the review manager controller
#
# $Id$
#
########################################################################
#

require File.dirname(__FILE__) + '/../test_helper'
require 'review_manager_controller'

# Re-raise errors caught by the controller.
class ReviewManagerController; def rescue_action(e) raise e end; end

class ReviewManagerControllerTest < Test::Unit::TestCase
  def setup
    @controller = ReviewManagerController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end


  fixtures(:review_types,
           :review_types_roles,
           :roles,
           :users)


  ######################################################################
  #
  # test_review_type_role_assignment
  #
  # Description:
  # This method does the functional testing of the 
  # review_type_role_assignment method  from the ReviewManager class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_review_type_role_assignment

    # Verify response when not logged in.
    post :review_type_role_assignment

    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])


    # Verify response when logged in as a non-admin
    set_non_admin
    post :review_type_role_assignment

    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Verify response when logged in as an admin
    set_admin
    post :review_type_role_assignment

    assert_response :success

    roles        = assigns(roles)['roles']
    review_types = assigns(review_types)['review_types']

    assert_equal(19, roles.size)
    assert_equal(5, review_types.size)

    expected_values = Array[
      {:name => 'CE-DFT',     
       :review_types => ['Final', 'Placement', 'Pre-Artwork', 'Routing']},
      {:name => 'Compliance - EMC',     
       :review_types => []},
      {:name => 'Compliance - Safety',     
       :review_types => []},
      {:name => 'DFM',
       :review_types => ['Final', 'Placement', 'Pre-Artwork', 'Routing']},
      {:name => 'Hardware Engineering Manager',
       :review_types => []},
      {:name => 'HWENG',
       :review_types => ['Final', 'Placement', 'Pre-Artwork', 'Release', 'Routing']},
      {:name => 'Library',
       :review_types => ['Pre-Artwork']},
      {:name => 'Mechanical',
       :review_types => ['Final', 'Placement', 'Pre-Artwork']},
      {:name => 'Mechanical-MFG',
       :review_types => ['Final', 'Placement', 'Pre-Artwork', 'Routing']}, 
      {:name => 'Operations Manager',        
       :review_types => ['Release']},
      {:name => 'PCB Design',        
       :review_types => ['Final', 'Release']},
      {:name => 'PCB Input Gate',
       :review_types => ['Pre-Artwork']},
      {:name => 'PCB Mechanical',
       :review_types => ['Pre-Artwork']},
      {:name => 'Planning',
       :review_types => ['Final', 'Pre-Artwork']},
      {:name => 'Program Manager',
       :review_types => []},
      {:name => 'SLM BOM',
       :review_types => ['Pre-Artwork']},
      {:name => 'SLM-Vendor',
       :review_types => ['Pre-Artwork']},
      {:name => 'TDE',
       :review_types => ['Final', 'Placement', 'Pre-Artwork']},
      {:name => 'Valor',
       :review_types => ['Final', 'Pre-Artwork']}
    ]

    roles.each { |role|
      expected_role = expected_values.shift

      review_types = role.review_types.sort_by { |rt| rt.name }
      review_types.each { |rt|
        expected_rt = expected_role[:review_types]
        expected_name = expected_rt.shift
        assert_equal(expected_role[:name]+'::'+expected_name.to_s,
                     role.name+'::'+rt.name)
      }

    }

    expected_values = Array[
      {:name => 'Final',
        :role_names => ['HWENG', 'Valor', 'CE-DFT', 'DFM', 'TDE', 'Mechanical', 'Mechanical-MFG', 'PCB Design', 'Planning']},
      {:name => 'Pre-Artwork',
        :role_names => ['HWENG', 'Valor', 'CE-DFT', 'DFM', 'TDE', 'Mechanical', 'Mechanical-MFG', 'Planning', 'PCB Input Gate', 'Library', 'PCB Mechanical', 'SLM BOM', 'SLM-Vendor']},
      {:name => 'Placement',
        :role_names => ['HWENG', 'CE-DFT', 'DFM', 'TDE', 'Mechanical', 'Mechanical-MFG']},
      {:name => 'Routing',
        :role_names => ['HWENG', 'CE-DFT', 'DFM', 'Mechanical-MFG', 'Library']},
      {:name => 'Release',
        :role_names => ['HWENG', 'PCB Design', 'Operations Manager']},
    ]
    review_types.each { |review_type| 
      expected_rt = expected_values.shift
      assert_equal(expected_rt[:name], review_type.name)

      review_type.roles.each { |role|
        expected_role = expected_rt[:role_names]
        expected_name = expected_role.shift
        assert_equal(expected_name, role.name)
      }
    }

  end


  ######################################################################
  #
  # test_assign_groups_to_reviews
  #
  # Description:
  # This method does the functional testing of the 
  # assign_groups_to_reviews method  from the ReviewManager class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_assign_groups_to_reviews

    set_admin
    post(:assign_groups_to_reviews,
         :review_type => {
           # 1-Final, 2-Routing, 3-Pre-Art, 4-Placement, 5-Release
           '5_1'=>'1',  '5_2'=>'0',  '5_3'=>'1',  '5_4'=>'0', '5_5'=>'0',   #HWENG
           '6_1'=>'1',  '6_2'=>'1',  '6_3'=>'1',  '6_4'=>'0', '6_5'=>'1',   #VALOR
           '7_1'=>'1',  '7_2'=>'1',  '7_3'=>'0',  '7_4'=>'1', '7_5'=>'1',   #CE-DFT
           '8_1'=>'0',  '8_2'=>'0',  '8_3'=>'1',  '8_4'=>'0', '8_5'=>'1',   #DFM
           '9_1'=>'1',  '9_2'=>'0',  '9_3'=>'1',  '9_4'=>'1', '9_5'=>'0',   #TDE
	       '10_1'=>'1', '10_2'=>'0', '10_3'=>'1', '10_4'=>'1', '10_5'=>'0', #MECHANICAL
           '11_1'=>'0', '11_2'=>'1', '11_3'=>'1', '11_4'=>'1', '11_5'=>'0', #MECH-MFG
           '12_1'=>'1', '12_2'=>'0', '12_3'=>'0', '12_4'=>'0', '12_5'=>'1', #PCB DESIGN
           '13_1'=>'1', '13_2'=>'0', '13_3'=>'1', '13_4'=>'0', '13_5'=>'0', #PLANNING
           '14_1'=>'1', '14_2'=>'0', '14_3'=>'0', '14_4'=>'0', '14_5'=>'0', #PCB IG
           '15_1'=>'1', '15_2'=>'0', '15_3'=>'0', '15_4'=>'0', '15_5'=>'0', #LIBRARY
           '16_1'=>'0', '16_2'=>'0', '16_3'=>'1', '16_4'=>'1', '16_5'=>'1', #PCB MECH
           '17_1'=>'1', '17_2'=>'1', '17_3'=>'1', '17_4'=>'1', '17_5'=>'1', #SLM BOM
           '18_1'=>'0', '18_2'=>'1', '18_3'=>'1', '18_4'=>'1', '18_5'=>'0', #SLM-Vendor
           '19_1'=>'1', '19_2'=>'0', '19_3'=>'0', '19_4'=>'0', '19_5'=>'1'  #OPS MGR
         })

    post :review_type_role_assignment

    assert_response :success

    roles = assigns(roles)['roles']
    review_types  = assigns(review_types)['review_types']

    assert_equal(19, roles.size)
    assert_equal(5, review_types.size)

    expected_values = Array[
      {:name => 'CE-DFT',
       :review_types => ['Final', 'Placement', 'Release', 'Routing']},
      {:name => 'Compliance - EMC',     
       :review_types => []},
      {:name => 'Compliance - Safety',     
       :review_types => []},
      {:name => 'DFM',
       :review_types => ['Pre-Artwork', 'Release']},
      {:name => 'Hardware Engineering Manager',
       :review_types => []},
      {:name => 'HWENG',
       :review_types => ['Final', 'Pre-Artwork']},
      {:name => 'Library',
       :review_types => ['Final']},
      {:name => 'Mechanical',
       :review_types => ['Final', 'Placement', 'Pre-Artwork']},
      {:name => 'Mechanical-MFG',
       :review_types => ['Placement', 'Pre-Artwork', 'Routing']},
      {:name => 'Operations Manager',
       :review_types => ['Final', 'Release']},
      {:name => 'PCB Design',
       :review_types => ['Final', 'Release']},
      {:name => 'PCB Input Gate',
       :review_types => ['Final']},
      {:name => 'PCB Mechanical',
       :review_types => ['Placement', 'Pre-Artwork', 'Release']},
      {:name => 'Planning',
       :review_types => ['Final', 'Pre-Artwork']},
      {:name => 'Program Manager',
       :review_types => []},
      {:name => 'SLM BOM',
       :review_types => ['Final', 'Placement', 'Pre-Artwork', 'Release', 'Routing']},
      {:name => 'SLM-Vendor',
       :review_types => ['Placement', 'Pre-Artwork', 'Routing']},
      {:name => 'TDE',
       :review_types => ['Final', 'Placement', 'Pre-Artwork']},
      {:name => 'Valor',      
       :review_types => ['Final', 'Pre-Artwork', 'Release', 'Routing']}
    ]

    roles.each { |role|
      expected_role = expected_values.shift
      
      returned_rts = []
      role.review_types.each { |rt| returned_rts.push(rt.name) }

      returned_rts.sort.each { |review_type|
        expected_rt = expected_role[:review_types]
        expected_name = expected_rt.shift
        assert_equal(expected_role[:name]+'::'+expected_name.to_s,
                     role.name+'::'+review_type)
      }

    }

    expected_values = Array[
      {:name => 'Pre-Artwork',
        :role_names => ['DFM', 'HWENG', 'Mechanical', 'Mechanical-MFG', 'PCB Mechanical', 'Planning', 'SLM BOM', 'SLM-Vendor', 'TDE', 'Valor']},
      {:name => 'Placement', 
        :role_names => ['CE-DFT', 'Mechanical', 'Mechanical-MFG', 'PCB Mechanical', 'SLM BOM', 'SLM-Vendor', 'TDE']},
      {:name => 'Routing', 
        :role_names => ['CE-DFT', 'Mechanical-MFG', 'SLM BOM', 'SLM-Vendor', 'Valor']},
      {:name => 'Final',
        :role_names => ['CE-DFT', 'HWENG', 'Library', 'Mechanical', 'Operations Manager', 'PCB Design', 'PCB Input Gate', 'Planning', 'SLM BOM', 'TDE', 'Valor']},
      {:name => 'Release', 
        :role_names => ['CE-DFT', 'DFM', 'Operations Manager', 'PCB Design', 'PCB Mechanical', 'SLM BOM', 'Valor']}
    ]
    review_types.each { |review_type| 
      expected_rt = expected_values.shift

      returned_roles = []
      review_type.roles.each { |role| returned_roles.push(role.name) }

      returned_roles.sort.each { |role|
        expected_role = expected_rt[:role_names]
        expected_name = expected_role.shift
        assert_equal(expected_rt[:name]+'::'+expected_name, 
                     review_type.name+'::'+role)
      }
    }

  end


end
