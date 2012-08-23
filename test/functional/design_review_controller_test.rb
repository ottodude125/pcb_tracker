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

require File.expand_path( "../../test_helper", __FILE__ )
require 'design_review_controller'

# Re-raise errors caught by the controller.
class DesignReviewController; def rescue_action(e) raise e end; end

class DesignReviewControllerTest < ActionController::TestCase
  
  def setup
    
    @controller = DesignReviewController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @emails     = ActionMailer::Base.deliveries
    @emails.clear
    
    @review_types = {}
    ReviewType.find(:all).each { |rt| @review_types[rt.name] = rt }
    
    @review_complete = ReviewStatus.find_by_name("Review Completed")
    @in_review       = ReviewStatus.find_by_name("In Review")
    @pending_repost  = ReviewStatus.find_by_name("Pending Repost")
    @on_hold         = ReviewStatus.find_by_name("Review On-Hold")
    
    # Retrieve the user records for the reviewers.
    @espo      = users(:espo)
    @heng_k    = users(:heng_k)
    @lee_s     = users(:lee_s)
    @dave_m    = users(:dave_m)
    @tom_f     = users(:tom_f)
    @anthony_g = users(:anthony_g)
    @cathy_m   = users(:cathy_m)
    @john_g    = users(:john_g)
    @matt_d    = users(:matt_d)
    @art_d     = users(:art_d)
    @jim_l     = users(:jim_l)
    @dan_g     = users(:dan_g)
    @rich_a    = users(:rich_a)
    @lisa_a    = users(:lisa_a)
    @eileen_c  = users(:eileen_c)
    @bob_g     = users(:bob_g)
    @scott_g   = users(:scott_g)
    
    # Pre-load criticalities
    @low_priority  = priorities(:low)
    @high_priority = priorities(:high)
    
    # Pre-load roles
    @ce_dft         = roles(:ce_dft)
    @dfm            = roles(:dfm)
    @hweng          = roles(:hweng)
    @library        = roles(:library)
    @mechanical     = roles(:mechanical)
    @mechanical_mfg = roles(:mechanical_manufacturing)
    @pcb_design     = roles(:pcb_design)
    @pcb_input_gate = roles(:pcb_input_gate)
    @pcb_mechanical = roles(:pcb_mechanical)
    @planning       = roles(:planning)
    @slm_bom        = roles(:slm_bom)
    @slm_vendor     = roles(:slm_vendor)
    @tde            = roles(:tde)
    @valor          = roles(:valor)
    
    # Pre-load the design centers
    @nr      = design_centers(:nr)
    @fridley = design_centers(:fridley)
    @oregon  = design_centers(:oregon)
    
  end

  fixtures(:audit_comments,
           :audit_teammates,
           :audits,
           :board_design_entries,
           :board_design_entry_users,
           :board_reviewers,
           :boards,
           :boards_fab_houses,
           :boards_users,
           :checklists,
           :checks,
           :design_centers,
           :design_checks,
           :design_directories,
           :design_review_comments,
           :design_review_documents,
           :design_review_results,
           :design_reviews,
           :design_updates,
           :designs,
           :designs_fab_houses,
           :divisions,
           :document_types,
           :documents,
           :fab_houses,
           :ftp_notifications,
           :ipd_posts,
           :ipd_posts_users,
           :locations,
           :part_numbers,
           :platforms,
           :prefixes,
           :priorities,
           :product_types,
           :projects,
           :review_groups,
           :review_statuses,
           :review_types,
           :review_types_roles,
           :revisions,
           :roles,
           :roles_users,
           :sections,
           :subsections,
           :users)
           

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
    
    get(:view, { :id => mx234a_pre_art.id }, {})
    assert_response(:success)

    get(:view, { :id => mx234a_pre_art.id }, {})
    assert_equal(mx234a_pre_art.id, assigns(:design_review).id)
    assert_equal(mx234a.id,         assigns(:design_review).design.id)
    assert_equal(14,                assigns(:review_results).size)
    assert_equal(4,                 assigns(:design_review).design_review_comments.size)
    
    get(:view, {}, {})
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    #assert_equal('No ID was provided - unable to access the design review',
    #             flash['notice'])

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
    mx234a_pre_art = design_reviews(:mx234a_pre_artwork)
    mx234a         = designs(:mx234a)
    
    get(:view, {:id => mx234a_pre_art.id}, cathy_admin_session)
    assert_response(:success)
    assert_equal(mx234a_pre_art.id, assigns(:design_review).id)
    assert_equal(mx234a.id,         assigns(:design_review).design.id)
    assert_equal(14,                assigns(:review_results).size)
    assert_equal(4,                 assigns(:design_review).design_review_comments.size)

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
  def test_nodesigner_view
    
    # Verify that the designer view is called when the user is 
    # logged in as a designer.
    mx234a_pre_art = design_reviews(:mx234a_pre_artwork)
    mx234a         = designs(:mx234a)
    
    get(:view, { :id => mx234a_pre_art.id }, scott_designer_session)
    assert_response(:success)
    assert_equal(mx234a_pre_art.id, assigns(:design_review).id)
    assert_equal(mx234a.id,         assigns(:design_review).design.id)
    assert_equal(14,                assigns(:review_results).size)
    assert_equal(4,                 assigns(:design_review).design_review_comments.size)
    
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
    mx234a_pre_art = design_reviews(:mx234a_pre_artwork)
    mx234a         = designs(:mx234a)
    
    get(:view,{ :id => mx234a_pre_art.id}, ted_dft_session)
    assert_response(:success)
    assert_equal(mx234a_pre_art.id, assigns(:design_review).id)
    assert_equal(mx234a.id,         assigns(:design_review).design.id)
    assert_equal(14,                assigns(:review_results).size)
    assert_equal(4,                 assigns(:design_review).design_review_comments.size)
    assert_equal(nil,               assigns(:designers))
    assert_equal(nil,               assigns(:priorities))
    assert_equal(nil,               assigns(:fab_houses))
    
    # Verify information for PCB during a pre-artwork review.
    get(:view, {:id => mx234a_pre_art.id}, jim_pcb_design_session)
    assert_response(:success)
    assert_equal(mx234a_pre_art.id, assigns(:design_review).id)
    assert_equal(mx234a.id,         assigns(:design_review).design.id)
    assert_equal(14,                assigns(:review_results).size)
    assert_equal(4,                 assigns(:design_review).design_review_comments.size)
    assert_equal(5,                 assigns(:designers).size)
    assert_equal(3,                 assigns(:priorities).size)
    assert_equal(nil,               assigns(:fab_houses))
    
    # Verify information for SLM Vendor during a pre-artwork review.
    get(:view, { :id => mx234a_pre_art.id }, dan_slm_vendor_session)
    assert_equal(mx234a_pre_art.id, assigns(:design_review).id)
    assert_equal(mx234a.id,         assigns(:design_review).design.id)
    assert_equal(14,                assigns(:review_results).size)
    assert_equal(4,                 assigns(:design_review).design_review_comments.size)
    assert_equal(nil,               assigns(:designers))
    assert_equal(nil,               assigns(:priorities))

    fab_houses = assigns(:fab_houses)
    assert_equal(8, fab_houses.size)

    selected_fab_houses = %w(IBM Merix OPC)
    for fab_house in fab_houses
      assert_equal(selected_fab_houses.include?(fab_house.name), 
                   fab_house[:selected])
    end
    
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
    mx234a_pre_art = design_reviews(:mx234a_pre_artwork)
    mx234a         = designs(:mx234a)

    get(:view, { :id => mx234a_pre_art.id }, jim_manager_session)
    assert_equal(mx234a_pre_art.id, assigns(:design_review).id)
    assert_equal(mx234a.id,         assigns(:design_review).design.id)
    assert_equal(14,                assigns(:review_results).size)
    assert_equal(4,                 assigns(:design_review).design_review_comments.size)
    
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

    designer_session = cathy_designer_session
    
    mx234a         = designs(:mx234a)
    pre_art_review = ReviewType.get_pre_artwork
    
    get(:post_review,
        { :combine_placement_routing => '0',
          :design_id                 => mx234a.id,
          :review_type_id            => pre_art_review.id },
        designer_session)
      
    assert_equal(mx234a.id,         assigns(:design_review).design.id)
    assert_equal(pre_art_review.id, assigns(:design_review).review_type_id)

    expected_values = [ set_reviewer(@dfm,            3, @heng_k),
                        set_reviewer(@ce_dft,         2, @espo),
                        set_reviewer(@library,        2, @dave_m),
                        set_reviewer(@hweng,          4, @lee_s),
                        set_reviewer(@mechanical,     2, @tom_f),
                        set_reviewer(@mechanical_mfg, 2, @anthony_g),
                        set_reviewer(@planning,       2, @matt_d),
                        set_reviewer(@pcb_input_gate, 2, @cathy_m),
                        set_reviewer(@pcb_design,     1, @jim_l),
                        set_reviewer(@pcb_mechanical, 2, @john_g),
                        set_reviewer(@slm_bom,        1, @art_d),
                        set_reviewer(@slm_vendor,     1, @dan_g),
                        set_reviewer(@tde,            2, @rich_a),
                        set_reviewer(@valor,          4, @lisa_a) ]

    reviewer_list = assigns(:reviewers)
    assert_equal(expected_values.size, reviewer_list.size)

    reviewer_list.each do |review_group|
      expected_val = expected_values.shift
      assert_equal(expected_val[:group].display_name, review_group.role.display_name)
      assert_equal(expected_val[:group].id,           review_group.role_id)
      assert_equal(expected_val[:reviewer_count],     review_group.role.active_users.size)
      assert_equal(expected_val[:reviewer].id,        review_group.reviewer_id)
    end

    pre_art_design_review = DesignReview.find(:first,
                                              :conditions => "design_id='#{mx234a.id}' and " +
                                                             "review_type_id='#{pre_art_review.id}'")
    assert_equal(0, pre_art_design_review.review_type_id_2)

    
    placement_review = ReviewType.get_placement
    routing_review   = ReviewType.get_routing
    
    get(:post_review,
        { :combine_placement_routing => '1',
          :design_id                 => mx234a.id,
          :review_type_id            => placement_review.id },
        designer_session)

    assert_equal(mx234a.id,           assigns(:design_review).design.id)
    assert_equal(placement_review.id, assigns(:design_review).review_type_id)

    expected_values = [ set_reviewer(@dfm,            3, @heng_k),
                        set_reviewer(@ce_dft,         2, @espo),
                        set_reviewer(@hweng,          4, @lee_s),
                        set_reviewer(@mechanical,     2, @tom_f),
                        set_reviewer(@mechanical_mfg, 2, @anthony_g),
                        set_reviewer(@tde,            2, @rich_a) ]

    reviewer_list = assigns(:reviewers)
    assert_equal(expected_values.size, reviewer_list.size)

    reviewer_list.each do |review_group|
      expected_val = expected_values.shift
      assert_equal(expected_val[:group].display_name, review_group.role.display_name)
      assert_equal(expected_val[:group].id,           review_group.role_id)
      assert_equal(expected_val[:reviewer_count],     review_group.role.active_users.size)
      assert_equal(expected_val[:reviewer].id,        review_group.reviewer_id)
    end

    placement_design_review = DesignReview.find(:first,
                                                :conditions => "design_id='#{mx234a.id}' and " +
                                                               "review_type_id='#{placement_review.id}'")
    assert_equal(routing_review.id, placement_design_review.review_type_id_2)
    

    final_review_type = ReviewType.get_final
    
    get(:post_review,
        { :combine_placement_routing => '0',
          :design_id                 => mx234a.id,
          :review_type_id            => final_review_type.id },
        designer_session)

    assert_equal(mx234a.id,            assigns(:design_review).design.id)
    assert_equal(final_review_type.id, assigns(:design_review).review_type_id)

    expected_values = [ set_reviewer(@dfm,            3, @heng_k),
                        set_reviewer(@ce_dft,         2, @espo),
                        set_reviewer(@hweng,          4, @lee_s),
                        set_reviewer(@mechanical,     2, @tom_f),
                        set_reviewer(@mechanical_mfg, 2, @anthony_g),
                        set_reviewer(@planning,       2, @matt_d),
                        set_reviewer(@pcb_design,     1, @jim_l),
                        set_reviewer(@tde,            2, @rich_a),
                        set_reviewer(@valor,          4, @lisa_a) ]

    reviewer_list = assigns(:reviewers)
    assert_equal(expected_values.size, reviewer_list.size)

    reviewer_list.each do |review_group|
      expected_val = expected_values.shift
      assert_equal(expected_val[:group].display_name, review_group.role.display_name)
      assert_equal(expected_val[:group].id,           review_group.role_id)
      assert_equal(expected_val[:reviewer_count],     review_group.role.active_users.size)
      assert_equal(expected_val[:reviewer].id,        review_group.reviewer_id)
    end

    pre_art_design_review = DesignReview.find(:first,
                                              :conditions => "design_id='#{mx234a.id}' and " +
                                                             "review_type_id='#{pre_art_review.id}'")
    assert_equal(0, pre_art_design_review.review_type_id_2)

  end


  ######################################################################
  #
  # test_post
  #
  # Description:
  # This method does the functional testing of the post method
  # from the Design Review class
  #
  # Additional information:
  # Verifies the following
  #   - User can not post unless logged in as an designer.
  #   - The information entered on the form is processed correctly.
  #
  ######################################################################
  #
  def test_post

    review_status_list = ReviewStatus.find(:all)
    statuses = {}
    for review_status in review_status_list
      statuses[review_status.name] = review_status.id
    end

    admin_email = users(:patrice_m).email

    designer_session = scott_designer_session
    pre_artwork_dr = design_reviews(:mx234c_pre_artwork)

    # Verify the state before posting.
    assert_equal(statuses['Not Started'], 
                 pre_artwork_dr.review_status_id)
    assert_equal(0, pre_artwork_dr.posting_count)

    assert_equal(14, pre_artwork_dr.design_review_results.size)
    for review_result in pre_artwork_dr.design_review_results
      assert_equal('No Response', review_result.result)
    end

    assert_equal(0, pre_artwork_dr.design_review_comments.size)
                 
    put(:post,
        { :design_review   => {:id => pre_artwork_dr.id},
          :board_reviewers => { '7'  => '7101',     '8' => '7150',
                                '5'  => '7001',    '15' => '7400',
                                '10' => '7251',    '11' => '7300',
                                '12' => '4001',    '14' => '4000',
                                '16' => '7451',    '17' => '7500',
                                '18' => '7550',     '9' => '7200',
                                '6'  => '7050',    '13' => '7650' }, 
          :post_comment    => { :comment => 'Test Comment' } },
        designer_session)

    pre_artwork_dr.reload
    # Verify the state after posting.
    assert_equal(statuses['In Review'], 
                 pre_artwork_dr.review_status_id)
    assert_equal(1, pre_artwork_dr.posting_count)

    assert_equal(14, pre_artwork_dr.design_review_results.size)
    for review_result in pre_artwork_dr.design_review_results
      assert_equal('No Response', review_result.result)
    end
    
    comments = pre_artwork_dr.design_review_comments
    assert_equal(1, comments.size)
    dr_comment = comments.pop
    assert_equal('Test Comment',     dr_comment.comment)
    assert_equal(users(:scott_g).id, dr_comment.user_id)

    assert_equal(15, @emails.size)
    email = @emails.pop

    assert_equal(14, email.to.size)
    assert_equal('Catalyst/AC/(pcb252_234_c0_q): The Pre-Artwork design review has been posted', 
                 email.subject)
    found_email = email.cc.detect { |addr| addr == admin_email }
    assert_equal(nil, found_email)

    # The rest of the mails are invitations - verify that
    invite_list = []
    while @emails != []
      email = @emails.pop
      assert_equal(1, email.to.size)
      assert_equal("Your login information for the PCB Design Tracker",
                   email.subject)
      invite_list << email
    end
    #invite_list = invite_list.sort_by { |email| email.to.pop }
    for review_result in pre_artwork_dr.design_review_results
      reviewer = User.find(review_result.reviewer_id)
      assert(invite_list.detect { |email| email.to.pop == reviewer.email})
    end


    mx234a_final = design_reviews(:mx234a_final)

    # Verify the state before posting.
    assert_equal(statuses['Not Started'],
                 mx234a_final.review_status_id)
    assert_equal(0, mx234a_final.posting_count)

    assert_equal(9, mx234a_final.design_review_results.size)
    for review_result in mx234a_final.design_review_results
      assert_equal('No Response', review_result.result)
    end

    assert_equal(0, mx234a_final.design_review_comments.size)
                 
    post(:post,
         { :design_review   => {:id => mx234a_final.id},
           :board_reviewers => { '7' => '7101',    '8' => '7150',
                                 '5' => '7001',   '10' => '7251',
                                '11' => '7300',   '12' => '4001',
                                 '9' => '7200',    '6' => '7050',
                                '13' => '7650' },
           :post_comment    => { :comment => 'Test Comment' } },
         designer_session)

    # Verify the state after posting.
    mx234a_final.reload
    assert_equal(@in_review.id, mx234a_final.review_status_id)

    assert_equal(1, mx234a_final.posting_count)

    assert_equal(9, mx234a_final.design_review_results.size)
    for review_result in mx234a_final.design_review_results
      assert_equal('No Response', review_result.result)
    end
    
    comments = mx234a_final.design_review_comments
    assert_equal(1, comments.size)
    dr_comment = comments.pop
    assert_equal('Test Comment',     dr_comment.comment)
    assert_equal(users(:scott_g).id, dr_comment.user_id)

    email = @emails.pop
    assert_equal(9, email.to.size)
    assert_equal('Catalyst/AC/(pcb252_234_a0_g): The Final design review has been posted', 
                 email.subject)
    found_email = email.cc.detect { |addr| addr == admin_email }
    assert_equal(admin_email, found_email)

  end


  ######################################################################
  #
  # test_repost_review
  #
  # Description:
  # This method does the functional testing of the repost_review method
  # from the Design Review class
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
    pre_art_review     = ReviewType.get_pre_artwork
    
    post(:repost_review,
         { :design_review_id => mx234a_pre_artwork.id },
         cathy_designer_session)

    assert_equal(mx234a_pre_artwork.design.id, assigns(:design_review).design.id)
    assert_equal(pre_art_review.id,            assigns(:design_review).review_type_id)

    reviewer_list = assigns(:reviewers)
    assert_equal(14, reviewer_list.size)

    expected_values = [ set_group('CE-DFM Engineer',          8, 3),
                        set_group('CE-DFT Engineer',          7, 2),
                        set_group('Component Development',   15, 2),
                        set_group('Hardware Engineer (EE)',   5, 4),
                        set_group('Mechanical Engineer',     10, 2),
                        set_group('Mechanical Mfg Engineer', 11, 2),
                        set_group('New Product Planner',     13, 2),
                        set_group('PCB Design Input Gate',   14, 2),
                        set_group('PCB Design Manager',      12, 1),
                        set_group('PCB Mechanical Engineer', 16, 2),
                        set_group('SLM BOM',                 17, 1),
                        set_group('SLM Vendor',              18, 1),
                        set_group('TDE Engineer',             9, 2),
                        set_group('Valor',                    6, 4) ]

    for review_group in reviewer_list
      expected_val = expected_values.shift

      assert_equal(expected_val[:group],          review_group.role.display_name)
      assert_equal(expected_val[:group_id],       review_group.role_id)
      assert_equal(expected_val[:reviewer_count], review_group.role.active_users.size)
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
  # Additional information:
  # Verifies the following
  #   - User can not post unless logged in as an designer.
  #   - The information entered on the form is processed correctly.
  #
  ######################################################################
  #
  def test_repost
    
    designer_session = scott_designer_session
    mx234a_pre_artwork = design_reviews(:mx234a_pre_artwork)

    # Verify the state before posting.
    assert_equal(@in_review.id, mx234a_pre_artwork.review_status_id)
    assert_equal(1, mx234a_pre_artwork.posting_count)

    assert_equal(14, mx234a_pre_artwork.design_review_results.size)
    for review_result in mx234a_pre_artwork.design_review_results
      assert_equal('No Response', review_result.result)
    end

    assert_equal(4, mx234a_pre_artwork.design_review_comments.size)
                 
    post(:post,
         { :design_review   => {:id => mx234a_pre_artwork.id},
           :board_reviewers => {  '7' => '7101',     '8' => '7150',
                                  '5' => '7001',    '15' => '7400',
                                 '10' => '7251',    '11' => '7300',
                                 '12' => '4001',    '14' => '4000',
                                 '16' => '7451',    '17' => '7500',
                                 '18' => '7550',     '9' => '7200',
                                  '6' => '7050',    '13' => '7650' },
           :post_comment    => { :comment => 'Test Comment' } },
         designer_session)

    # Verify the state after posting.
    mx234a_pre_artwork.reload
    assert_equal(@in_review.id, mx234a_pre_artwork.review_status_id)
    assert_equal(1, mx234a_pre_artwork.posting_count)

    assert_equal(14, mx234a_pre_artwork.design_review_results.size)
    for review_result in mx234a_pre_artwork.design_review_results
      assert_equal('No Response', review_result.result)
    end
    comments = mx234a_pre_artwork.design_review_comments
    assert_equal(5, comments.size)
    dr_comment = comments.shift
    assert_equal('Test Comment',     dr_comment.comment)
    assert_equal(users(:scott_g).id, dr_comment.user_id)

    post(:repost,
         { :design_review   => {:id => mx234a_pre_artwork.id},
           :board_reviewers => {  '7' => '7101',     '8' => '7150',
                                  '5' => '7001',    '15' => '7400',
                                 '10' => '7251',    '11' => '7300',
                                 '12' => '4001',    '14' => '4000',
                                 '16' => '7451',    '17' => '7500',
                                 '18' => '7550',     '9' => '7200',
                                  '6' => '7050',    '13' => '7650' },
           :post_comment    => { :comment => 'Test Comment for the repost' } },
         designer_session)


    # Verify the state after posting.
    mx234a_pre_artwork.reload
    assert_equal(@in_review.id, mx234a_pre_artwork.review_status_id)

    assert_equal(2, mx234a_pre_artwork.posting_count)

    assert_equal(14, mx234a_pre_artwork.design_review_results.size)
    for review_result in mx234a_pre_artwork.design_review_results
      assert_equal('No Response', review_result.result)
    end

    comments = mx234a_pre_artwork.design_review_comments.sort_by { |c| c.id }
    
    assert_equal(6,                             comments.size)
    assert_equal('Test Comment',                comments[4].comment)
    assert_equal('Test Comment for the repost', comments[5].comment)
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
  # Additional information:
  # Verifies the following
  #   - The information entered on the form is processed correctly.
  #
  ######################################################################
  #
  def test_add_comment
    
    designer_session = scott_designer_session
    mx234a_pre_artwork = design_reviews(:mx234a_pre_artwork)

    comments = DesignReviewComment.find_all_by_design_review_id(
                 mx234a_pre_artwork.id)
    assert_equal(4, comments.size)

    post(:add_comment,
         { :post_comment  => { :comment => '' },
           :design_review => { :id      =>  mx234a_pre_artwork.id } },
         designer_session)
    comments = DesignReviewComment.find_all_by_design_review_id(
                 mx234a_pre_artwork.id)
    assert_equal(4, comments.size)

    post(:add_comment,
         { :post_comment  => { :comment => 'First Comment!' },
           :design_review => { :id      =>  mx234a_pre_artwork.id } },
         designer_session)
    comments = DesignReviewComment.find_all_by_design_review_id(
                 mx234a_pre_artwork.id)
    assert_equal(5, comments.size)
    assert_equal('First Comment!', comments[4].comment)

    post(:add_comment,
         { :post_comment  => { :comment => 'Second Comment!' },
           :design_review => { :id      =>  mx234a_pre_artwork.id } },
         designer_session)
    comments = DesignReviewComment.find_all_by_design_review_id(
                 mx234a_pre_artwork.id)
    assert_equal(6, comments.size)
    assert_equal('This is comment one',   comments[0].comment)
    assert_equal('This is comment two',   comments[1].comment)
    assert_equal('This is comment three', comments[2].comment)
    assert_equal('This is comment four',  comments[3].comment)
    assert_equal('First Comment!',        comments[4].comment)
    assert_equal('Second Comment!',       comments[5].comment)

  end


  ######################################################################
  #
  # test_change_design_center
  #
  # Description:
  # This method does the functional testing of the change_design_center
  # method from the Design Review class
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
         { :design_review_id  =>  mx234a_pre_artwork.id }, 
         {})
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
  # Additional information:
  # Verifies the following
  #   - User can not update unless logged in as an designer.
  #   - The information entered on the form is processed correctly.
  #
  ######################################################################
  #
  def test_update_design_center

    mx234a_pre_artwork = design_reviews(:mx234a_pre_artwork)
    boston_dc          = @nr
    fridley_dc         = @fridley

    mx234a = DesignReview.find(mx234a_pre_artwork.id)
    assert_equal(boston_dc.id, mx234a.design.design_center.id)

    post(:update_design_center,
         { :design_review  => { :id => mx234a_pre_artwork.id },
           :design_center  => { :location => fridley_dc.id } },
         scott_designer_session)
    mx234a = DesignReview.find(mx234a_pre_artwork.id)
    assert_equal(fridley_dc.id, mx234a.design.design_center.id)
    assert_equal('252-234-a0 has been updated - the updates were recorded and mail was sent',
                 flash['notice'])
    assert_redirected_to(:action => :view, :id => mx234a.id)

  end


  ######################################################################
  #
  # test_review_attachments
  #
  # Description:
  # This method does the functional testing of the review_attachments
  # method from the Design Review class
  #
  # Additional information:
  # Verifies the following
  #   - The information needed for the display is loaded.
  #
  ######################################################################
  #
  def test_review_attachments

    mx234a = design_reviews(:mx234a_pre_artwork)
    
    post(:review_attachments, { :design_review_id => mx234a.id }, scott_designer_session)
    assert_equal(mx234a.id,           assigns(:design_review).id)
    assert_equal(designs(:mx234a).id, assigns(:design_review).design_id)

    documents = assigns(:design_review).design.board.current_document_list
    assert_equal(4, documents.size)

    expected_documents = [ set_document(4, 'eng_notes.xls',      'Lee Schaff'),
                           set_document(1, 'mx234a_stackup.doc', 'Cathy McLaren'),
                           set_document(3, 'go_pirates.xls',     'Scott Glover'),
                           set_document(3, 'go_red_sox.xls',     'Scott Glover')]

    documents.each_with_index do |document, i|
      expected_doc = expected_documents[i]
      assert_equal(expected_doc[:document_type_id], document.document_type_id)
      assert_equal(expected_doc[:document_name],    document.document.name)
      assert_equal(expected_doc[:creator],          document.document.user.name)
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
  # Additional information:
  # Verifies the following
  #   - The user in logged in.
  #   - The information needed for the display is loaded.
  #
  ######################################################################
  #
  def test_update_documents

    mx234a           = design_reviews(:mx234a_pre_artwork)
    mx234a_eng_notes = design_review_documents(:mx234a_eng_notes_doc)
  
    post(:update_documents,
         { :design_review_id => mx234a.id, :document_id => mx234a_eng_notes.id },
         scott_designer_session)
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
  # Additional information:
  # Verifies the following
  #   - User can not update unless logged in
  #   - The information entered on the form is processed correctly.
  #
  ######################################################################
  #
  def test_save_update

    mx234a_pre_art = design_reviews(:mx234a_pre_artwork)
    
    put(:save_update,
        { :doc_id   => design_review_documents(:mx234a_stackup_doc),
          :document => { :name         => 'test.doc',
                         :data         => 'TEST DATA',
                         :content_type => 'txt' }, 
          :design_review => { :id => mx234a_pre_art.id } },
        cathy_admin_session)
    assert_redirected_to(:action => :review_attachments,
                         :design_review_id => mx234a_pre_art.id)
    assert_equal('The Stackup document has been updated.', flash['notice'])
 
    ### TODO - FIGURE OUT HOW TO LOAD A DOC FOR TESTING.

  end


  #
  ######################################################################
  #
  # test_add_attachment
  #
  # Description:
  # This method does the functional testing of the add_attachment method
  # from the Design Review class
  #
  # Additional information:
  # Verifies the following
  #   - User can not update unless logged in
  #   - The information entered on the form is processed correctly.
  #
  ######################################################################
  #
  def test_add_attachment
    
    mx234a_pre_art = design_reviews(:mx234a_pre_artwork)

    post(:add_attachment,
         :id            => mx234a_pre_art.design.board.id,
         :design_review => {:id => mx234a_pre_art.id})

    assert_equal(mx234a_pre_art.id,              assigns(:design_review).id)
    assert_equal(mx234a_pre_art.design.board.id, assigns(:board).id)
    assert_kind_of(Document, assigns(:document))
    doc_type = assigns(:document_types)

    assert_equal(2, doc_type.size)
    assert_equal("Other",           doc_type[0].name)
    assert_equal('Outline Drawing', doc_type[1].name)
    
    post(:add_attachment,
         :id               => mx234a_pre_art.design.board.id,
         :design_review_id => mx234a_pre_art.id)

    assert_equal(mx234a_pre_art.id,              assigns(:design_review).id)
    assert_equal(mx234a_pre_art.design.board.id, assigns(:board).id)
    assert_kind_of(Document, assigns(:document))
    doc_type = assigns(:document_types)
    assert_equal(2, doc_type.size)
    assert_equal("Other", doc_type[0].name)
    assert_equal('Outline Drawing', doc_type[1].name)

  end


  #
  ######################################################################
  #
  # test_save_attachment
  #
  # TODO: test_save_attachment
  #
  ######################################################################
  #
  def test_save_attachment
    
    #post(:save_attahment,
    #    :document_type => {:id => ''})
  end


  #
  ######################################################################
  #
  # test_get_attachment
  #
  # TODO: test_get_attachment
  #
  ######################################################################
  #
  def test_get_attachment

    post(:get_attachment, {}, {})
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal('Can not retrieve the attachment without an ID', flash['notice'])
    #post(:get_attachment, 
    #     :id => documents(:mx234a_stackup_document).id)
         
    #print "\n\nFigure out how to verify that get_attachment is working\n\n"
  end


  #
  ######################################################################
  #
  # test_list_obsolete
  #
  # TODO: test_list_obsolete
  #
  ######################################################################
  #
  def test_list_obsolete
    assert true
  end


  
  #
  ######################################################################
  #
  # test_review_mail_list
  #
  # Description:
  # This method verifies the review mail list
  # 
  ######################################################################
  #
  def test_review_mail_list
  
    admin_session = cathy_admin_session
    mx234a_pre_art = design_reviews(:mx234a_pre_artwork)

    get(:review_mail_list, { :design_review_id => mx234a_pre_art.id }, admin_session)
    assert_equal(mx234a_pre_art.id,        assigns(:design_review).id)
    assert_equal(mx234a_pre_art.design.id, assigns(:design).id)
    
    
    reviewer_list = assigns(:reviewers)
    
    expected_reviewer_list = []
    
    expected_users_not_copied = User.find(:all, :order => 'last_name')
    mx234a_pre_art.design_review_results.each do |design_review_result|
      user     = User.find(design_review_result.reviewer_id)
      reviewer = {:id        => user.id,
                  :name      => user.name,
                  :last_name => user.last_name,
                  :group     => Role.find(design_review_result.role_id).name}
      expected_reviewer_list << reviewer
      expected_users_not_copied.delete_if { |usr| usr.id == reviewer[:id] }
    end
    
    expected_reviewer_list = expected_reviewer_list.sort_by { |reviewer| reviewer[:last_name]}
    assert_equal(expected_reviewer_list, reviewer_list)
    
    
    users_copied = assigns(:users_copied)
    assert_equal([], users_copied)
    
    
    
    expected_users_not_copied.delete_if { |user| !user.active? }
    expected_users_not_copied.delete_if { |user| user.id == mx234a_pre_art.design.designer_id }

    users_not_copied = assigns(:users_not_copied)
    
    assert_equal(expected_users_not_copied, users_not_copied)
    
    users_not_copied_list = expected_users_not_copied.dup
    expected_users_copied = []
    for copy_user in users_not_copied_list
    
      expected_users_not_copied.delete_if { |usr| usr == copy_user }
      expected_users_copied << copy_user
      expected_users_copied = expected_users_copied.sort_by { |usr| usr.last_name }
      
      post(:add_to_list, { :id => copy_user.id }, admin_session )
      assert_equal(expected_users_not_copied, assigns(:users_not_copied))
      assert_equal(expected_users_copied,     assigns(:users_copied))
      
    end
    
    users_copied_list = expected_users_copied.dup
    for uncopy_user in users_copied_list
    
      expected_users_copied.delete_if { |usr| usr == uncopy_user }
      expected_users_not_copied << uncopy_user
      expected_users_not_copied = 
        expected_users_not_copied.sort_by { |usr| usr.last_name }
      
      post(:remove_from_list, { :id => uncopy_user.id }, admin_session)
      assert_equal(expected_users_not_copied, assigns(:users_not_copied))
      assert_equal(expected_users_copied,     assigns(:users_copied))
      
    end
    
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
  ######################################################################
  #
  def test_post_results

    #
    # THE PRE-ARTWORK REVIEW
    #
    expected_results = {
      '7'  => "No Response",   '8' => "No Response",   '5' => "No Response", 
      '15' => "No Response",  '10' => "No Response",  '11' => "No Response",
      '14' => "No Response",  '16' => "No Response",  '13' => "No Response",
      '17' => "No Response",  '18' => "No Response",   '9' => "No Response",
      '6'  => "No Response",  '12' => "No Response" }

    mail_subject = 'Catalyst/AC/(pcb252_234_a0_g): Pre-Artwork '
    reviewer_result_list= [
      # Espo - CE-DFT Reviewer
      {:user_id          => @espo.id,
       :role_id          => @ce_dft.id,
       :comment          => 'This is good!',
       :result           => 'APPROVED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_ce_dft).id,
       :role_id_tag      => 'role_id_7',
       :expected_results => {
         :comments_count   => 5,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + ' CE-DFT - APPROVED - See comments'
       }
      },
      # Heng Kit Too - DFM Reviewer
      {:user_id          => @heng_k.id,
       :role_id          => @dfm.id,
       :comment          => 'This is good enough to waive.',
       :result           => 'WAIVED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_dfm).id,
       :role_id_tag      => ':role_id_8',
       :expected_results => {
         :comments_count => 6,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + ' DFM - WAIVED - See comments'
       }
      },
      # Dave Macioce - Library Reviewer
      {:user_id          => @dave_m.id,
       :role_id          => @library.id,
       :comment          => 'Yankees Suck!!!',
       :result           => 'REJECTED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_lib),
       :role_id_tag      => ':role_id_15',
       :expected_results => {
         :comments_count => 7,
         :review_status_id => @pending_repost.id,
         :mail_subject     => mail_subject + ' Library - REJECTED - See comments'
       }
      },
      # Lee Shaff- HW Reviewer
      {:user_id          => @lee_s.id,
       :role_id          => @hweng.id,
       :comment          => 'No Comment',
       :result           => 'APPROVED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_hw).id,
       :role_id_tag      => ':role_id_5',
       :expected_results => {
         :comments_count => 8,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + ' HWENG - APPROVED - See comments'
       }
      },
      # Dave Macioce - Library Reviewer
      {:user_id          => @dave_m.id,
       :role_id          => @library.id,
       :comment          => '',
       :result           => 'APPROVED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_lib).id,
       :role_id_tag      => ':role_id_15',
       :expected_results => {
         :comments_count => 8,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + ' Library - APPROVED - No comments'
       }
      },
      # Espo - CE-DFT Reviewer
      {:user_id          => @espo.id,
       :role_id          => @ce_dft.id,
       :comment          => 'This is no good!',
       :result           => 'REJECTED',
       :ignore           => true,
       :review_result_id => design_review_results(:mx234a_pre_artwork_ce_dft).id,
       :role_id_tag      => 'role_id_7',
       :expected_results => {
         :comments_count => 9,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + '- Comments added'
       }
      },
      # Espo - CE-DFT Reviewer
      {:user_id          => @espo.id,
       :role_id          => @ce_dft.id,
       :comment          => 'Just kidding!',
       :result           => 'APPROVED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_ce_dft).id,
       :role_id_tag      => 'role_id_7',
       :expected_results => {
         :comments_count => 10,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + ' CE-DFT - APPROVED - See comments'
       }
      },
      # Tom Flak - Mehanical
      {:user_id          => @tom_f.id,
       :role_id          => @mechanical.id,
       :comment          => 'This is good!',
       :result           => 'APPROVED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_mech).id,
       :role_id_tag      => 'role_id_10',
       :expected_results => {
         :comments_count => 11,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + ' Mechanical - APPROVED - See comments'
       }
      },
      # Anthony Gentile - Mechanical MFG
      {:user_id          => @anthony_g.id,
       :role_id          => @mechanical_mfg.id,
       :comment          => '',
       :result           => 'APPROVED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_mech_mfg).id,
       :role_id_tag      => 'role_id_11',
       :expected_results => {
         :comments_count => 11,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + ' Mechanical-MFG - APPROVED - No comments'
       }
      },
      # Cathy McLaren - PCB Input Gate
      {:user_id          => @cathy_m.id,
       :role_id          => @pcb_input_gate.id,
       :comment          => 'I always have something to say.',
       :result           => 'APPROVED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_pcb_ig).id,
       :role_id_tag      => 'role_id_14',
       :expected_results => {
         :comments_count => 12,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + ' PCB Input Gate - APPROVED - See comments'
       }
      },
      # John Godin - PCB Mehanical
      {:user_id          => @john_g.id,
       :role_id          => @pcb_mechanical.id,
       :comment          => '',
       :result           => 'APPROVED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_pcb_mech).id,
       :role_id_tag      => 'role_id_16',
       :expected_results => {
         :comments_count => 12,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + ' PCB Mechanical - APPROVED - No comments'
       }
      },
      # Matt Disanzo - Planning
      {:user_id          => @matt_d.id,
       :role_id          => @planning.id,
       :comment          => 'Comment before entering result.',
       :result           => nil,
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_plan).id,
       :role_id_tag      => 'role_id_13',
       :expected_results => {
         :comments_count => 13,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + '- Comments added'
       }
      },
      # Matt Disanzo - Planning
      {:user_id          => @matt_d.id,
       :role_id          => @planning.id,
       :comment          => 'Testing.',
       :result           => 'APPROVED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_plan).id,
       :role_id_tag      => 'role_id_13',
       :expected_results => {
         :comments_count => 14,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + ' Planning - APPROVED - See comments'
       }
      },
      # Matt Disanzo - Planning
      {:user_id          => @matt_d.id,
       :role_id          => @planning.id,
       :comment          => 'Comment after entering result.',
       :result           => nil,
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_plan).id,
       :role_id_tag      => 'role_id_13',
       :expected_results => {
         :comments_count => 15,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + '- Comments added'
       }
      },
      # Arthur Davis - SLM BOM
      {:user_id          => @art_d.id,
       :role_id          => @slm_bom.id,
       :comment          => '',
       :result           => 'APPROVED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_slm_bom).id,
       :role_id_tag      => 'role_id_17',
       :expected_results => {
         :comments_count => 15,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + ' SLM BOM - APPROVED - No comments'
       }
      },
      # Rich Ahamed - TDE
      {:user_id          => @rich_a.id,
       :role_id          => @tde.id,
       :comment          => '',
       :result           => 'APPROVED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_tde).id,
       :role_id_tag      => 'role_id_9',
       :expected_results => {
         :comments_count => 15,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + ' TDE - APPROVED - No comments'
       }
      },
      # Lisa Austin - Valor
      {:user_id          => @lisa_a.id,
       :role_id          => @valor.id,
       :comment          => '',
       :result           => 'APPROVED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_valor).id,
       :role_id_tag      => 'role_id_6',
       :expected_results => {
         :comments_count => 15,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + ' Valor - APPROVED - No comments'
       }
      },

     ]

    mx234a = design_reviews(:mx234a_pre_artwork)

    update_mx234a                  = DesignReview.find(mx234a.id)
    update_mx234a.review_status_id = @in_review.id
    update_mx234a.save

    mx234a_review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)
    for mx234a_review_result in mx234a_review_results
      mx234a_review_result.result = 'No Response'
      mx234a_review_result.save
    end

    mx234a_review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)

    assert_equal(14, mx234a_review_results.size)
    assert_equal(4, 
                 DesignReviewComment.find_all_by_design_review_id(mx234a.id).size)
    for review_result in mx234a_review_results
      assert_equal("No Response", review_result.result)
    end

    repost = false
    for reviewer_result in reviewer_result_list

      if repost
        update_mx234a                  = DesignReview.find(mx234a.id)
        update_mx234a.review_status_id = @in_review.id
        update_mx234a.save
      end
      
      rev = User.find(reviewer_result[:user_id]).name

      reviewer_session = set_session(reviewer_result[:user_id], Role.find(reviewer_result[:role_id]).name)
      if reviewer_result[:result]
        post(:reviewer_results,
             { :post_comment                 => { "comment" => reviewer_result[:comment] },
               reviewer_result[:role_id_tag] => { reviewer_result[:review_result_id] => reviewer_result[:result] },
               :design_review                => { "id"      => mx234a.id } },
             reviewer_session,
             {:review_results => mx234a_review_results } ) #flash values
        if !reviewer_result[:ignore]
          expected_results[reviewer_result[:role_id].to_s] = reviewer_result[:result]
        end
      else
        post(:reviewer_results,
             { :post_comment  => { "comment" => reviewer_result[:comment] },
               :design_review => { "id"      => mx234a.id } },
             reviewer_session,
             {:review_results => mx234a_review_results } ) #flash values
      end

      if reviewer_result[:result] != 'REJECTED'
        assert_redirected_to(:action => :post_results)
      else
        if !reviewer_result[:ignore]
          expected_results.each { |k,v| 
            expected_results[k] = 'WITHDRAWN' if v == 'APPROVED'
          }
        end
        
        assert_redirected_to(:action => :confirm_rejection)
        #follow_redirect
        # "follow_redirect" is part of integration testing and should not be in
        # used in a functional test
       if false  #comment out section
        assert_equal(mx234a.id, assigns(:design_review_id))
       end #suppress follow_redirect
        repost = true
      end

      if !reviewer_result[:ignore]
        post(:post_results, {}, reviewer_session,
             {:review_results => mx234a_review_results } ) #flash values
      else
        post(:post_results, { :note => 'ignore' }, reviewer_session,
             {:review_results => mx234a_review_results } ) #flash values
      end

      email = @emails.pop
      assert_equal(0, @emails.size)
      assert_equal(reviewer_result[:expected_results][:mail_subject],
                   email.subject)
                   
      design_review_comments = DesignReviewComment.find_all_by_design_review_id(mx234a.id)
      assert_equal(reviewer_result[:expected_results][:comments_count], 
                   design_review_comments.size)
      if reviewer_result[:comment] != ''
        assert_equal(reviewer_result[:comment], design_review_comments.pop.comment)
      end

      review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)

      review_results.each do |review_result|
        assert_equal(expected_results[review_result.role_id.to_s],
                     review_result.result)
      end

      pre_art_design_review = DesignReview.find(mx234a.id)
      assert_equal(reviewer_result[:expected_results][:review_status_id],
                   pre_art_design_review.review_status_id)
    end

    #Verify the existing priority and designer.
    mx234a_pre_art_dr = DesignReview.find(mx234a.id)
    mx234a_design     = mx234a_pre_art_dr.design
    high              = Priority.find_by_name('High')
    low               = Priority.find_by_name('Low')
    bob_g             = User.find_by_last_name("Goldin")
    scott_g           = User.find_by_last_name("Glover")
    patrice_m         = User.find_by_last_name("Michaels")
    cathy_m           = User.find_by_last_name("McLaren")

    assert_equal(high.id,  mx234a_design.priority_id)
    assert_equal(5000,     mx234a_design.designer_id)
    assert_equal(5001,     mx234a_design.peer_id)

    release_review = ReviewType.get_release
    pre_art_review = ReviewType.get_pre_artwork
    for mx234a_dr in mx234a_design.design_reviews
      assert_equal(high.id,  mx234a_dr.priority_id)
      if release_review.id === mx234a_dr.review_type_id
        assert_equal(patrice_m.name, User.find(mx234a_dr.designer_id).name)
      elsif pre_art_review.id == mx234a_dr.review_type_id
        assert_equal(cathy_m.name, User.find(mx234a_dr.designer_id).name)
      else
        assert_equal(bob_g.name, User.find(mx234a_dr.designer_id).name)
      end
    end

    assert_equal(ReviewType.get_pre_artwork.id,
                 mx234a_design.phase_id)

    # Handle special processing cases
    assert_equal(0, mx234a_design.board.fab_houses.size)
    assert_equal(3, mx234a_design.fab_houses.size)
    fab_houses = mx234a_design.fab_houses.sort_by { |fh| fh.name }
    assert_equal(fab_houses(:ibm).id,   fab_houses[0].fab_house_id.to_i)
    assert_equal(fab_houses(:merix).id, fab_houses[1].fab_house_id.to_i)
    assert_equal(fab_houses(:opc).id,   fab_houses[2].fab_house_id.to_i)
    
    reviewer_session = dan_slm_vendor_session
    post(:reviewer_results,
         { :post_comment  => { "comment"   => '' },
           :role_id_18    => { 11          => 'APPROVED' },
           :design_review => { "id"        => mx234a.id },
                               :fab_house  => { '1' => '0',        '2' => '0',
                                                '3' => '1',        '4' => '1',
                                                '5' => '0',        '6' => '0',
                                                '7' => '0',        '8' => '0' } },
         reviewer_session,
         {:review_results => mx234a_review_results } ) #flash values
    assert_redirected_to(:action => :post_results)
    post(:post_results, {}, reviewer_session,
             {:review_results => mx234a_review_results } ) #flash values

    email = @emails.pop
    assert_equal(0, @emails.size)
    # Expect comments - the fab houses changed
    assert_equal(mail_subject + ' SLM-Vendor - APPROVED - See comments',
                 email.subject)
                   

    design_update = Design.find(mx234a_design.id)
    assert_equal(2, design_update.board.fab_houses.size)
    assert_equal(2, design_update.fab_houses.size)
    fab_houses = design_update.fab_houses.sort_by { |fh| fh.name }
    assert_equal(fab_houses(:advantech).id, fab_houses[0].fab_house_id.to_i)
    assert_equal(fab_houses(:coretec).id,   fab_houses[1].fab_house_id.to_i)
    fab_houses = design_update.board.fab_houses.sort_by { |fh| fh.name }
    assert_equal(fab_houses(:advantech).id, fab_houses[0].fab_house_id.to_i)
    assert_equal(fab_houses(:coretec).id,   fab_houses[1].fab_house_id.to_i)

    comments = DesignReviewComment.find_all_by_design_review_id(mx234a.id)
    assert_equal(16, comments.size)
    assert_equal('Updated the fab houses  - Added: AdvantechPWB, Coretec - Removed: OPC, Merix, IBM', 
                 comments.pop.comment)

    expected_results["18"] = 'APPROVED'
    review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)
    for review_result in review_results
      assert_equal(expected_results[review_result.role_id.to_s],
                   review_result.result)
    end

    pre_art_design_review = DesignReview.find(mx234a.id)
    assert_equal(@in_review.id, pre_art_design_review.review_status_id)
    assert_equal('09-May-06',
                 pre_art_design_review.completed_on.format_dd_mon_yy)


    # Handle special proessing for PCB Design Manager
    reviewer_session = jim_pcb_design_session
    post(:reviewer_results,
         { :post_comment  => { "comment" => 'Absolutely!' },
           :role_id_12    => { '100'     => reviewer_result[:result] },
           :design_review => { "id"      => mx234a.id },
           :designer      => { :id       => scott_g.id },
           :peer          => { :id       => bob_g.id },
           :priority      => { :id       => low.id } },
         reviewer_session)
    post(:post_results, {}, reviewer_session)

    email = @emails.shift
    assert_equal(1, @emails.size)

    assert_equal(mail_subject + ' PCB Design - APPROVED - See comments',
                 email.subject)
    email = @emails.shift
    assert_equal(0, @emails.size)

    assert_equal('Catalyst/AC/(pcb252_234_a0_g): The Pre-Artwork design review is complete',
                 email.subject)

    mx234a_pre_art_dr = DesignReview.find(mx234a.id)
    mx234a_design     = Design.find(mx234a_pre_art_dr.design_id)

    assert_equal(low.id,     mx234a_design.priority_id)
    assert_equal(scott_g.id, mx234a_design.designer_id)

    for mx234a_dr in mx234a_design.design_reviews
      assert_equal(low.name, Priority.find(mx234a_dr.priority_id).name)
      case ReviewType.find(mx234a_dr.review_type_id).name
      when 'Pre-Artwork'
        assert_equal(cathy_m.name,   User.find(mx234a_dr.designer_id).name)
      when 'Release'
        assert_equal(patrice_m.name, User.find(mx234a_dr.designer_id).name)
      else
        assert_equal(scott_g.name,   User.find(mx234a_dr.designer_id).name)
      end
    end

    assert_equal(ReviewType.get_placement.id,
                 mx234a_design.phase_id)
    assert_equal('Review Completed', mx234a_pre_art_dr.review_status.name)
    assert_equal(Time.now.format_dd_mon_yy,
                 mx234a_pre_art_dr.completed_on.format_dd_mon_yy)
    assert_equal(17, 
                 DesignReviewComment.find_all_by_design_review_id(mx234a.id).size)


    reviewer_session = dan_slm_vendor_session
    post(:reviewer_results,
         { :post_comment  => { "comment" => 'This is a test.' },
           :design_review => { "id"      => mx234a.id },
                               :fab_house   => { '1' => '0',        '2' => '0',
                                                 '3' => '0',        '4' => '0',
                                                 '5' => '1',        '6' => '1',
                                                 '7' => '0',        '8' => '0' } },
         reviewer_session,
             {:review_results => mx234a_review_results } ) #flash values
                                             
    assert_redirected_to(:action => :post_results)
    post(:post_results, {}, reviewer_session,
             {:review_results => mx234a_review_results } ) #flash values
    
    email = @emails.pop
    assert_equal(0, @emails.size)
    # Expect comments - the fab houses changed
    assert_equal(mail_subject + '- Comments added', email.subject)
  
    #
    # THE PLACEMENT REVIEW
    #
    expected_results = { '7' => "No Response",   '8' => "No Response",
                         '5' => "No Response",  '10' => "No Response",
                        '11' => "No Response",   '9' => "No Response" }

    mail_subject = 'Catalyst/AC/(pcb252_234_a0_g): Placement '
    reviewer_result_list= [
      # Espo - CE-DFT Reviewer
      {:user_id          => @espo.id,
       :role_id          => @ce_dft.id,
       :comment          => 'This is good!',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_placement_ce_dft).id,
       :role_id_tag      => 'role_id_7',
       :expected_results => {
         :comments_count   => 2,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' CE-DFT - APPROVED - See comments'
       }
      },
      # Heng Kit Too - DFM Reviewer
      {:user_id          => @heng_k.id,
       :role_id          => @dfm.id,
       :comment          => 'This is good enough to waive.',
       :result           => 'WAIVED',
       :review_result_id => design_review_results(:mx234a_placement_dfm).id,
       :role_id_tag      => ':role_id_8',
       :expected_results => {
         :comments_count => 3,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' DFM - WAIVED - See comments'
       }
      },
      # Lee Shaff- HW Reviewer
      {:user_id          => @lee_s.id,
       :role_id          => @hweng.id,
       :comment          => 'No Comment',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_placement_hw).id,
       :role_id_tag      => ':role_id_5',
       :expected_results => {
         :comments_count => 4,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' HWENG - APPROVED - See comments'
       }
      },
      # Tom Flak - Mehanical
      {:user_id          => @tom_f.id,
       :role_id          => @mechanical.id,
       :comment          => 'This is good!',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_placement_mech).id,
       :role_id_tag      => 'role_id_10',
       :expected_results => {
         :comments_count => 5,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' Mechanical - APPROVED - See comments'
       }
      },
      # Anthony Gentile - Mechanical MFG
      {:user_id          => @anthony_g.id,
       :role_id          => @mechanical_mfg.id,
       :comment          => '',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_placement_mech_mfg).id,
       :role_id_tag      => 'role_id_11',
       :expected_results => {
         :comments_count => 5,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' Mechanical-MFG - APPROVED - No comments'
       }
      },
      # Rich Ahamed - TDE
      {:user_id          => @rich_a.id,
       :role_id          => @tde.id,
       :comment          => '',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_placement_tde).id,
       :role_id_tag      => 'role_id_9',
       :expected_results => {
         :comments_count => 5,
         :review_status_id => @review_complete.id,
         :mail_count       => 2,
         :mail_subject     => mail_subject + ' TDE - APPROVED - No comments'
       }
      }
    ]

    mx234a = design_reviews(:mx234a_placement)

    update_mx234a                  = DesignReview.find(mx234a.id)
    update_mx234a.review_status_id = @in_review.id
    update_mx234a.save

    mx234a_review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)
    for mx234a_review_result in mx234a_review_results
      mx234a_review_result.result = 'No Response'
      mx234a_review_result.save
    end

    mx234a_review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)

    assert_equal(reviewer_result_list.size,
                 mx234a_review_results.size)
    assert_equal(1, 
                 DesignReviewComment.find_all_by_design_review_id(mx234a.id).size)
    for review_result in mx234a_review_results
      assert_equal("No Response", review_result.result)
    end

    repost = false
    for reviewer_result in reviewer_result_list

      if repost
        update_mx234a                  = DesignReview.find(mx234a.id)
        update_mx234a.review_status_id = @in_review.id
        update_mx234a.update
      end
      
      rev = User.find(reviewer_result[:user_id]).name
      reviewer_session = set_session(reviewer_result[:user_id], Role.find(reviewer_result[:role_id]).name)
      if reviewer_result[:result]
        post(:reviewer_results,
             { :post_comment                 => { "comment" => reviewer_result[:comment] },
               reviewer_result[:role_id_tag] => { reviewer_result[:review_result_id] => reviewer_result[:result] },
               :design_review                => { "id"      => mx234a.id } },
             reviewer_session,
             {:review_results => mx234a_review_results } ) #flash values)
        expected_results[reviewer_result[:role_id].to_s] = reviewer_result[:result]
      else
        post(:reviewer_results,
             { :post_comment  => { "comment" => reviewer_result[:comment] },
               :design_review => { "id"      => mx234a.id } },
             reviewer_session,
             {:review_results => mx234a_review_results } )
      end

      if reviewer_result[:result] != 'REJECTED'
        assert_redirected_to(:action => :post_results)
      else
        expected_results.each { |k,v| 
          expected_results[k] = 'WITHDRAWN' if v == 'APPROVED'
        }
        
        assert_redirected_to(:action => :confirm_rejection)
        #follow_redirect
        # "follow_redirect" is part of integration testing and should not be in
        # used in a functional test
        if false  #comment out section
        assert_equal(mx234a.id, assigns(:design_review_id))
        end #suppress follow_redirect
        repost = true
      end

      post(:post_results, {}, reviewer_session)

      assert_equal(reviewer_result[:expected_results][:mail_count], 
                   @emails.size)
      email = @emails.pop

      if @emails.size > 0
        assert_equal("Catalyst/AC/(pcb252_234_a0_g): The Placement design review is complete",
                     email.subject)
        email = @emails.pop
      end
      
      assert_equal(reviewer_result[:expected_results][:mail_subject],
                   email.subject)
                   
      design_review_comments = DesignReviewComment.find_all_by_design_review_id(mx234a.id)
      assert_equal(reviewer_result[:expected_results][:comments_count], 
                   design_review_comments.size)
      if reviewer_result[:comment] != ''
        assert_equal(reviewer_result[:comment],
                     design_review_comments.pop.comment)
      end

      review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)

      for review_result in review_results
        assert_equal(expected_results[review_result.role_id.to_s],
                     review_result.result)
      end

      placement_design_review = DesignReview.find(mx234a.id)
      assert_equal(reviewer_result[:expected_results][:review_status_id],
                   placement_design_review.review_status_id)
    end

    mx234a_design.reload
    mx234a_placement_dr = DesignReview.find(mx234a.id)
    assert_equal(ReviewType.get_routing.id,
                 mx234a_design.phase_id)
    assert_equal('Review Completed', 
                 mx234a_placement_dr.review_status.name)
    assert_equal(Time.now.format_dd_mon_yy,
                 mx234a_placement_dr.completed_on.format_dd_mon_yy)

    #
    # THE ROUTING REVIEW
    #
    expected_results = { '7'  => "No Response",   '8' => "No Response",
                         '5'  => "No Response",  '18' => "No Response",
                        '11'  => "No Response" }

    mail_subject = 'Catalyst/AC/(pcb252_234_a0_g): Routing '
    reviewer_result_list= [
      # Espo - CE-DFT Reviewer
      {:user_id          => @espo.id,
       :role_id          => @ce_dft.id,
       :comment          => 'This is good!',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_route_ce_dft).id,
       :role_id_tag      => 'role_id_7',
       :expected_results => {
         :comments_count   => 2,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' CE-DFT - APPROVED - See comments'
       }
      },
      # Dan Gough - SLM - Vendor
      {:user_id          => @dan_g.id,
       :role_id          => @slm_vendor.id,
       :comment          => 'I am stressed and I am going to pull a nutty!!!!',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_routing_slm_v),
       :role_id_tag      => 'role_id_18',
       :expected_results => {
         :comments_count   => 3,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' SLM-Vendor - APPROVED - See comments'
       }
      },
      # Heng Kit Too - DFM Reviewer
      {:user_id          => @heng_k.id,
       :role_id          => @dfm.id,
       :comment          => 'This is good enough to waive.',
       :result           => 'WAIVED',
       :review_result_id => design_review_results(:mx234a_route_dfm).id,
       :role_id_tag      => ':role_id_8',
       :expected_results => {
         :comments_count => 4,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' DFM - WAIVED - See comments'
       }
      },
      # Lee Shaff- HW Reviewer
      {:user_id          => @lee_s.id,
       :role_id          => @hweng.id,
       :comment          => 'No Comment',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_route_hw).id,
       :role_id_tag      => ':role_id_5',
       :expected_results => {
         :comments_count => 5,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' HWENG - APPROVED - See comments'
       }
      },
      # Anthony Gentile - Mechanical MFG
      {:user_id          => @anthony_g.id,
       :role_id          => @mechanical_mfg.id,
       :comment          => '',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_placement_mech_mfg).id,
       :role_id_tag      => 'role_id_11',
       :expected_results => {
         :comments_count => 5,
         :review_status_id => @review_complete.id,
         :mail_count       => 2,
         :mail_subject     => mail_subject + ' Mechanical-MFG - APPROVED - No comments'
       }
      }
    ]

    mx234a = design_reviews(:mx234a_routing)

    update_mx234a                  = DesignReview.find(mx234a.id)
    update_mx234a.review_status_id = @in_review.id
    update_mx234a.save

    mx234a_review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)
    for mx234a_review_result in mx234a_review_results
      mx234a_review_result.result = 'No Response'
      mx234a_review_result.save
    end

    mx234a_review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)

    assert_equal(reviewer_result_list.size,
                 mx234a_review_results.size)
    assert_equal(1, 
                 DesignReviewComment.find_all_by_design_review_id(mx234a.id).size)
    for review_result in mx234a_review_results
      assert_equal("No Response", review_result.result)
    end

    repost = false
    for reviewer_result in reviewer_result_list

      if repost
        update_mx234a                  = DesignReview.find(mx234a.id)
        update_mx234a.review_status_id = @in_review.id
        update_mx234a.update
      end
      
      rev = User.find(reviewer_result[:user_id]).name
      reviewer_session = set_session(reviewer_result[:user_id], Role.find(reviewer_result[:role_id]).name)
      
      if reviewer_result[:result]
        post(:reviewer_results,
             { :post_comment                 => { "comment" => reviewer_result[:comment] },
               reviewer_result[:role_id_tag] => { reviewer_result[:review_result_id] => reviewer_result[:result] },
               :design_review                => { "id"      => mx234a.id } },
             reviewer_session,
             {:review_results => mx234a_review_results } )
        expected_results[reviewer_result[:role_id].to_s] = reviewer_result[:result]
      else
        post(:reviewer_results,
             { :post_comment  => { "comment" => reviewer_result[:comment] },
               :design_review => { "id"      => mx234a.id } },
             reviewer_session,
             {:review_results => mx234a_review_results } )
      end

      if reviewer_result[:result] != 'REJECTED'
        assert_redirected_to(:action => :post_results)
      else
        expected_results.each { |k,v| 
          expected_results[k] = 'WITHDRAWN' if v == 'APPROVED'
        }
        
        assert_redirected_to(:action => :confirm_rejection)
        #follow_redirect
        # "follow_redirect" is part of integration testing and should not be in
        # used in a functional test
        if false  #comment out section
        assert_equal(mx234a.id, assigns(:design_review_id))
        end #suppress follow_redirect
        repost = true
      end

      post(:post_results, {}, reviewer_session,
             {:review_results => mx234a_review_results })
      assert_equal(reviewer_result[:expected_results][:mail_count], @emails.size)
      email = @emails.pop

      if @emails.size > 0
        assert_equal('Catalyst/AC/(pcb252_234_a0_g): The Routing design review is complete',
                     email.subject)
        email = @emails.pop
      end
      
      assert_equal(reviewer_result[:expected_results][:mail_subject],
                   email.subject)
                   
      design_review_comments = DesignReviewComment.find_all_by_design_review_id(mx234a.id)
      assert_equal(reviewer_result[:expected_results][:comments_count], 
                   design_review_comments.size)
      if reviewer_result[:comment] != ''
        assert_equal(reviewer_result[:comment],
                     design_review_comments.pop.comment)
      end

      review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)

      for review_result in review_results
        assert_equal(expected_results[review_result.role_id.to_s],
                     review_result.result)
      end

      routing_design_review = DesignReview.find(mx234a.id)
      assert_equal(reviewer_result[:expected_results][:review_status_id],
                   routing_design_review.review_status_id)
    end

    mx234a_design.reload
    mx234a_routing_dr = DesignReview.find(mx234a.id)
    assert_equal(ReviewType.get_final.id,
                 mx234a_design.phase_id)
    assert_equal('Review Completed', 
                 mx234a_routing_dr.review_status.name)
    assert_equal(Time.now.format_dd_mon_yy,
                 mx234a_routing_dr.completed_on.format_dd_mon_yy)

    #
    # THE FINAL REVIEW
    #
    expected_results = { '7' => "No Response",    '8' => "No Response",
                         '5' => "No Response",   '11' => "No Response",
                        '10' => "No Response",   '12' => "No Response",
                        '13' => "No Response",    '9' => "No Response",
                         '6' => "No Response" }

    mail_subject = 'Catalyst/AC/(pcb252_234_a0_g): Final '
    final_reviewer_result_list = [
      # Espo - CE-DFT Reviewer
      {:user_id          => @espo.id,
       :role_id          => @ce_dft.id,
       :comment          => 'This is good!',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_final_ce_dft).id,
       :role_id_tag      => 'role_id_7',
       :expected_results => {
         :comments_count   => 1,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' CE-DFT - APPROVED - See comments'
       }
      },
      # Heng Kit Too - DFM Reviewer
      {:user_id          => @heng_k.id,
       :role_id          => @dfm.id,
       :comment          => 'This is good enough to waive.',
       :result           => 'WAIVED',
       :review_result_id => design_review_results(:mx234a_final_dfm).id,
       :role_id_tag      => ':role_id_8',
       :expected_results => {
         :comments_count => 2,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' DFM - WAIVED - See comments'
       }
      },
      # Lee Shaff- HW Reviewer
      {:user_id          => @lee_s.id,
       :role_id          => @hweng.id,
       :comment          => 'No Comment',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_final_hw).id,
       :role_id_tag      => ':role_id_5',
       :expected_results => {
         :comments_count => 3,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' HWENG - APPROVED - See comments'
       }
      },
      # Anthony Gentile - Mechanical MFG
      {:user_id          => @anthony_g.id,
       :role_id          => @mechanical_mfg.id,
       :comment          => '',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_final_mech_mfg).id,
       :role_id_tag      => 'role_id_11',
       :expected_results => {
         :comments_count => 3,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' Mechanical-MFG - APPROVED - No comments'
       }
      },
      # Tom Flak - Mehanical
      {:user_id          => @tom_f.id,
       :role_id          => @mechanical.id,
       :comment          => 'This is good!',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_final_mech).id,
       :role_id_tag      => 'role_id_10',
       :expected_results => {
         :comments_count => 4,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' Mechanical - APPROVED - See comments'
       }
      },
      # Jim Light - PCB Manager
      {:user_id          => @jim_l.id,
       :role_id          => @pcb_design.id,
       :comment          => 'This is good!',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_final_pcb_design).id,
       :role_id_tag      => 'role_id_12',
       :expected_results => {
         :comments_count => 5,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' PCB Design - APPROVED - See comments'
       }
      },
      # Matt Disanzo - Planner
      {:user_id          => @matt_d.id,
       :role_id          => @planning.id,
       :comment          => 'This is a test.',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_final_plan).id,
       :role_id_tag      => 'role_id_13',
       :expected_results => {
         :comments_count => 6,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' Planning - APPROVED - See comments'
       }
      },
      # Rich Ahamed - Planner
      {:user_id          => @rich_a.id,
       :role_id          => @tde.id,
       :comment          => 'TDE Rules!  Planning Drools!',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_final_tde).id,
       :role_id_tag      => 'role_id_9',
       :expected_results => {
         :comments_count => 7,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' TDE - APPROVED - See comments'
       }
      },
      # Lisa Austin - Valor
      {:user_id          => @bob_g.id,
       :role_id          => @valor.id,
       :comment          => '',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_final_valor).id,
       :role_id_tag      => 'role_id_6',
       :expected_results => {
         :comments_count => 7,
         :review_status_id => @review_complete.id,
         :mail_count       => 2,
         :mail_subject     => mail_subject + ' Valor - APPROVED - No comments'
       }
      }
    ]

    mx234a = design_reviews(:mx234a_final)
    admin_email = users(:patrice_m).email


    update_mx234a                  = DesignReview.find(mx234a.id)
    update_mx234a.review_status_id = @in_review.id
    update_mx234a.save

    mx234a_review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)
    for mx234a_review_result in mx234a_review_results
      mx234a_review_result.result = 'No Response'
      mx234a_review_result.save
    end

    mx234a_review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)

    assert_equal(final_reviewer_result_list.size,  mx234a_review_results.size)
    assert_equal(0, 
                 DesignReviewComment.find_all_by_design_review_id(mx234a.id).size)
    mx234a_review_results.each do |review_result| 
      assert_equal("No Response", review_result.result)
    end

    repost = false
    final_reviewer_result_list.each do |reviewer_result|

      if repost
        update_mx234a                  = DesignReview.find(mx234a.id)
        update_mx234a.review_status_id = @in_review.id
        update_mx234a.update
      end
      
      rev = User.find(reviewer_result[:user_id]).name
      reviewer_session = set_session(reviewer_result[:user_id], Role.find(reviewer_result[:role_id]).name)

      if reviewer_result[:result]
        post(:reviewer_results,
             { :post_comment                 => { "comment" => reviewer_result[:comment] },
               reviewer_result[:role_id_tag] => { reviewer_result[:review_result_id] => reviewer_result[:result] },
               :design_review                => { "id"      => mx234a.id } },
             reviewer_session,
             {:review_results => mx234a_review_results } )
        expected_results[reviewer_result[:role_id].to_s] = reviewer_result[:result]
      else
        post(:reviewer_results,
             { :post_comment  => { "comment" => reviewer_result[:comment] },
               :design_review => { "id"      => mx234a.id } },
             reviewer_session,
             {:review_results => mx234a_review_results } )
      end

      if reviewer_result[:result] != 'REJECTED'
        assert_redirected_to(:action => :post_results)
      else
        expected_results.each { |k,v| 
          expected_results[k] = 'WITHDRAWN' if v == 'APPROVED'
        }
        
        assert_redirected_to(:action => :confirm_rejection)
        #follow_redirect
        # "follow_redirect" is part of integration testing and should not be in
        # used in a functional test
        if false  #comment out section
        assert_equal(mx234a.id, assigns(:design_review_id))
        end #suppress follow_redirect
        repost = true
      end

      post(:post_results, {}, reviewer_session)
      assert_equal(reviewer_result[:expected_results][:mail_count], 
                   @emails.size)
      email = @emails.pop

      if @emails.size > 0
        assert_equal("Catalyst/AC/(pcb252_234_a0_g): The Final design review is complete",
                     email.subject)

        found_email = email.cc.detect { |addr| addr == admin_email }
        assert_equal(admin_email, found_email)
        
        email = @emails.pop
      end
      
      assert_equal(reviewer_result[:expected_results][:mail_subject],
                   email.subject)
                   
      design_review_comments = DesignReviewComment.find_all_by_design_review_id(mx234a.id)
      assert_equal(reviewer_result[:expected_results][:comments_count], 
                   design_review_comments.size)
      if reviewer_result[:comment] != ''
        assert_equal(reviewer_result[:comment],
                     design_review_comments.pop.comment)
      end

      review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)

      for review_result in review_results
        assert_equal(expected_results[review_result.role_id.to_s],
                     review_result.result)
      end

      routing_design_review = DesignReview.find(mx234a.id)
      assert_equal(reviewer_result[:expected_results][:review_status_id],
                   routing_design_review.review_status_id)
    end

    mx234a_design.reload
    mx234a_final_dr = DesignReview.find(mx234a.id)
    assert_equal(ReviewType.get_release.id,
                 mx234a_design.phase_id)
    assert_equal('Review Completed', 
                 mx234a_final_dr.review_status.name)
    assert_equal(Time.now.format_dd_mon_yy,
                 mx234a_final_dr.completed_on.format_dd_mon_yy)

    #
    # THE RELEASE REVIEW
    #
    expected_results = { '5' => "No Response",  '12' => "No Response",
                        '19' => "No Response" }

    mail_subject = 'Catalyst/AC/(pcb252_234_a0_g): Release '
    reviewer_result_list= [
      # Lee Shaff- HW Reviewer
      {:user_id          => @lee_s.id,
       :role_id          => @hweng.id,
       :comment          => 'No Comment',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_release_hw).id,
       :role_id_tag      => ':role_id_5',
       :expected_results => {
         :comments_count => 1,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' HWENG - APPROVED - See comments'
       }
      },
      # Jim Light - PCB Manager
      {:user_id          => @jim_l.id,
       :role_id          => @pcb_design.id,
       :comment          => 'This is good!',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_release_pcb_design).id,
       :role_id_tag      => 'role_id_12',
       :expected_results => {
         :comments_count => 2,
         :review_status_id => @in_review.id,
         :mail_count       => 1,
         :mail_subject     => mail_subject + ' PCB Design - APPROVED - See comments'
       }
      },
      # Eileen Corran - Operations Manager
      {:user_id          => @eileen_c.id,
       :role_id          => roles(:operations_manager).id,
       :comment          => '',
       :result           => 'APPROVED',
       :review_result_id => design_review_results(:mx234a_release_ops).id,
       :role_id_tag      => 'role_id_19',
       :expected_results => {
         :comments_count => 2,
         :review_status_id => @review_complete.id,
         :mail_count       => 2,
         :mail_subject     => mail_subject + ' Operations Manager - APPROVED - No comments'
       }
      }
    ]

    mx234a = design_reviews(:mx234a_release)

    update_mx234a                  = DesignReview.find(mx234a.id)
    update_mx234a.review_status_id = @in_review.id
    update_mx234a.save

    mx234a_review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)
    for mx234a_review_result in mx234a_review_results
      mx234a_review_result.result = 'No Response'
      mx234a_review_result.save
    end

    mx234a_review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)

    assert_equal(reviewer_result_list.size,
                 mx234a_review_results.size)
    assert_equal(0, 
                 DesignReviewComment.find_all_by_design_review_id(mx234a.id).size)
    for review_result in mx234a_review_results
      assert_equal("No Response", review_result.result)
    end

    repost = false
    for reviewer_result in reviewer_result_list

      if repost
        update_mx234a                  = DesignReview.find(mx234a.id)
        update_mx234a.review_status_id = @in_review.id
        update_mx234a.update
      end
      
      rev = User.find(reviewer_result[:user_id]).name
      reviewer_session = set_session(reviewer_result[:user_id], Role.find(reviewer_result[:role_id]).name)

      if reviewer_result[:result]
        post(:reviewer_results,
             { :post_comment                 => { "comment" => reviewer_result[:comment] },
               reviewer_result[:role_id_tag] => { reviewer_result[:review_result_id] => reviewer_result[:result] },
               :design_review                => { "id"      => mx234a.id } },
             reviewer_session,
             {:review_results => mx234a_review_results } )
        expected_results[reviewer_result[:role_id].to_s] = reviewer_result[:result]
      else
        post(:reviewer_results,
             { :post_comment  => { "comment" => reviewer_result[:comment] },
               :design_review => { "id"      => mx234a.id } },
             reviewer_session,
             {:review_results => mx234a_review_results } )
      end

      if reviewer_result[:result] != 'REJECTED'
        assert_redirected_to(:action => :post_results)
      else
        expected_results.each { |k,v| 
          expected_results[k] = 'WITHDRAWN' if v == 'APPROVED'
        }
        
        assert_redirected_to(:action => :confirm_rejection)
        follow_redirect
        # "follow_redirect" is part of integration testing and should not be in
        # used in a functional test
        if false  #comment out section
        assert_equal(mx234a.id, assigns(:design_review_id))
        end #suppress follow_redirect
        repost = true
      end

      post(:post_results, {}, reviewer_session,
             {:review_results => mx234a_review_results } )
      assert_equal(reviewer_result[:expected_results][:mail_count], 
                   @emails.size)
      email = @emails.pop

      if @emails.size > 0
        assert_equal("Catalyst/AC/(pcb252_234_a0_g): The Release design review is complete",
                     email.subject)
        email = @emails.pop
      end

      assert_equal(reviewer_result[:expected_results][:mail_subject],
                   email.subject)
                   
      design_review_comments = DesignReviewComment.find_all_by_design_review_id(mx234a.id)
      assert_equal(reviewer_result[:expected_results][:comments_count], 
                   design_review_comments.size)
      if reviewer_result[:comment] != ''
        assert_equal(reviewer_result[:comment],
                     design_review_comments.pop.comment)
      end

      review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)

      for review_result in review_results
        assert_equal(expected_results[review_result.role_id.to_s],
                     review_result.result)
      end

      release_design_review = DesignReview.find(mx234a.id)
      assert_equal(reviewer_result[:expected_results][:review_status_id],
                   release_design_review.review_status_id)
    end

    mx234a_design.reload
    mx234a_release_dr = DesignReview.find(mx234a.id)
    assert_equal(Design::COMPLETE, mx234a_design.phase_id)
    assert_equal('Review Completed', 
                 mx234a_release_dr.review_status.name)
    assert_equal(Time.now.format_dd_mon_yy,
                 mx234a_release_dr.completed_on.format_dd_mon_yy)

  end


  #
  ######################################################################
  #
  # test_post_results_and_hold
  #
  # Description:
  # This method does the functional testing of the post results and
  # reviewer_results methods from the Design Review class
  #
  ######################################################################
  #
  def test_post_results_and_hold

    #
    # THE PRE-ARTWORK REVIEW
    #
    expected_results = {
       '7' => "No Response",   '8' => "No Response",   '5' => "No Response",
      '15' => "No Response",  '10' => "No Response",  '11' => "No Response",
      '14' => "No Response",  '16' => "No Response",  '13' => "No Response",
      '17' => "No Response",  '18' => "No Response",   '9' => "No Response",
       '6' => "No Response",  '12' => "No Response"
    }

    mail_subject = 'Catalyst/AC/(pcb252_234_a0_g): Pre-Artwork '
    reviewer_result_list= [
      # Espo - CE-DFT Reviewer
      {:user_id          => @espo.id,
       :role_id          => @ce_dft.id,
       :comment          => 'espo comment while in-review',
       :result           => 'APPROVED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_ce_dft).id,
       :role_id_tag      => 'role_id_7',
       :review_status    => @in_review,
       :expected_results => {
         :comments_count   => 5,
         :review_status_id => @in_review.id,
         :mail_subject     => mail_subject + ' CE-DFT - APPROVED - See comments',
         :notice           => "Design Review updated with comments and the review result - mail was sent"
       }
      },
      # Heng Kit Too - DFM Reviewer
      {:user_id          => @heng_k.id,
       :role_id          => @dfm.id,
       :comment          => 'HKT comment while on-hold',
       :result           => 'WAIVED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_dfm).id,
       :role_id_tag      => ':role_id_8',
       :review_status    => @on_hold,
       :expected_results => {
         :comments_count => 6,
         :review_status_id => @on_hold.id,
         :mail_subject     => mail_subject + '- Comments added',
         :notice           => "Design Review status is 'Review On-Hold': comments were recorded and review results were discarded - mail was sent"
       }
      },
      # Heng Kit Too - DFM Reviewer
      {:user_id          => @heng_k.id,
       :role_id          => @dfm.id,
       :comment          => 'HKT comment while pending repost',
       :result           => 'WAIVED',
       :ignore           => false,
       :review_result_id => design_review_results(:mx234a_pre_artwork_dfm).id,
       :role_id_tag      => ':role_id_8',
       :review_status    => @pending_repost,
       :expected_results => {
         :comments_count => 7,
         :review_status_id => @pending_repost.id,
         :mail_subject     => mail_subject + '- Comments added',
         :notice           => "Design Review status is 'Pending Repost': comments were recorded and review results were discarded - mail was sent"
       }
      }
    ]

    mx234a = design_reviews(:mx234a_pre_artwork)

    mx234a.design_review_results.each do |rr|
      rr.result = 'No Response'
      rr.save
    end
    
    mx234a_review_results = mx234a.design_review_results

    assert_equal(14, mx234a_review_results.size)
    assert_equal(4,  mx234a.design_review_comments.size)
    mx234a_review_results.each { |rr| assert_equal("No Response", rr.result) }

    reviewer_result_list.each do |reviewer_result|

      if reviewer_result[:review_status] == @on_hold
        mx234a.place_on_hold
      elsif reviewer_result[:review_status] == @pending_repost
        mx234a.review_status_id = @pending_repost.id
        mx234a.save
      else
        mx234a.remove_from_hold(@in_review)
        expected_results[reviewer_result[:role_id].to_s] = reviewer_result[:result]
      end
      mx234a.reload

      rev = User.find(reviewer_result[:user_id]).name
      reviewer_session = set_session(reviewer_result[:user_id], Role.find(reviewer_result[:role_id]).name)

      post(:reviewer_results,
           { :post_comment                 => { "comment"                          => reviewer_result[:comment] },
             reviewer_result[:role_id_tag] => { reviewer_result[:review_result_id] => reviewer_result[:result] },
             :design_review                => { "id"                               => mx234a.id } },
           reviewer_session)
      assert_redirected_to(:action => :post_results)

      #follow_redirect
      # "follow_redirect" is part of integration testing and should not be in
      # used in a functional test
      if false  #comment out section

      #assert_equal(reviewer_result[:expected_results][:notice], flash['notice'])

      assert_equal(1, @emails.size)
      email = @emails.pop
      assert_equal(0, @emails.size)
      assert_equal(reviewer_result[:expected_results][:mail_subject],
                   email.subject)
                   
      design_review_comments = DesignReviewComment.find_all_by_design_review_id(mx234a.id)
      assert_equal(reviewer_result[:expected_results][:comments_count], 
                   design_review_comments.size)
      if reviewer_result[:comment] != ''
        assert_equal(reviewer_result[:comment], design_review_comments.pop.comment)
      end

      review_results = DesignReviewResult.find_all_by_design_review_id(mx234a.id)

      for review_result in review_results
        assert_equal(expected_results[review_result.role_id.to_s],
                     review_result.result)
      end

      pre_art_design_review = DesignReview.find(mx234a.id)
      assert_equal(reviewer_result[:expected_results][:review_status_id],
                   pre_art_design_review.review_status_id)
      end #suppress "follow_redirect" section
    end

    #Verify the existing priority and designer.
    mx234a_pre_art_dr = DesignReview.find(mx234a.id)
    mx234a_design     = mx234a_pre_art_dr.design
    high              = Priority.find_by_name('High')
    low               = Priority.find_by_name('Low')
    bob_g             = User.find_by_last_name("Goldin")
    scott_g           = User.find_by_last_name("Glover")
    patrice_m         = User.find_by_last_name("Michaels")
    cathy_m           = User.find_by_last_name("McLaren")

    assert_equal(high.id,  mx234a_design.priority_id)
    assert_equal(5000,     mx234a_design.designer_id)
    assert_equal(5001,     mx234a_design.peer_id)

    release_review = ReviewType.get_release
    pre_art_review = ReviewType.get_pre_artwork
    for mx234a_dr in mx234a_design.design_reviews
      assert_equal(high.id,  mx234a_dr.priority_id)
      if release_review.id === mx234a_dr.review_type_id
        assert_equal(patrice_m.name, User.find(mx234a_dr.designer_id).name)
      elsif pre_art_review.id == mx234a_dr.review_type_id
        assert_equal(cathy_m.name, User.find(mx234a_dr.designer_id).name)
      else
        assert_equal(bob_g.name, User.find(mx234a_dr.designer_id).name)
      end
    end

    assert_equal(ReviewType.get_pre_artwork.id,
                 mx234a_design.phase_id)

    # Handle special processing cases
    assert_equal(0, mx234a_design.board.fab_houses.size)
    assert_equal(3, mx234a_design.fab_houses.size)
    fab_houses = mx234a_design.fab_houses.sort_by { |fh| fh.name }
    assert_equal(fab_houses(:ibm).id,   fab_houses[0].id.to_i)
    assert_equal(fab_houses(:merix).id, fab_houses[1].id.to_i)
    assert_equal(fab_houses(:opc).id,   fab_houses[2].id.to_i)
    
    comment_count = mx234a.design_review_comments.size
    # Verify the behavior when the review is pending and on hold
    updates = [{:review_status   => @pending_repost,
                :notice          => "Design Review status is 'Pending Repost': comments were recorded and review results were discarded - mail was sent",
                :fab_house       => {'1' => '1', '2' => '0',  '3' => '1',
                                     '4' => '1', '5' => '0',  '6' => '0',
                                     '7' => '0', '8' => '1'},
                :fab_house_count => 4,
                :fab_house_list  => ['AdvantechPWB', 'Coretec', 
                                     'Merix',        'OPC']},
               {:review_status   => @on_hold,
                :notice          => "Design Review status is 'Review On-Hold': comments were recorded and review results were discarded - mail was sent",
                :fab_house       => {'1' => '0', '2' => '0',  '3' => '0',
                                     '4' => '0', '5' => '1',  '6' => '0',
                                     '7' => '1', '8' => '1'},
                :fab_house_count => 3,
                :fab_house_list  => ['DDI Anaheim',  'MEI',   'OPC']}]
         
    slm_vendor_session = dan_slm_vendor_session
    updates.each do |update|

      review_status = update[:review_status]
      if review_status.id == @on_hold.id
        mx234a.place_on_hold
      else
        mx234a.review_status_id = review_status.id
        mx234a.save
      end
      mx234a.reload
    
      post(:reviewer_results,
           { :post_comment  => { "comment"    => "#{review_status.name}" },
             :role_id_18    => { 11           => 'APPROVED' },
             :design_review => { "id"         => mx234a.id },
             :fab_house      => update[:fab_house] },
           slm_vendor_session)                                      
      assert_redirected_to(:action => :post_results)
      #follow_redirect
      # "follow_redirect" is part of integration testing and should not be in
      # used in a functional test
      if false  #comment out section

      email = @emails.pop
      assert_equal(0, @emails.size)
      # Expect comments - the fab houses changed
      assert_equal(mail_subject + '- Comments added', email.subject)

      assert_equal(update[:fab_house_count], mx234a.design.fab_houses.size)
      assert_equal(update[:fab_house_count], mx234a.design.board.fab_houses.size)
      
      if update[:fab_house_count] > 0
        design_fab_houses = mx234a.design.fab_houses.sort_by { |fh| fh.name }
        board_fab_houses  = mx234a.design.board.fab_houses.sort_by { |fh| fh.name }
      
        0.upto(update[:fab_house_count]-1) do |i|
          assert_equal(update[:fab_house_list][i], design_fab_houses[i].name)
          assert_equal(update[:fab_house_list][i], board_fab_houses[i].name)
        end
      end
      
      comment_count += 2
      assert_equal(comment_count,   mx234a.design_review_comments.size)
      
      #assert_equal(update[:notice], flash['notice'])
      end #suppress follow_redirect
    end       

    # Handle special proessing for PCB Design Manager
    comment_count = mx234a.design_review_comments.size
    # Verify the behavior when the review is pending and on hold
    updates = [{:review_status   => @pending_repost,
                :notice          => "Design Review status is 'Pending Repost': comments were recorded and review results were discarded - mail was sent",
                :fab_house       => {'1' => '1', '2' => '0',  '3' => '1',
                                     '4' => '1', '5' => '0',  '6' => '0',
                                     '7' => '0', '8' => '1'},
                :fab_house_count => 4,
                :fab_house_list  => ['AdvantechPWB', 'Coretec', 
                                     'Merix',        'OPC']},
               {:review_status   => @on_hold,
                :notice          => "Design Review status is 'Review On-Hold': comments were recorded and review results were discarded - mail was sent",
                :fab_house       => {'1' => '0', '2' => '0',  '3' => '0',
                                     '4' => '0', '5' => '1',  '6' => '0',
                                     '7' => '1', '8' => '1'},
                :fab_house_count => 3,
                :fab_house_list  => ['DDI Anaheim',  'MEI',   'OPC']}]
                
    email = []
    pcb_design_session = jim_pcb_design_session
    updates.each do |update|
    
      review_status = update[:review_status]
      if review_status.id == @on_hold.id
        mx234a.place_on_hold
      else
        mx234a.review_status_id = review_status.id
        mx234a.save
      end
      mx234a.reload
    
      post(:reviewer_results,
           { :post_comment  => { "comment" => 'Absolutely!' },
             :role_id_12    => { '100'     => 'APPROVED' },
             :design_review => { "id"      => mx234a.id },
             :designer      => { :id       => scott_g.id },
             :peer          => { :id       => bob_g.id },
             :priority      => { :id       => low.id } },
           pcb_design_session)

      assert_redirected_to(:action => :post_results)
      #follow_redirect
      # "follow_redirect" is part of integration testing and should not be in
      # used in a functional test
      if false  #comment out section

      email = @emails.pop
      assert_equal(0, @emails.size)
      # Expect comments - the fab houses changed
      assert_equal(mail_subject + '- Comments added', email.subject)

      comment_count += 1
      assert_equal(comment_count,   mx234a.design_review_comments.size)
      
      #assert_equal(update[:notice], flash['notice'])
      end # suppress follow_redirect
    end

    mx234a.reload
    
    designer_email = User.find(mx234a.design.pcb_input_id).email

    assert(!email.cc.detect { |addr| addr == designer_email })
    
    mx234a_pre_art_dr = DesignReview.find(mx234a.id)
    mx234a_design     = Design.find(mx234a_pre_art_dr.design_id)

    assert_equal(low.id,     mx234a_design.priority_id)
    assert_equal(scott_g.id, mx234a_design.designer_id)

    for mx234a_dr in mx234a_design.design_reviews
      assert_equal(low.name, Priority.find(mx234a_dr.priority_id).name)
      case ReviewType.find(mx234a_dr.review_type_id).name
      when 'Pre-Artwork'
        assert_equal(cathy_m.name,   User.find(mx234a_dr.designer_id).name)
      when 'Release'
        assert_equal(patrice_m.name, User.find(mx234a_dr.designer_id).name)
      else
        assert_equal(scott_g.name,   User.find(mx234a_dr.designer_id).name)
      end
    end

  end
  

  #
  ######################################################################
  #
  # test_reassign_reviewer
  #
  # Description:
  # This method does the functional testing of the reassign reviewer
  # action.
  #
  ######################################################################
  #
  def test_reassign_reviewer

    #set_user(@matt_d.id, 'Reviewer')
    post(:reassign_reviewer,
         {:design_review_id => design_reviews(:mx234a_pre_artwork).id},
         matt_planning_session)

    peer_list = assigns(:matching_roles)

    assert_equal(1, peer_list.size)
    assert_equal('Planning', 
                 Role.find(peer_list[0][:design_review].role_id).name)
    assert_equal(1, peer_list[0][:peers].size)
    peer = peer_list[0][:peers].pop
    assert_equal('Tina Delacuesta', peer.name)

    post(:reassign_reviewer,
         { :design_review_id => design_reviews(:mx234a_pre_artwork).id },
         rich_reviewer_session)

    peer_list = assigns(:matching_roles).sort_by { |match|
      Role.find(match[:design_review].role_id).name
    }

    assert_equal(2, peer_list.size)

    assert_equal('HWENG', Role.find(peer_list[0][:design_review].role_id).name)
    assert_equal(nil, peer_list[0][:peers])

    assert_equal('TDE', Role.find(peer_list[1][:design_review].role_id).name)
    assert_equal(1, peer_list[1][:peers].size)
    peer = peer_list[1][:peers].pop
    assert_equal('Man Chan', peer.name)

    end


  #
  ######################################################################
  #
  # test_update_review_assignments
  #
  # Description:
  # This method does the functional testing of the update_review_assignments
  # action.
  #
  ######################################################################
  #
  def test_update_review_assignments
    
    reviewer_session = rich_reviewer_session

    hw_review_result  = design_review_results(:mx234a_pre_artwork_hw)
    tde_review_result = design_review_results(:mx234a_pre_artwork_tde)
    assert_equal('Lee Schaff', User.find(hw_review_result.reviewer_id).name)

    put(:update_review_assignments,
        { :id                      => design_reviews(:mx234a_pre_artwork).id,
          'HWENG_5_assign_to_self' => 'yes' },
        reviewer_session)
    email = @emails.pop
    assert_equal(0, @emails.size)
    assert_equal('Catalyst/AC/(pcb252_234_a0_g): The Hardware Engineer (EE) review has been reassigned to Rich Ahamed',
                 email.subject)

    hw_review_result.reload
    assert_equal('Rich Ahamed', User.find(hw_review_result.reviewer_id).name)
    assert_equal('Rich Ahamed', User.find(tde_review_result.reviewer_id).name)

    put(:update_review_assignments,
        { :id     => design_reviews(:mx234a_pre_artwork).id,
          :user   => { 'TDE'   => '7201',
                       'HWENG' => '6000' } },
        reviewer_session)
    email = @emails.pop
    assert_equal(1, @emails.size)
    assert_equal('Catalyst/AC/(pcb252_234_a0_g): You have been assigned to perform the TDE Engineer review',
                 email.subject)
    email = @emails.pop
    assert_equal(0, @emails.size)
    assert_equal('Catalyst/AC/(pcb252_234_a0_g): You have been assigned to perform the Hardware Engineer (EE) review',
                 email.subject)

    hw_review_result.reload
    assert_equal('Ben Bina', User.find(hw_review_result.reviewer_id).name)
    tde_review_result.reload
    assert_equal('Man Chan', User.find(tde_review_result.reviewer_id).name)

  end


  #
  ######################################################################
  #
  # test_admin_update
  #
  # Description:
  # This method does the functional testing of the admin_update method
  # from the Design Review class
  # 
  # TODO: ONLY ADMINS SHOULD GET THE SCREEN
  #
  ######################################################################
  #
  def test_admin_update

    mx234a_pre_artwork = 
      DesignReview.find(design_reviews(:mx234a_pre_artwork).id)

    get(:admin_update, { :id => mx234a_pre_artwork.id }, {})

    designers = Role.active_designers
    assert_equal(designers.size,   assigns(:designers).size)
    assert_equal(designers.size-1, assigns(:peer_list).size)
    assert_equal(3,                assigns(:priorities).size)
    assert_equal(2,                assigns(:design_centers).size)
    
  end


