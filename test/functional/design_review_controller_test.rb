########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_review_controller_test.rb
#
# This file contains the functional tests for the design review controller
#
# $Id$
#
########################################################################
#

require File.dirname(__FILE__) + '/../test_helper'
require 'design_review_controller'

# Re-raise errors caught by the controller.
class DesignReviewController; def rescue_action(e) raise e end; end

class DesignReviewControllerTest < Test::Unit::TestCase
  def setup
    @controller = DesignReviewController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end


  fixtures(:board_reviewers,
           :boards,
           :design_centers,
           :design_review_results,
           :design_reviews,
           :designs,
           :priorities,
           :review_statuses,
           :users)

  def test_1_id
    print ("\n*** Design Review Controller Test - NEEDS WORK!!!\n")
    print ("*** $Id$\n")
  end


  ######################################################################
  #
  # test_view
  #
  # Description:
  # This method does the functional testing of the view method
  # from the Design Review class
  #
  ######################################################################
  #
  def test_view
  
    # Verify that the default view is called when the user is not
    # logged in.
    mx234a_pre_art = design_reviews(:mx234a_pre_artwork)
    mx234a         = designs(:mx234a)
    get(:view, :id => mx234a_pre_art.id)
    
    assert_response 302
    assert_redirect_url('http://test.host/design_review/safe_view/1')

    get(:safe_view, :id => mx234a_pre_art.id)
    assert_equal(mx234a_pre_art.id, assigns(:design_review).id)
    assert_equal(mx234a.id,         assigns(:design).id)
    assert_equal(14,                assigns(:review_results).size)
    assert_equal(0,                 assigns(:comments).size)
    
  end


  ######################################################################
  #
  # test_admin_view
  #
  # Description:
  # This method does the functional testing of the admin_view method
  # from the Design Review class
  #
  ######################################################################
  #
  def test_admin_view
  
    # Verify that the admin view is called when the user is 
    # logged in as an admin.
    set_user(users(:cathy_m).id, 'Admin')
    mx234a_pre_art = design_reviews(:mx234a_pre_artwork)
    mx234a         = designs(:mx234a)
    get(:view, :id => mx234a_pre_art.id)
    
    assert_response 302
    assert_redirect_url('http://test.host/design_review/admin_view/1')

    get(:admin_view, :id => mx234a_pre_art.id)
    assert_equal(mx234a_pre_art.id, assigns(:design_review).id)
    assert_equal(mx234a.id,         assigns(:design).id)
    assert_equal(14,                assigns(:review_results).size)
    assert_equal(0,                 assigns(:comments).size)

    end

  ######################################################################
  #
  # test_designer_view
  #
  # Description:
  # This method does the functional testing of the designer_view method
  # from the Design Review class
  #
  ######################################################################
  #
  def test_designer_view
    
    # Verify that the designer view is called when the user is 
    # logged in as a designer.
    set_user(users(:scott_g).id, 'Designer')
    mx234a_pre_art = design_reviews(:mx234a_pre_artwork)
    mx234a         = designs(:mx234a)
    get(:view, :id => mx234a_pre_art.id)
    
    assert_response 302
    assert_redirect_url('http://test.host/design_review/designer_view/1')

    get(:designer_view, :id => mx234a_pre_art.id)
    assert_equal(mx234a_pre_art.id, assigns(:design_review).id)
    assert_equal(mx234a.id,         assigns(:design).id)
    assert_equal(14,                assigns(:review_results).size)
    assert_equal(0,                 assigns(:comments).size)
    
  end


  ######################################################################
  #
  # test_reviewer_view
  #
  # Description:
  # This method does the functional testing of the reviewer_view method
  # from the Design Review class
  #
  # TO DO:
  # Log in as "PCB Manager" to exercise special processing.
  #
  ######################################################################
  #
  def test_reviewer_view
    
    # Verify that the reviewer view is called when the user is 
    # logged in as a reviewer.
    set_user(users(:ted_p).id, 'CE-DFT')
    mx234a_pre_art = design_reviews(:mx234a_pre_artwork)
    mx234a         = designs(:mx234a)
    get(:view, :id => mx234a_pre_art.id)

    assert_response 302
    assert_redirected_to(:action => :reviewer_view,
                         :id     => mx234a_pre_art.id.to_s)

    get(:reviewer_view, :id => mx234a_pre_art.id)
    assert_equal(mx234a_pre_art.id, assigns(:design_review).id)
    assert_equal(mx234a.id,         assigns(:design).id)
    assert_equal(14,                assigns(:review_results).size)
    assert_equal(0,                 assigns(:comments).size)
    assert_equal(nil,               assigns(:designers))
    assert_equal(nil,               assigns(:priorities))
    
    # Verify information for PCB during a placement review.
    set_user(users(:jim_l).id, 'PCB Design')
    mx234a           = designs(:mx234a)
    get(:view, :id => mx234a_pre_art.id)

    assert_response 302
    assert_redirected_to(:action => :reviewer_view,
                         :id     => mx234a_pre_art.id.to_s)

    get(:reviewer_view, :id => mx234a_pre_art.id)
    assert_equal(mx234a_pre_art.id, assigns(:design_review).id)
    assert_equal(mx234a.id,         assigns(:design).id)
    assert_equal(14,                assigns(:review_results).size)
    assert_equal(0,                 assigns(:comments).size)
    assert_equal(3,                 assigns(:designers).size)
    assert_equal(2,                 assigns(:priorities).size)
    
  end


  ######################################################################
  #
  # test_manager_view
  #
  # Description:
  # This method does the functional testing of the manager_view method
  # from the Design Review class
  #
  ######################################################################
  #
  def test_manager_view
    
    # Verify that the manager view is called when the user is 
    # logged in as a manager.
    set_user(users(:jim_l).id, 'Manager')
    mx234a_pre_art = design_reviews(:mx234a_pre_artwork)
    mx234a         = designs(:mx234a)
    get(:view, :id => mx234a_pre_art.id)
    
    assert_response 302
    assert_redirect_url('http://test.host/design_review/manager_view/1')

    get(:manager_view, :id => mx234a_pre_art.id)
    assert_equal(mx234a_pre_art.id, assigns(:design_review).id)
    assert_equal(mx234a.id,         assigns(:design).id)
    assert_equal(14,                assigns(:review_results).size)
    assert_equal(0,                 assigns(:comments).size)
    
  end


  ######################################################################
  #
  # test_posting_filter
  #
  # Description:
  # This method does the functional testing of the posting_filter method
  # from the Design Review class
  #
  ######################################################################
  #
  def test_posting_filter

    review_types = ReviewType.find_all(nil, 'sort_order ASC')
    base_url = "http://test.host/design_review/"

    for review_type in review_types

      post(:posting_filter,
           :design_id      => designs(:mx234a).id,
           :review_type_id => review_type.id)

      assert_response 302
      if review_type.name != 'Placement'

        assert_redirected_to(:action         => 'post_review',
                             :review_type_id => review_type.id.to_s,
                             :design_id      => designs(:mx234a).id.to_s)
      else
        assert_redirected_to(:action => 'placement_routing_post')
        assert_equal(designs(:mx234a).id, flash[:design_id].to_i)
        assert_equal(review_type.id     , flash[:review_type_id].to_i)

        post(:placement_routing_post)
        assert_equal(designs(:mx234a).id, flash[:design_id].to_i)
        assert_equal(review_type.id     , flash[:review_type_id].to_i)
      end

    end

  end


  ######################################################################
  #
  # test_process_placement_routing
  #
  # Description:
  # This method does the functional testing of the process_placement_routing
  # method from the Design Review class
  #
  ######################################################################
  #
  def test_process_placement_routing

    design_reviews = DesignReview.find_all_by_design_id(designs(:mx234a).id)
    assert_equal(5, design_reviews.size)

    results_count = 0
    for design_review in design_reviews
      results_count += design_review.design_review_results.size
    end
    assert_equal(37, results_count)

    placement_review_id = ReviewType.find_by_name('Placement').id
    post(:posting_filter,
         :design_id      => designs(:mx234a).id,
         :review_type_id => placement_review_id)
    
    post(:placement_routing_post)

    post(:process_placement_routing,
         :combine => {:reviews => '0'})

    assert_response 302
    assert_redirected_to(:action                    => 'post_review',
                         :combine_placement_routing => '0',
                         :design_id                 => designs(:mx234a).id.to_s,
                         :review_type_id            => placement_review_id.to_s)

    design_reviews = DesignReview.find_all_by_design_id(designs(:mx234a).id)
    assert_equal(5, design_reviews.size)

    results_count = 0
    for design_review in design_reviews
      results_count += design_review.design_review_results.size
    end
    assert_equal(37, results_count)

  end


  ######################################################################
  #
  # test_process_placement_routing_combined
  #
  # Description:
  # This method does the functional testing of the process_placement_routing
  # method from the Design Review class
  #
  ######################################################################
  #
  def test_process_placement_routing_combined

    design_reviews = DesignReview.find_all_by_design_id(designs(:mx234a).id)
    assert_equal(5, design_reviews.size)

    placement_review_id = ReviewType.find_by_name('Placement').id

    results_count = 0
    for design_review in design_reviews
      results_count += design_review.design_review_results.size
      if design_review.review_type_id == placement_review_id
        assert_equal(6, design_review.design_review_results.size)
      end
    end
    assert_equal(37, results_count)

    post(:posting_filter,
         :design_id      => designs(:mx234a).id,
         :review_type_id => placement_review_id)
    
    post(:placement_routing_post)

    post(:process_placement_routing,
         :combine => {:reviews => '1'})

    assert_response 302
    assert_redirected_to(:action                    => 'post_review',
                         :combine_placement_routing => '1',
                         :design_id                 => designs(:mx234a).id.to_s,
                         :review_type_id            => placement_review_id.to_s)

    design_reviews = DesignReview.find_all_by_design_id(designs(:mx234a).id)
    assert_equal(5, design_reviews.size)

    results_count = 0
    for design_review in design_reviews
      results_count += design_review.design_review_results.size
      if design_review.review_type_id == placement_review_id
        assert_equal(7, design_review.design_review_results.size)
      end
    end
    assert_equal(38, results_count)

    
  end


  ######################################################################
  #
  # test_post_review
  #
  # Description:
  # This method does the functional testing of the post_review method
  # from the Design Review class
  #
  ######################################################################
  #
  def test_post_review

    mx234a = designs(:mx234a)
    pre_art_review = ReviewType.find_by_name('Pre-Artwork')
    
    post(:post_review,
         :combine_placement_routing => '0',
         :design_id                 => mx234a.id,
         :review_type_id            => pre_art_review.id)

    assert_equal(mx234a.id,         assigns(:design).id)
    assert_equal(pre_art_review.id, assigns(:design_review).review_type_id)

    reviewer_list = assigns(:reviewers)
    assert_equal(14, reviewer_list.size)

    expected_values = [
      {:group          => 'CE-DFT',
       :group_id       => 7,
       :reviewer_count => 2},
      {:group          => 'DFM',
       :group_id       => 8,
       :reviewer_count => 3},
      {:group          => 'HWENG',
       :group_id       => 5,
       :reviewer_count => 4},
      {:group          => 'Library',
       :group_id       => 15,
       :reviewer_count => 2},
      {:group          => 'Mechanical',
       :group_id       => 10,
       :reviewer_count => 2},
      {:group          => 'Mechanical-MFG',
       :group_id       => 11,
       :reviewer_count => 2},
      {:group          => 'PCB Design',
       :group_id       => 12,
       :reviewer_count => 1},
      {:group          => 'PCB Input Gate',
       :group_id       => 14,
       :reviewer_count => 2},
      {:group          => 'PCB Mechanical',
       :group_id       => 16,
       :reviewer_count => 2},
      {:group          => 'Planning',
       :group_id       => 13,
       :reviewer_count => 2},
      {:group          => 'SLM BOM',
       :group_id       => 17,
       :reviewer_count => 1},
      {:group    => 'SLM Vendor',
       :group_id       => 18,
       :reviewer_count => 1},
      {:group          => 'TDE',
       :group_id       => 9,
       :reviewer_count => 2},
      {:group          => 'Valor',
       :group_id       => 6,
       :reviewer_count => 4}
    ]

    for review_group in reviewer_list
      expected_val = expected_values.shift

      assert_equal(expected_val[:group],          review_group[:group])
      assert_equal(expected_val[:group_id],       review_group[:group_id])
      assert_equal(expected_val[:reviewer_count], review_group[:reviewers].size)
    end

    pre_art_design_review = DesignReview.find_all(
                              "design_id='#{mx234a.id}' and " +
                              "review_type_id='#{pre_art_review.id}'").pop
    assert_equal(0, pre_art_design_review.review_type_id_2)

    
    placement_review = ReviewType.find_by_name('Placement')
    routing_review   = ReviewType.find_by_name('Routing')
    
    post(:post_review,
         :combine_placement_routing => '1',
         :design_id                 => mx234a.id,
         :review_type_id            => placement_review.id)

    assert_equal(mx234a.id,         assigns(:design).id)
    assert_equal(placement_review.id, assigns(:design_review).review_type_id)

    reviewer_list = assigns(:reviewers)
    assert_equal(6, reviewer_list.size)

    expected_values = [
      {:group          => 'CE-DFT',
       :group_id       => 7,
       :reviewer_count => 2},
      {:group          => 'DFM',
       :group_id       => 8,
       :reviewer_count => 3},
      {:group          => 'HWENG',
       :group_id       => 5,
       :reviewer_count => 4},
      {:group          => 'Mechanical',
       :group_id       => 10,
       :reviewer_count => 2},
      {:group          => 'Mechanical-MFG',
       :group_id       => 11,
       :reviewer_count => 2},
      {:group          => 'TDE',
       :group_id       => 9,
       :reviewer_count => 2},
      {:group          => 'Valor',
       :group_id       => 6,
       :reviewer_count => 4}
    ]

    for review_group in reviewer_list
      expected_val = expected_values.shift

      assert_equal(expected_val[:group],          review_group[:group])
      assert_equal(expected_val[:group_id],       review_group[:group_id])
      assert_equal(expected_val[:reviewer_count], review_group[:reviewers].size)
    end

    placement_design_review = DesignReview.find_all(
                                "design_id='#{mx234a.id}' and " +
                                "review_type_id='#{placement_review.id}'").pop
    assert_equal(routing_review.id, placement_design_review.review_type_id_2)

  end


  ######################################################################
  #
  # test_post
  #
  # Description:
  # This method does the functional testing of the post method
  # from the Design Review class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  # Verifies the following
  #   - User can not post unless logged in as an designer.
  #   - The information entered on the form is processed correctly.
  #
  ######################################################################
  #
  def test_post

    set_user(users(:scott_g).id, 'Designer')
    mx234a_pre_artwork = design_reviews(:mx234a_pre_artwork)

    # Verify the state before posting.
    assert_equal(ReviewStatus.find_by_name('Not Started').id,
                 mx234a_pre_artwork.review_status_id)
    assert_equal(0, mx234a_pre_artwork.posting_count)

    mx234a_pre_art_results = DesignReviewResult.find_all_by_design_review_id(
                               mx234a_pre_artwork.id)
    assert_equal(14, mx234a_pre_art_results.size)
    for review_result in mx234a_pre_art_results
      assert_equal('None', review_result.result)
    end
    comments = DesignReviewComment.find_all_by_design_review_id(mx234a_pre_artwork.id)
    assert_equal(0, comments.size)
                 
    post(:post,
         :design_review   => {:id => mx234a_pre_artwork.id},
         :board_reviewers => {'7'  => '7101',
                              '8'  => '7150',
                              '5'  => '7001',
                              '15' => '7400',
                              '10' => '7251',
                              '11' => '7300',
                              '12' => '4001',
                              '14' => '4000',
                              '16' => '7451',
                              '17' => '7500',
                              '18' => '7550',
                              '9'  => '7200',
                              '6'  => '7050',
                              '13' => '7650'},
         :post_comment    => {:comment => 'Test Comment'})

    design_review_update = DesignReview.find(mx234a_pre_artwork.id)

    # Verify the state after posting.
    assert_equal(ReviewStatus.find_by_name('Not Started').id,
                 mx234a_pre_artwork.review_status_id)
    design_review = DesignReview.find(mx234a_pre_artwork.id)
    assert_equal(1, design_review.posting_count)

    mx234a_pre_art_results = DesignReviewResult.find_all_by_design_review_id(
                               mx234a_pre_artwork.id)
    assert_equal(14, mx234a_pre_art_results.size)
    for review_result in mx234a_pre_art_results
      assert_equal('No Response', review_result.result)
    end
    comments = DesignReviewComment.find_all_by_design_review_id(mx234a_pre_artwork.id)
    assert_equal(1, comments.size)
    dr_comment = comments.pop
    assert_equal('Test Comment',     dr_comment.comment)
    assert_equal(users(:scott_g).id, dr_comment.user_id)

    
  end


  ######################################################################
  #
  # test_repost_review
  #
  # Description:
  # This method does the functional testing of the repost_review method
  # from the Design Review class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  # Verifies the following
  #   - User can not view unless logged in as an designer.
  #   - The information needed for the display is loaded.
  #
  ######################################################################
  #
  def test_repost_review
    
    mx234a_pre_artwork = design_reviews(:mx234a_pre_artwork)
    pre_art_review = ReviewType.find_by_name('Pre-Artwork')
    
    post(:repost_review,
         :design_review_id => mx234a_pre_artwork.id)

    assert_equal(mx234a_pre_artwork.design.id, assigns(:design).id)
    assert_equal(pre_art_review.id,            assigns(:design_review).review_type_id)

    reviewer_list = assigns(:reviewers)
    assert_equal(14, reviewer_list.size)

    expected_values = [
      {:group          => 'CE-DFT',
       :group_id       => 7,
       :reviewer_count => 2},
      {:group          => 'DFM',
       :group_id       => 8,
       :reviewer_count => 3},
      {:group          => 'HWENG',
       :group_id       => 5,
       :reviewer_count => 4},
      {:group          => 'Library',
       :group_id       => 15,
       :reviewer_count => 2},
      {:group          => 'Mechanical',
       :group_id       => 10,
       :reviewer_count => 2},
      {:group          => 'Mechanical-MFG',
       :group_id       => 11,
       :reviewer_count => 2},
      {:group          => 'PCB Design',
       :group_id       => 12,
       :reviewer_count => 1},
      {:group          => 'PCB Input Gate',
       :group_id       => 14,
       :reviewer_count => 2},
      {:group          => 'PCB Mechanical',
       :group_id       => 16,
       :reviewer_count => 2},
      {:group          => 'Planning',
       :group_id       => 13,
       :reviewer_count => 2},
      {:group          => 'SLM BOM',
       :group_id       => 17,
       :reviewer_count => 1},
      {:group    => 'SLM Vendor',
       :group_id       => 18,
       :reviewer_count => 1},
      {:group          => 'TDE',
       :group_id       => 9,
       :reviewer_count => 2},
      {:group          => 'Valor',
       :group_id       => 6,
       :reviewer_count => 4}
    ]

    for review_group in reviewer_list
      expected_val = expected_values.shift

      assert_equal(expected_val[:group],          review_group[:group])
      assert_equal(expected_val[:group_id],       review_group[:group_id])
      assert_equal(expected_val[:reviewer_count], review_group[:reviewers].size)
    end

  end


  ######################################################################
  #
  # test_repost
  #
  # Description:
  # This method does the functional testing of the repost method
  # from the Design Review class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  # Verifies the following
  #   - User can not post unless logged in as an designer.
  #   - The information entered on the form is processed correctly.
  #
  ######################################################################
  #
  def test_repost
    
    set_user(users(:scott_g).id, 'Designer')
    mx234a_pre_artwork = design_reviews(:mx234a_pre_artwork)

    # Verify the state before posting.
    assert_equal(ReviewStatus.find_by_name('Not Started').id,
                 mx234a_pre_artwork.review_status_id)
    assert_equal(0, mx234a_pre_artwork.posting_count)

    mx234a_pre_art_results = DesignReviewResult.find_all_by_design_review_id(
                               mx234a_pre_artwork.id)
    assert_equal(14, mx234a_pre_art_results.size)
    for review_result in mx234a_pre_art_results
      assert_equal('None', review_result.result)
    end
    comments = DesignReviewComment.find_all_by_design_review_id(mx234a_pre_artwork.id)
    assert_equal(0, comments.size)
                 
    post(:post,
         :design_review   => {:id => mx234a_pre_artwork.id},
         :board_reviewers => {'7'  => '7101',
                              '8'  => '7150',
                              '5'  => '7001',
                              '15' => '7400',
                              '10' => '7251',
                              '11' => '7300',
                              '12' => '4001',
                              '14' => '4000',
                              '16' => '7451',
                              '17' => '7500',
                              '18' => '7550',
                              '9'  => '7200',
                              '6'  => '7050',
                              '13' => '7650'},
         :post_comment    => {:comment => 'Test Comment'})

    design_review_update = DesignReview.find(mx234a_pre_artwork.id)

    # Verify the state after posting.
    assert_equal(ReviewStatus.find_by_name('Not Started').id,
                 mx234a_pre_artwork.review_status_id)
    design_review = DesignReview.find(mx234a_pre_artwork.id)
    assert_equal(1, design_review.posting_count)

    mx234a_pre_art_results = DesignReviewResult.find_all_by_design_review_id(
                               mx234a_pre_artwork.id)
    assert_equal(14, mx234a_pre_art_results.size)
    for review_result in mx234a_pre_art_results
      assert_equal('No Response', review_result.result)
    end
    comments = DesignReviewComment.find_all_by_design_review_id(mx234a_pre_artwork.id)
    assert_equal(1, comments.size)
    dr_comment = comments.pop
    assert_equal('Test Comment',     dr_comment.comment)
    assert_equal(users(:scott_g).id, dr_comment.user_id)

    post(:repost,
         :design_review   => {:id => mx234a_pre_artwork.id},
         :board_reviewers => {'7'  => '7101',
                              '8'  => '7150',
                              '5'  => '7001',
                              '15' => '7400',
                              '10' => '7251',
                              '11' => '7300',
                              '12' => '4001',
                              '14' => '4000',
                              '16' => '7451',
                              '17' => '7500',
                              '18' => '7550',
                              '9'  => '7200',
                              '6'  => '7050',
                              '13' => '7650'},
         :post_comment    => {:comment => 'Test Comment for the repost'})


    design_review_update = DesignReview.find(mx234a_pre_artwork.id)

    # Verify the state after posting.
    assert_equal(ReviewStatus.find_by_name('Not Started').id,
                 mx234a_pre_artwork.review_status_id)
    design_review = DesignReview.find(mx234a_pre_artwork.id)
    assert_equal(2, design_review.posting_count)

    mx234a_pre_art_results = DesignReviewResult.find_all_by_design_review_id(
                               mx234a_pre_artwork.id)
    assert_equal(14, mx234a_pre_art_results.size)
    for review_result in mx234a_pre_art_results
      assert_equal('No Response', review_result.result)
    end
    comments = DesignReviewComment.find_all_by_design_review_id(mx234a_pre_artwork.id)
    assert_equal(2,                             comments.size)
    assert_equal('Test Comment',                comments.shift.comment)
    assert_equal('Test Comment for the repost', comments.shift.comment)
    assert_equal(users(:scott_g).id,            dr_comment.user_id)

  end


  ######################################################################
  #
  # test_add_comment
  #
  # Description:
  # This method does the functional testing of the add_comment method
  # from the Design Review class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  # Verifies the following
  #   - The information entered on the form is processed correctly.
  #
  ######################################################################
  #
  def test_add_comment
    
    set_user(users(:scott_g).id, 'Designer')
    mx234a_pre_artwork = design_reviews(:mx234a_pre_artwork)

    comments = DesignReviewComment.find_all_by_design_review_id(
                 mx234a_pre_artwork.id)
    assert_equal(0, comments.size)

    post(:add_comment,
         :post_comment  => {:comment => ''},
         :design_review => {:id      =>  mx234a_pre_artwork.id})

    comments = DesignReviewComment.find_all_by_design_review_id(
                 mx234a_pre_artwork.id)
    assert_equal(0, comments.size)

    post(:add_comment,
         :post_comment  => {:comment => 'First Comment!'},
         :design_review => {:id      =>  mx234a_pre_artwork.id})

    comments = DesignReviewComment.find_all_by_design_review_id(
                 mx234a_pre_artwork.id)
    assert_equal(1, comments.size)
    assert_equal('First Comment!', comments.shift.comment)

    post(:add_comment,
         :post_comment  => {:comment => 'Second Comment!'},
         :design_review => {:id      =>  mx234a_pre_artwork.id})

    comments = DesignReviewComment.find_all_by_design_review_id(
                 mx234a_pre_artwork.id)
    assert_equal(2, comments.size)
    assert_equal('First Comment!',  comments.shift.comment)
    assert_equal('Second Comment!', comments.shift.comment)

  end


  ######################################################################
  #
  # test_change_design_center
  #
  # Description:
  # This method does the functional testing of the change_design_center
  # method from the Design Review class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  # Verifies the following
  #   - User can not view unless logged in as an designer.
  #   - The information needed for the display is loaded.
  #
  ######################################################################
  #
  def test_change_design_center

    mx234a_pre_artwork = design_reviews(:mx234a_pre_artwork)
    post(:change_design_center,
         :design_review_id  =>  mx234a_pre_artwork.id)

    assert_equal(2,                     assigns(:design_centers).size)
    assert_equal(mx234a_pre_artwork.id, assigns(:design_review).id)
         
  end


  ######################################################################
  #
  # test_update_design_center
  #
  # Description:
  # This method does the functional testing of the add_comment method
  # from the Design Review class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  # Verifies the following
  #   - User can not update unless logged in as an designer.
  #   - The information entered on the form is processed correctly.
  #
  ######################################################################
  #
  def test_update_design_center

    mx234a_pre_artwork = design_reviews(:mx234a_pre_artwork)
    boston_dc          = design_centers(:boston_harrison)
    fridley_dc         = design_centers(:fridley)

    mx234a = DesignReview.find(mx234a_pre_artwork.id)
    assert_equal(boston_dc.id, mx234a.design_center.id)

    post(:update_design_center,
         :design_review  => {:id => mx234a_pre_artwork.id},
         :design_center  => {:location => fridley_dc.id})

    mx234a = DesignReview.find(mx234a_pre_artwork.id)
    assert_equal(fridley_dc.id, mx234a.design_center.id)
    assert_equal('The design center has been updated.', flash['notice'])
    assert_redirected_to(:action => :designer_view,
                         :id     => mx234a.id)

  end


  ######################################################################
  #
  # test_review_attachments
  #
  # Description:
  # This method does the functional testing of the review_attachments
  # method from the Design Review class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  # Verifies the following
  #   - The information needed for the display is loaded.
  #
  ######################################################################
  #
  def ntest_review_attachments
    assert true
    print('?')
  end


  ######################################################################
  #
  # test_update_documents
  #
  # Description:
  # This method does the functional testing of the update_documents
  # method from the Design Review class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  # Verifies the following
  #   - The user in logged in.
  #   - The information needed for the display is loaded.
  #
  ######################################################################
  def ntest_update_documents
    assert true
    print('?')
  end


  #
  ######################################################################
  #
  # test_save_update
  #
  # Description:
  # This method does the functional testing of the save_update method
  # from the Design Review class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  # Verifies the following
  #   - User can not update unless logged in
  #   - The information entered on the form is processed correctly.
  #
  ######################################################################
  #
  def ntest_save_update
    assert true
    print('?')
  end


  def ntest_add_attachment
    assert true
    print('?')
  end


  def ntest_save_attachment
    assert true
    print('?')
  end


  def ntest_get_attachment
    assert true
    print('?')
  end


  def ntest_list_obsolete
    assert true
    print('?')
  end


  
  def ntest_review_mail_list
    assert true
    print('?')
  end


  def ntest_add_to_list
    assert true
    print('?')
  end


  def ntest_remove_from_list
    assert true
    print('?')
  end


  def ntest_review_results
    assert true
    print('?')
  end


  def ntest_post_results
    assert true
    print('?')
  end


  def ntest_confirm_rejection
    assert true
    print('?')
  end


  def ntest_reassign_reviewer
    assert true
    print('?')
  end


  def ntest_update_review_assignments
    assert true
    dump_design
  end


  def dump_design

    print "\n************** DUMP DESIGN *****************\n"
  end


end
