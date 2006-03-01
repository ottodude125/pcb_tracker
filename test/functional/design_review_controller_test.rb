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
           :design_review_documents,
           :design_review_results,
           :design_reviews,
           :designs,
           :documents,
           :document_types,
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
  def test_review_attachments

    set_user(users(:scott_g).id, 'Designer')

    mx234a = design_reviews(:mx234a_pre_artwork)
    post(:review_attachments,
         :design_review_id => mx234a.id)

    assert_equal(mx234a.id,           assigns(:design_review).id)
    assert_equal(designs(:mx234a).id, assigns(:design_review).design_id)

    documents = assigns(:documents)
    assert_equal(4, documents.size)

    expected_documents = [
      {:document_type_id => 1,
       :document_name    => 'mx234a_stackup.doc',
       :creator          => 'Cathy McLaren'},
      {:document_type_id => 3,
       :document_name    => 'go_pirates.xls',
       :creator          => 'Scott Glover'},
      {:document_type_id => 3,
       :document_name    => 'go_red_sox.xls',
       :creator          => 'Scott Glover'},
      {:document_type_id => 4,
       :document_name    => 'eng_notes.xls',
       :creator          => 'Lee Schaff'}
    ]

    for document in documents
      expected_doc = expected_documents.pop
      assert_equal(expected_doc[:document_type_id], document["document_type_id"])
      assert_equal(expected_doc[:document_name],    document.document.name)
      assert_equal(expected_doc[:creator],          
                   User.find(document.document.created_by).name)
    end
    
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
  def test_update_documents

    mx234a           = design_reviews(:mx234a_pre_artwork)
    mx234a_eng_notes = design_review_documents(:mx234a_eng_notes_doc)
  
    set_user(users(:scott_g).id, 'Designer')
    post(:update_documents,
         :design_review_id => mx234a.id,
         :document_id      => mx234a_eng_notes.id)

    assert_equal(0,                         assigns(:drd).document_id)
    assert_equal(mx234a.id,                 assigns(:design_review).id)
    assert_equal(mx234a_eng_notes.id,       assigns(:existing_drd).id)
    assert_equal(document_types(:eng_inst), assigns(:document_type))
    
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


  #
  ######################################################################
  #
  # test_post_results
  #
  # Description:
  # This method does the functional testing of the post results and
  # reviewer_results methods from the Design Review class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def test_post_results

    expected_results = {
      '7'  => "No Response",
      '8'  => "No Response",
      '5'  => "No Response",
      '15' => "No Response",
      '10' => "No Response",
      '11' => "No Response",
      '14' => "No Response",
      '16' => "No Response",
      '13' => "No Response",
      '17' => "No Response",
      '18' => "No Response",
      '9'  => "No Response",
      '6'  => "No Response",
      '12' => "No Response"
    }

    in_review      = ReviewStatus.find_by_name("In Review")
    pending_repost = ReviewStatus.find_by_name("Pending Repost")
    reviewer_result_list= [
      # 1) Espo - CE-DFT Reviewer
      {:user_id   => users(:espo).id,
       :role_id   => 7,
       :comment   => 'This is good!',
       :result    => 'APPROVED',
       :review_result_id => '1',
       :role_id_tag      => 'role_id_7',
       :expected_results => {
         :comments_count   => 1,
         :review_status_id => in_review.id
       }
      },
      # 2) Heng Kit Too - DFM Reviewer
      {:user_id   => users(:heng_k).id,
       :role_id   => 8,
       :comment   => 'This is good enough to waive.',
       :result    => 'WAIVED',
       :review_result_id => '2',
       :role_id_tag      => ':role_id_8',
       :expected_results => {
         :comments_count => 2,
         :review_status_id => in_review.id
       }
      },
      # 3) Dave Macioce - Library Reviewer
      {:user_id   => users(:dave_m).id,
       :role_id   => 15,
       :comment   => 'Yankees Suck!!!',
       :result    => 'REJECTED',
       :review_result_id => '4',
       :role_id_tag      => ':role_id_15',
       :expected_results => {
         :comments_count => 3,
         :review_status_id => pending_repost.id
       }
      },
      # 4) Lee Shaff- HW Reviewer
      {:user_id   => users(:lee_s).id,
       :role_id   => 5,
       :comment   => 'No Comment',
       :result    => 'APPROVED',
       :review_result_id => '3',
       :role_id_tag      => ':role_id_5',
       :expected_results => {
         :comments_count => 4,
         :review_status_id => in_review.id
       }
      },
      # 5) Dave Macioce - Library Reviewer
      {:user_id   => users(:dave_m).id,
       :role_id   => 15,
       :comment   => '',
       :result    => 'APPROVED',
       :review_result_id => '4',
       :role_id_tag      => ':role_id_15',
       :expected_results => {
         :comments_count => 4,
         :review_status_id => in_review.id
       }
      },
      # 6) Espo - CE-DFT Reviewer
      {:user_id   => users(:espo).id,
       :role_id   => 7,
       :comment   => 'This is good!',
       :result    => 'APPROVED',
       :review_result_id => '1',
       :role_id_tag      => 'role_id_7',
       :expected_results => {
         :comments_count => 5,
         :review_status_id => in_review.id
       }
      },
      # 7) Tom Flak - Mehanical
      {:user_id   => users(:tom_f).id,
       :role_id   => 10,
       :comment   => 'This is good!',
       :result    => 'APPROVED',
       :review_result_id => '5',
       :role_id_tag      => 'role_id_10',
       :expected_results => {
         :comments_count => 6,
         :review_status_id => in_review.id
       }
      },
      # 8) Anthony Gentile - Mechanical MFG
      {:user_id   => users(:anthony_g).id,
       :role_id   => 11,
       :comment   => '',
       :result    => 'APPROVED',
       :review_result_id => '6',
       :role_id_tag      => 'role_id_11',
       :expected_results => {
         :comments_count => 6,
         :review_status_id => in_review.id
       }
      },
      # 9) Cathy McLaren - PCB Input Gate
      {:user_id   => users(:cathy_m).id,
       :role_id   => 14,
       :comment   => 'I always have something to say.',
       :result    => 'APPROVED',
       :review_result_id => '7',
       :role_id_tag      => 'role_id_14',
       :expected_results => {
         :comments_count => 7,
         :review_status_id => in_review.id
       }
      },
      # 10) John Godin - PCB Mehanical
      {:user_id   => users(:john_g).id,
       :role_id   => 16,
       :comment   => '',
       :result    => 'APPROVED',
       :review_result_id => '8',
       :role_id_tag      => 'role_id_16',
       :expected_results => {
         :comments_count => 7,
         :review_status_id => in_review.id
       }
      },
      # 11) Matt Disanzo - Planning
      {:user_id   => users(:matt_d).id,
       :role_id   => 13,
       :comment   => 'Testing.',
       :result    => 'APPROVED',
       :review_result_id => '9',
       :role_id_tag      => 'role_id_13',
       :expected_results => {
         :comments_count => 8,
         :review_status_id => in_review.id
       }
      },
      # 12) Arthur Davis - SLM BOM
      {:user_id   => users(:art_d).id,
       :role_id   => 17,
       :comment   => '',
       :result    => 'APPROVED',
       :review_result_id => '10',
       :role_id_tag      => 'role_id_17',
       :expected_results => {
         :comments_count => 8,
         :review_status_id => in_review.id
       }
      },
      # 13) Dan Gough - SLM Vendor
      {:user_id   => users(:dan_g).id,
       :role_id   => 18,
       :comment   => '',
       :result    => 'APPROVED',
       :review_result_id => '11',
       :role_id_tag      => 'role_id_18',
       :expected_results => {
         :comments_count => 8,
         :review_status_id => in_review.id
       }
      },
      # 14) Rich Ahamed - TDE
      {:user_id   => users(:rich_a).id,
       :role_id   => 9,
       :comment   => '',
       :result    => 'APPROVED',
       :review_result_id => '12',
       :role_id_tag      => 'role_id_9',
       :expected_results => {
         :comments_count => 8,
         :review_status_id => in_review.id
       }
      },
      # 15) Lisa Austin - Valor
      {:user_id   => users(:lisa_a).id,
       :role_id   => 6,
       :comment   => '',
       :result    => 'APPROVED',
       :review_result_id => '13',
       :role_id_tag      => 'role_id_6',
       :expected_results => {
         :comments_count => 8,
         :review_status_id => in_review.id
       }
      },

     ]

    mx234a = design_reviews(:mx234a_pre_artwork)

    update_mx234a = DesignReview.find(mx234a.id)
    update_mx234a.review_status_id = ReviewStatus.find_by_name('In Review').id
    update_mx234a.update

    mx234a_review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)
    for mx234a_review_result in mx234a_review_results
      mx234a_review_result.result = 'No Response'
      mx234a_review_result.update
    end

    mx234a_review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)

    assert_equal(14, mx234a_review_results.size)
    assert_equal(0, 
                 DesignReviewComment.find_all_by_design_review_id(mx234a.id).size)
    for review_result in mx234a_review_results
      assert_equal("No Response", review_result.result)
    end

    print "\n"
    repost = false
    for reviewer_result in reviewer_result_list

      if repost
        update_mx234a = DesignReview.find(mx234a.id)
        update_mx234a.review_status_id = ReviewStatus.find_by_name('In Review').id
        update_mx234a.update
      end
      
      rev = User.find(reviewer_result[:user_id]).name
      print "\nProcessing #{rev} - #{reviewer_result[:result]}"
      set_user(reviewer_result[:user_id], Role.find(reviewer_result[:role_id]))

      post(:reviewer_results,
           :post_comment  => {"comment"                          => reviewer_result[:comment]},
           reviewer_result[:role_id_tag] => {reviewer_result[:review_result_id] => reviewer_result[:result]},
           :design_review => {"id"                               => mx234a.id})

      expected_results[reviewer_result[:role_id].to_s] = reviewer_result[:result]

      if reviewer_result[:result] != 'REJECTED'
        assert_redirected_to(:action => :post_results)
      else
        expected_results.each { |k,v| 
          expected_results[k] = 'WITHDRAWN' if v == 'APPROVED'
        }
        assert_redirected_to(:action => :confirm_rejection)
        post(:confirm_rejection)
        repost = true
      end

      post(:post_results)

      assert_equal(reviewer_result[:expected_results][:comments_count], 
                   DesignReviewComment.find_all_by_design_review_id(mx234a.id).size)

      review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)

      for review_result in review_results
        assert_equal(expected_results[review_result.role_id.to_s],
                     review_result.result)
      end

      pre_art_design_review = DesignReview.find(mx234a.id)
      assert_equal(reviewer_result[:expected_results][:review_status_id],
                   pre_art_design_review.review_status_id)
    end
    print "\n"

    #Verify the existing priority and designer.
    mx234a_pre_art_dr = DesignReview.find(mx234a.id)
    mx234a_design     = mx234a_pre_art_dr.design
    high              = Priority.find_by_name('High')
    low               = Priority.find_by_name('Low')
    bob_g             = User.find_by_last_name("Goldin")
    scott_g           = User.find_by_last_name("Glover")

    assert_equal(high.id,  mx234a_design.priority_id)
    assert_equal(bob_g.id, mx234a_design.designer_id)

    for mx234a_dr in mx234a_design.design_reviews
      assert_equal(high.id,  mx234a_dr.priority_id)
      assert_equal(bob_g.id, mx234a_dr.designer_id)
    end

    assert_equal(ReviewType.find_by_name("Pre-Artwork").id,
                 mx234a_design.phase_id)

                 # Handle special processing cases
    set_user(users(:jim_l).id, Role.find(12))
    post(:reviewer_results,
         :post_comment  => {"comment" => 'Absolutely!'},
         :role_id_12    => {'100'     => reviewer_result[:result]},
         :design_review => {"id"      => mx234a.id},
         :designer      => {:id       => scott_g.id},
         :priority      => {:id       => low.id})
    post(:post_results)

    mx234a_pre_art_dr = DesignReview.find(mx234a.id)
    mx234a_design     = Design.find(mx234a_pre_art_dr.design_id)

    assert_equal(low.id,     mx234a_design.priority_id)
    assert_equal(scott_g.id, mx234a_design.designer_id)

    for mx234a_dr in mx234a_design.design_reviews
      assert_equal(low.name, Priority.find(mx234a_dr.priority_id).name)
      case ReviewType.find(mx234a_dr.review_type_id).name
      when 'Pre-Artwork'
        assert_equal(bob_g.name, User.find(mx234a_dr.designer_id).name)
      when 'Release'
        assert_equal(bob_g.name, User.find(mx234a_dr.designer_id).name)
      else
        assert_equal(scott_g.name, User.find(mx234a_dr.designer_id).name)
      end
    end

    assert_equal(ReviewType.find_by_name("Placement").id,
                 mx234a_design.phase_id)
    assert_equal('Review Completed', mx234a_pre_art_dr.review_status.name)

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