def dump_design_reviews(msg)
  
  designs(:mx234a).design_reviews.each do |design_review|
    next if design_review.review_type.name != 'Pre-Artwork'
    puts(designs(:mx234a).part_number.pcb_display_name +
         " - ########################### - " + msg)
    puts("DESIGN REVIEW - ID: " + design_review.id.to_s +
         "  REVIEW TYPE: " + design_review.review_type.name)
    puts("DESIGNER: " + design_review.designer.name +
         "  CRITICALITY: " + design_review.priority.name +
         "  DESIGN CENTER: " + design_review.design_center.name)
    puts("###########################")
  end

end
  #
  ######################################################################
  #
  # test_proces_admin_update
  #
  # Description:
  # This method does the functional testing of the process_admin_update 
  # method from the Design Review class
  #
  ######################################################################
  # TODO: Depends on flash
  def notest_process_admin_update

    # Verify the redirect when the user is not a admin/manager
    mx234a_pre_artwork = DesignReview.find(design_reviews(:mx234a_pre_artwork).id)
    #bob_g   = User.find_by_last_name("Goldin")
    #scott_g = User.find_by_last_name("Glover")
    #rich_m  = User.find_by_last_name("Miller")
    #jan_k   = User.find_by_last_name("Kasting")
    #cathy_m = User.find_by_last_name("McLaren")
    #siva_e  = User.find_by_last_name("Esakky")
    
    boston_harrison = @nr
    oregon          = @oregon

    post(:process_admin_update,
         { :id       => mx234a_pre_artwork.id,
           :designer => { :id => @scott_g.id.to_s },
           :peer     => { :id => @scott_g.id.to_s } },
         {})

    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal('Update not allowed - Must be admin or manager',
                 flash['notice'])
                 
    pre_art_design_review = mx234a_pre_artwork.design.get_design_review('Pre-Artwork')
    release_design_review = mx234a_pre_artwork.design.get_design_review('Release')

    # Verify the redirect when the user tries to set the designer and 
    # peer as the same person.
    post(:process_admin_update,
         { :id             => mx234a_pre_artwork.id,
           :designer       => { :id => @scott_g.id.to_s },
           :peer           => { :id => @scott_g.id.to_s },
           :pcb_input_gate => { :id => pre_art_design_review.designer_id },
           :design_center  => { :id => mx234a_pre_artwork.design_center_id },
           :priority       => { :id => mx234a_pre_artwork.priority_id },
           :release_poster => { :id => release_design_review.designer_id },
           :post_comment   => { :comment => '' } },
         jim_manager_session)
       
    assert_redirected_to(:action => "admin_update", :id => mx234a_pre_artwork.id.to_s)
    assert_equal('The peer and the designer must be different - update not recorded',
                 flash['notice'])

    # Verify the baseline.
    mx234a = designs(:mx234a)
    expected_reviews = {
      'Release'     => {:designer      => 'Patrice Michaels',
                        :priority      => 'High',
                        :design_center => boston_harrison.name},
      'Pre-Artwork' => {:designer      => 'Cathy McLaren',
                        :priority      => 'High',
                        :design_center => boston_harrison.name}
    }
    expected_reviews.default = {
      :designer      => 'Robert Goldin',
      :priority      => 'High',
      :design_center => boston_harrison.name
    }

    mx234a.design_reviews.each do |design_review|
        assert_equal(expected_reviews[design_review.review_type.name][:designer],
                     design_review.designer.name)
        assert_equal(expected_reviews[design_review.review_type.name][:priority],
                     design_review.priority.name)
        assert_equal(expected_reviews[design_review.review_type.name][:design_center],
                     design_review.design_center.name)
    end
    
    @emails.clear
    post(:process_admin_update,
         :id             => mx234a_pre_artwork.id,
         :designer       => {:id      => rich_m.id.to_s},
         :pcb_input_gate => {:id      => jan_k.id.to_s},
         :peer           => {:id      => scott_g.id.to_s},
         :review_status  => {:id      => review_statuses(:in_review).id.to_s},
         :priority       => {:id      => @low_priority.id.to_s},
         :release_poster => {:id      => release_design_review.designer_id},
         :design_center  => {:id      => @fridley.id.to_s},
         :post_comment   => {:comment => "This is a test"})
         
    mx234a.reload
 
    assert(1, @emails.size)
    email = @emails.pop
    assert("The mx234a Pre-Artwork Design Review has been modified by James Light",
           email.subject)
          
    mx234a_pre_artwork_reviewers = [@espo,      @heng_k,    @lee_s,     @dave_m,
                                    @tom_f,     @anthony_g, @cathy_m,   @john_g,
                                    @matt_d,    @art_d,     @jim_l,     @dan_g,
                                    @rich_a,    @lisa_a]

    expected_to_list  = mx234a_pre_artwork_reviewers.collect { |r| r.email }
    expected_to_list += [rich_m.email, scott_g.email, jan_k.email]
    expected_to_list  = expected_to_list.uniq.sort
    expected_cc_list  = [bob_g.email].sort
    
    assert_equal(expected_cc_list, email.cc.sort)
    assert_equal(expected_to_list, email.to.sort)       
    
    assert_equal(rich_m.name,  mx234a.designer.name)
    assert_equal(scott_g.name, mx234a.peer.name)
    assert_equal(jan_k.name,   mx234a.input_gate.name)
    
    expected_reviews['Final']       = { :designer      => rich_m.name,
                                        :priority      => @low_priority.name,
                                        :design_center => @fridley.name }
    expected_reviews['Placement']   = { :designer      => rich_m.name,
                                        :priority      => @low_priority.name,
                                        :design_center => @fridley.name }
    expected_reviews['Pre-Artwork'] = { :designer      => jan_k.name,
                                        :priority      => @low_priority.name,
                                        :design_center => @fridley.name }
    expected_reviews['Release']     = { :designer      => 'Patrice Michaels',
                                        :priority      => @low_priority.name,
                                        :design_center => @fridley.name }
    expected_reviews['Routing']     = { :designer      => rich_m.name,
                                        :priority      => @low_priority.name,
                                        :design_center => @fridley.name }

    mx234a.design_reviews.each do |design_review|
      assert_equal(expected_reviews[design_review.review_type.name][:designer],
                   User.find(design_review.designer_id).name)
      assert_equal(expected_reviews[design_review.review_type.name][:priority],
                   Priority.find(design_review.priority_id).name)
      assert_equal(expected_reviews[design_review.review_type.name][:design_center],
                   DesignCenter.find(design_review.design_center_id).name)
    end
    
    # Update the designer only and make sure that the designer for all but the
    # pre-art reviews are updated.
    @emails.clear
    post(:process_admin_update,
         :id             => mx234a_pre_artwork.id,
         :designer       => {:id      => bob_g.id.to_s},
         :pcb_input_gate => {:id      => jan_k.id.to_s},
         :peer           => {:id      => scott_g.id.to_s},
         :review_status  => {:id      => review_statuses(:in_review).id.to_s},
         :priority       => {:id      => @low_priority.id.to_s},
         :release_poster => {:id      => release_design_review.designer_id},
         :design_center  => {:id      => @fridley.id.to_s},
         :post_comment   => {:comment => "This is a test"})
         
    mx234a.reload

    assert_equal(1, @emails.size)
    email = @emails.pop
    assert_equal('Catalyst/AC/(pcb252_234_a0_g): The Pre-Artwork design ' +
                 'review has been modified by James Light',
                 email.subject)
          
    expected_to_list  = mx234a_pre_artwork_reviewers.collect { |r| r.email }
    expected_to_list += [bob_g.email, scott_g.email, jan_k.email]
    expected_to_list  = expected_to_list.uniq.sort
    expected_cc_list  = [rich_m.email].sort
    
    assert_equal(expected_cc_list, email.cc.sort)
    assert_equal(expected_to_list, email.to.sort)       
    
    assert_equal(bob_g.name,   mx234a.designer.name)
    assert_equal(scott_g.name, mx234a.peer.name)
    assert_equal(jan_k.name,   mx234a.input_gate.name)
    
    expected_reviews['Final']       = { :designer      => bob_g.name,
                                        :priority      => @low_priority.name,
                                        :design_center => @fridley.name }
    expected_reviews['Placement']   = { :designer      => bob_g.name,
                                        :priority      => @low_priority.name,
                                        :design_center => @fridley.name }
    expected_reviews['Pre-Artwork'] = { :designer      => jan_k.name,
                                        :priority      => @low_priority.name,
                                        :design_center => @fridley.name }
    expected_reviews['Release']     = { :designer      => 'Patrice Michaels',
                                        :priority      => @low_priority.name,
                                        :design_center => @fridley.name }
    expected_reviews['Routing']     = { :designer      => bob_g.name,
                                        :priority      => @low_priority.name,
                                        :design_center => @fridley.name }

    mx234a.design_reviews.each do |design_review|
      assert_equal(expected_reviews[design_review.review_type.name][:designer],
                   User.find(design_review.designer_id).name)
      assert_equal(expected_reviews[design_review.review_type.name][:priority],
                   Priority.find(design_review.priority_id).name)
      assert_equal(expected_reviews[design_review.review_type.name][:design_center],
                   DesignCenter.find(design_review.design_center_id).name)
    end


    # Set the Pre-Art review to review completed, do an update on the placement 
    # review and verify the results.
    mx234a_pre_artwork.reload
    mx234a_pre_artwork.review_status = @review_complete
    mx234a_pre_artwork.save
    mx234a_pre_artwork.reload
    
    mx234a.phase_id = ReviewType.get_placement.id
    mx234a.save
    
    mx234a_placement = design_reviews(:mx234a_placement)

    @emails.clear
    post(:process_admin_update,
         :id             => mx234a_placement.id,
         :designer       => {:id      => scott_g.id.to_s},
         :pcb_input_gate => {:id      => jan_k.id.to_s},
         :peer           => {:id      => rich_m.id.to_s},
         :review_status  => {:id      => review_statuses(:in_review).id.to_s},
         :priority       => {:id      => @high_priority.id.to_s},
         :release_poster => {:id      => release_design_review.designer_id},
         :design_center  => {:id      => @fridley.id.to_s},
         :post_comment   => {:comment => "Placement Update"})
         
    mx234a.reload

    assert_equal(1, @emails.size)
    email = @emails.pop
    assert_equal('Catalyst/AC/(pcb252_234_a0_g): The Placement design review ' +
                 'has been modified by James Light',
                 email.subject)

    mx234a_placement_reviewers = [@espo,      @heng_k,    @lee_s,     
                                  @tom_f,     @anthony_g, @rich_a]

    expected_to_list  = mx234a_placement_reviewers.collect { |r| r.email }
    expected_to_list += [scott_g.email, rich_m.email, jan_k.email]
    expected_to_list  = expected_to_list.uniq.sort
    expected_cc_list  = [bob_g.email, @cathy_m.email, @jim_l.email, @lisa_a.email].sort

    assert_equal(expected_cc_list, email.cc.sort)
    assert_equal(expected_to_list, email.to.sort)       
    
    assert_equal(scott_g.name, mx234a.designer.name)
    assert_equal(rich_m.name,  mx234a.peer.name)
    assert_equal(jan_k.name,   mx234a.input_gate.name)
    
    expected_reviews['Final']       = { :designer      => scott_g.name,
                                        :priority      => @high_priority.name,
                                        :design_center => @fridley.name }
    expected_reviews['Placement']   = { :designer      => scott_g.name,
                                        :priority      => @high_priority.name,
                                        :design_center => @fridley.name }
    expected_reviews['Pre-Artwork'] = { :designer      => jan_k.name,
                                        :priority      => @low_priority.name,
                                        :design_center => @fridley.name }
    expected_reviews['Release']     = { :designer      => 'Patrice Michaels',
                                        :priority      => @high_priority.name,
                                        :design_center => @fridley.name }
    expected_reviews['Routing']     = { :designer      => scott_g.name,
                                        :priority      => @high_priority.name,
                                        :design_center => @fridley.name }

    mx234a.design_reviews.each do |design_review|
      assert_equal(expected_reviews[design_review.review_type.name][:designer],
                   User.find(design_review.designer_id).name)
      assert_equal(expected_reviews[design_review.review_type.name][:priority],
                   Priority.find(design_review.priority_id).name)
      assert_equal(expected_reviews[design_review.review_type.name][:design_center],
                   DesignCenter.find(design_review.design_center_id).name)
    end
    
    
    # Set the placement review to review completed, do an update on the routing 
    # review and verfiy the results.
    mx234a_placement.reload
    mx234a_placement.review_status = @review_complete
    mx234a_placement.save
    mx234a_placement.reload
    
    mx234a.phase_id = ReviewType.get_routing.id
    mx234a.save
    
    mx234a_routing = design_reviews(:mx234a_routing)

    @emails.clear
    post(:process_admin_update,
         :id             => mx234a_routing.id,
         :designer       => {:id      => rich_m.id.to_s},
         :pcb_input_gate => {:id      => jan_k.id.to_s},
         :peer           => {:id      => bob_g.id.to_s},
         :review_status  => {:id      => review_statuses(:in_review).id.to_s},
         :priority       => {:id      => @low_priority.id.to_s},
         :release_poster => {:id      => release_design_review.designer_id},
         :design_center  => {:id      => @oregon.id.to_s},
         :post_comment   => {:comment => "Placement Update"})
         
    mx234a.reload
    
    assert_equal(1, @emails.size)
    email = @emails.pop
    assert_equal('Catalyst/AC/(pcb252_234_a0_g): The Routing design review ' +
                 'has been modified by James Light',
                 email.subject)

    mx234a_routing_reviewers = [@espo,      @heng_k,    @lee_s,     
                                @anthony_g, @dan_g]

    expected_to_list  = mx234a_routing_reviewers.collect { |r| r.email }
    expected_to_list += [bob_g.email, rich_m.email, jan_k.email]
    expected_to_list  = expected_to_list.uniq.sort
    expected_cc_list  = [scott_g.email, @jim_l.email, @cathy_m.email].sort
    
    assert_equal(expected_cc_list, email.cc.sort)
    assert_equal(expected_to_list, email.to.sort)       
    
    assert_equal(rich_m.name, mx234a.designer.name)
    assert_equal(bob_g.name,  mx234a.peer.name)
    assert_equal(jan_k.name,  mx234a.input_gate.name)
    
    expected_reviews['Final']       = { :designer      => rich_m.name,
                                        :priority      => @low_priority.name,
                                        :design_center => @oregon.name }
    expected_reviews['Placement']   = { :designer      => scott_g.name,
                                        :priority      => @high_priority.name,
                                        :design_center => @oregon.name }
    expected_reviews['Pre-Artwork'] = { :designer      => jan_k.name,
                                        :priority      => @low_priority.name,
                                        :design_center => @oregon.name }
    expected_reviews['Release']     = { :designer      => 'Patrice Michaels',
                                        :priority      => @low_priority.name,
                                        :design_center => @oregon.name }
    expected_reviews['Routing']     = { :designer      => rich_m.name,
                                        :priority      => @low_priority.name,
                                        :design_center => @oregon.name }

    mx234a.design_reviews.each do |design_review|
      assert_equal(expected_reviews[design_review.review_type.name][:designer],
                   User.find(design_review.designer_id).name)
      assert_equal(expected_reviews[design_review.review_type.name][:priority],
                   Priority.find(design_review.priority_id).name)
      assert_equal(expected_reviews[design_review.review_type.name][:design_center],
                   DesignCenter.find(design_review.design_center_id).name)
    end


    # Set the routing review to review completed, do an update on the final
    # review and verify the results
    mx234a_routing.reload
    mx234a_routing.review_status = @review_complete
    mx234a_routing.save
    mx234a_routing.reload
   
    mx234a.phase_id = ReviewType.get_final.id
    mx234a.save
    
    mx234a_final = design_reviews(:mx234a_final)

    @emails.clear
    # Change the designer from Rich to Bob, the peer from Bob to Scott, the priority from
    # low to high, and the design center from oregon to boston.
    post(:process_admin_update,
         :id             => mx234a_final.id,
         :designer       => {:id      => bob_g.id.to_s},
         :pcb_input_gate => {:id      => jan_k.id.to_s},
         :peer           => {:id      => scott_g.id.to_s},
         :review_status  => {:id      => review_statuses(:in_review).id.to_s},
         :priority       => {:id      => @high_priority.id.to_s},
         :release_poster => {:id      => release_design_review.designer_id},
         :design_center  => {:id      => @nr.id.to_s},
         :post_comment   => {:comment => "Final Review Update"})
         
    mx234a.reload
    
    assert_equal(1, @emails.size)
    email = @emails.pop
    assert_equal('Catalyst/AC/(pcb252_234_a0_g): The Final design review has ' +
                 'been modified by James Light',
                 email.subject)

    mx234a_final_reviewers = [@espo,      @heng_k,    @lee_s,     @anthony_g, 
                              @jim_l,     @tom_f,     @matt_d,    @rich_a,    bob_g]

    expected_to_list  = mx234a_final_reviewers.collect { |r| r.email }
    expected_to_list += [bob_g.email, scott_g.email, jan_k.email]
    expected_to_list  = expected_to_list.uniq.sort
    expected_cc_list  = [rich_m.email, @cathy_m.email].sort
    
    assert_equal(expected_cc_list, email.cc.sort)
    assert_equal(expected_to_list, email.to.sort)       
    
    assert_equal(bob_g.name,    mx234a.designer.name)
    assert_equal(scott_g.name,  mx234a.peer.name)
    assert_equal(jan_k.name,    mx234a.input_gate.name)
    
    expected_reviews['Final']       = { :designer      => bob_g.name,
                                        :priority      => @high_priority.name,
                                        :design_center => @nr.name }
    expected_reviews['Placement']   = { :designer      => scott_g.name,
                                        :priority      => @high_priority.name,
                                        :design_center => @nr.name }
    expected_reviews['Pre-Artwork'] = { :designer      => jan_k.name,
                                        :priority      => @low_priority.name,
                                        :design_center => @nr.name }
    expected_reviews['Release']     = { :designer      => 'Patrice Michaels',
                                        :priority      => @high_priority.name,
                                        :design_center => @nr.name }
    expected_reviews['Routing']     = { :designer      => rich_m.name,
                                        :priority      => @low_priority.name,
                                        :design_center => @nr.name }

    mx234a.design_reviews.each do |design_review|
      assert_equal(expected_reviews[design_review.review_type.name][:designer],
                   User.find(design_review.designer_id).name)
      assert_equal(expected_reviews[design_review.review_type.name][:priority],
                   Priority.find(design_review.priority_id).name)
      assert_equal(expected_reviews[design_review.review_type.name][:design_center],
                   DesignCenter.find(design_review.design_center_id).name)
    end
   
   
    # Set the final review to the review completed, update the designer for the 
    # release review and verify the results.
    mx234a_final.reload
    mx234a_final.review_status = @review_complete
    mx234a_final.save
    mx234a_final.reload
    
    mx234a.phase_id = ReviewType.get_release.id
    mx234a.save

    mx234a_release = design_reviews(:mx234a_release)

    @emails.clear
    # Change the priority from high to low and the design center from boston to oregon.
    post(:process_admin_update,
         :id             => mx234a_release.id,
         :designer       => {:id      => bob_g.id.to_s},
         :pcb_input_gate => {:id      => jan_k.id.to_s},
         :peer           => {:id      => scott_g.id.to_s},
         :review_status  => {:id      => review_statuses(:in_review).id.to_s},
         :priority       => {:id      => @low_priority.id.to_s},
         :release_poster => {:id      => release_design_review.designer_id},
         :design_center  => {:id      => @oregon.id.to_s},
         :post_comment   => {:comment => "Final Review Update"})
         
    mx234a.reload
    
    assert_equal(1, @emails.size)
    email = @emails.pop
    assert_equal('Catalyst/AC/(pcb252_234_a0_g): The Release design review ' +
                 'has been modified by James Light',
                 email.subject)

    mx234a_routing_reviewers = [@lee_s,   @jim_l,   @eileen_c]

    expected_to_list  = mx234a_routing_reviewers.collect { |r| r.email }
    expected_to_list += [bob_g.email, jan_k.email, scott_g.email]
    expected_to_list  = expected_to_list.uniq.sort
    expected_cc_list  = [users(:patrice_m).email, @cathy_m.email].sort
    
    assert_equal(expected_cc_list, email.cc.sort)
    assert_equal(expected_to_list, email.to.sort)       
    
    assert_equal(bob_g.name,   mx234a.designer.name)
    assert_equal(scott_g.name, mx234a.peer.name)
    assert_equal(jan_k.name,   mx234a.input_gate.name)
    
    expected_reviews['Final']       = { :designer      => bob_g.name,
                                        :priority      => @high_priority.name,
                                        :design_center => @oregon.name }
    expected_reviews['Placement']   = { :designer      => scott_g.name,
                                        :priority      => @high_priority.name,
                                        :design_center => @oregon.name }
    expected_reviews['Pre-Artwork'] = { :designer      => jan_k.name,
                                        :priority      => @low_priority.name,
                                        :design_center => @oregon.name }
    expected_reviews['Release']     = { :designer      => 'Patrice Michaels',
                                        :priority      => @low_priority.name,
                                        :design_center => @oregon.name }
    expected_reviews['Routing']     = { :designer      => rich_m.name,
                                        :priority      => @low_priority.name,
                                        :design_center => @oregon.name }

    mx234a.design_reviews.each do |design_review|
      assert_equal(expected_reviews[design_review.review_type.name][:designer],
                   User.find(design_review.designer_id).name)
      assert_equal(expected_reviews[design_review.review_type.name][:priority],
                   Priority.find(design_review.priority_id).name)
      assert_equal(expected_reviews[design_review.review_type.name][:design_center],
                   DesignCenter.find(design_review.design_center_id).name)
    end

  end

  
  private
  
  
  def set_reviewer(group, reviewer_count, reviewer)
    { :group => group, :reviewer_count => reviewer_count, :reviewer => reviewer }
  end
  
  
  def set_group(group, group_id, reviewer_count)
    { :group => group, :group_id => group_id, :reviewer_count => reviewer_count}
  end
  
  
  def set_document(document_type_id, document_name, creator)
    { :document_type_id => document_type_id,
      :document_name    => document_name,
      :creator          => creator }
  end  
  
end
