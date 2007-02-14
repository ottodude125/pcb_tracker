########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: tracker_mailer_test.rb
#
# This file contains the unit tests for the Tracker Mailer model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'
require 'tracker_mailer'

class TrackerMailerTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  fixtures(:audits,
           :audit_comments,
           :board_reviewers,
           :boards,
           :boards_fab_houses,
           :design_centers,
           :design_checks,
           :design_review_comments,
           :design_review_documents,
           :design_review_results,
           :design_reviews,
           :designs,
           :fab_houses,
           :ipd_posts,
           :platforms,
           :prefixes,
           :projects,
           :review_statuses,
           :roles_users,
           :review_types,
           :roles,
           :users)


  ##############################################################################
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
    
    @audit   = Audit.find(audits(:audit_mx234a).id)
    
    @mx234a_pre_art_dr = DesignReview.find(
                           design_reviews(:mx234a_pre_artwork).id)
    @mx234a_release_dr = DesignReview.find(
                           design_reviews(:mx234a_release).id)
    @mx234a_final_dr   = DesignReview.find(
                           design_reviews(:mx234a_final).id)
                           
    @mx234a_pre_art_dr_emails = 
      @mx234a_pre_art_dr.reviewers.collect { |r| r.email }.sort_by { |address| address }.uniq
    @mx234a_final_dr_emails   =
      @mx234a_final_dr.reviewers.collect { |r| r.email }.sort_by { |address| address }.uniq
    @mx234a_release_dr_emails =
      @mx234a_release_dr.reviewers.collect { |r| r.email }.sort_by { |address| address }.uniq
               
    @hweng_role   = Role.find_by_name('HWENG')
    
    @manager_email_list = []
    manager_role = Role.find_by_name("Manager")
    for manager in manager_role.users
      @manager_email_list << manager.email if manager.active?
    end
    
    @input_gate_email_list = []
    input_gate_role = Role.find_by_name("PCB Input Gate")
    for input_gate in input_gate_role.users
      @input_gate_email_list << input_gate.email if input_gate.active?
    end
    
    @pcb_admin_email_list = []
    pcb_admin_role = Role.find_by_name("PCB Admin")
    for pcb_admin in pcb_admin_role.users
      @pcb_admin_email_list << pcb_admin.email if pcb_admin.active?
    end

    
    
    @rich_a  = users(:rich_a)
    @cathy_m = users(:cathy_m)
    @jan_k   = users(:jan_k)
    @jim_l   = users(:jim_l)
    @scott_g = users(:scott_g)
    @bob_g   = users(:bob_g)
    @lee_s   = users(:lee_s)
    @rich_m  = users(:rich_m)
    @siva_e  = users(:siva_e)
    
    @mx234a_stackup_doc = DesignReviewDocument.find(
                            design_review_documents(:mx234a_stackup_doc).id)
    
    @root_post = IpdPost.find(ipd_posts(:mx234a_thread_one).id)
    
    @now  = Time.now
    
  end


  ##############################################################################
  def test_peer_audit_complete
  
    peer = @audit.design.peer.name

    response = TrackerMailer.create_peer_audit_complete(@audit, @now)
    
    assert_equal("#{@audit.design.name}" +
                 ": The peer auditor has completed the audit", 
                 response.subject)
    assert_equal("#{peer} has completed the peer audit review" +
                 " for the #{@audit.design.name}\n",
                 response.body)
    assert_equal([users(:bob_g).email], response.to)
    assert_equal([Pcbtr::SENDER],       response.from)
    assert_equal(@now.to_s,             response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = [@cathy_m.email,
                   @scott_g.email,
                   @jan_k.email,
                   @jim_l.email].sort_by { |address| address }
    assert_equal(expected_cc, response_cc)
    
  end


  ##############################################################################
  def test_self_audit_complete
  
    designer = User.find(@audit.design.designer_id).name
  
    response = TrackerMailer.create_self_audit_complete(@audit, @now)
    
    assert_equal("#{@audit.design.name}" +
                 ": The designer has completed the self-audit", 
                 response.subject)
    assert_equal("#{designer} has completed the self audit review" +
                 " for the #{@audit.design.name}\n\nYou can start" +
                 " your peer audit.\n",
                 response.body)
    assert_equal([@scott_g.email], response.to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = [@cathy_m.email,
                   @bob_g.email,
                   @jan_k.email,
                   @jim_l.email].sort_by { |address| address }
    assert_equal(expected_cc, response_cc)
    
  end


  ##############################################################################
  def test_final_review_warning
  
    design = @audit.design
    
    response = TrackerMailer.create_final_review_warning(@audit.design, @now)
     
    assert_equal("Notification of upcoming Final Review for #{@audit.design.name}", 
                 response.subject)
    assert_equal("Attention! Peer review is underway.  Final review/approval " +
                 "will be required in a few days.",
                 response.body)
                 
    reviewers = [ users(:espo),       users(:heng_k),
                  users(:lisa_a),     users(:rich_a),
                  users(:matt_d),     users(:jim_l),
                  users(:anthony_g),  users(:tom_f),
                  users(:lee_s) ].uniq.sort_by { |u| u.email }
    to_list   = reviewers.collect { |u| u.email }      
    assert_equal(to_list,          response.to.sort_by { |email| email })
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    expected_cc = [@cathy_m.email, @bob_g.email, @jan_k.email].sort_by { |address| address }
    assert_equal(expected_cc, response.cc.sort_by { |email| email })
    
  end


  ##############################################################################
  def test_design_review_update
  
    subject = "#{@mx234a_pre_art_dr.design.name}::" +
                "#{@mx234a_pre_art_dr.review_type.name}"
                
    #
    # Test a comment only update.
    response = TrackerMailer.create_design_review_update(
                 @cathy,
                 @mx234a_pre_art_dr,
                 true,
                 {},
                 @now)
                 
    assert_equal(subject + " - Comments added", 
                 response.subject)

    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_pre_art_dr_emails

    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = @manager_email_list + @input_gate_email_list
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)

    #
    # Test a result only update.
    # Update the review result record before sending the mail.
    tde_role      = Role.find_by_name("TDE")
    review_result = DesignReviewResult.find_by_design_review_id_and_reviewer_id_and_role_id(
                      @mx234a_pre_art_dr.id,
                      @rich_a.id,
                      tde_role.id)
    review_result.result = 'APPROVED'
    review_result.update

    response = TrackerMailer.create_design_review_update(
                 @rich_a,
                 @mx234a_pre_art_dr,
                 false,
                 {:TDE => 'APPROVED'},
                 @now)
                 
    assert_equal(subject + "  TDE - APPROVED - No comments", 
                 response.subject)
                 
    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_pre_art_dr_emails

    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = @manager_email_list + @input_gate_email_list
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)

    #
    # Test a result and comment update.
    # Update the review result record before sending the mail.
    tde_role      = Role.find_by_name("TDE")
    review_result = DesignReviewResult.find_by_design_review_id_and_reviewer_id_and_role_id(
                      @mx234a_pre_art_dr.id,
                      @rich_a.id,
                      tde_role.id)
    review_result.result = 'WAIVED'
    review_result.update

    response = TrackerMailer.create_design_review_update(
                 @rich_a,
                 @mx234a_pre_art_dr,
                 true,
                 {:TDE   => 'WAIVED'},
                 @now)
                 
    assert_equal(subject + "  TDE - WAIVED - See comments", 
                 response.subject)
                 
    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_pre_art_dr_emails

    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = @manager_email_list + @input_gate_email_list
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)

  end


  ##############################################################################
  def test_design_review_complete_notification
  
    #
    # Pre-Artwork Review
    response = TrackerMailer.create_design_review_complete_notification(
                 @mx234a_pre_art_dr,
                 @now)
                
    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_pre_art_dr_emails
    
    assert_equal("mx234a: Pre-Artwork Review is complete", 
                 response.subject)
    assert_equal(expected_to,      response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    assert_equal("The design information is located at " +
                 "#{Pcbtr::PCBTR_BASE_URL}design_review/view/1\n",
                 response.body)

    response_cc = response.cc.sort_by { |address| address }
    expected_cc = @manager_email_list + @input_gate_email_list
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)

    #
    # Final Review
    response = TrackerMailer.create_design_review_complete_notification(
                 @mx234a_final_dr,
                 @now)
                
    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_final_dr_emails
    
    assert_equal("mx234a: Final Review is complete", 
                 response.subject)
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    assert_equal("The design information is located at " +
                 "#{Pcbtr::PCBTR_BASE_URL}design_review/view/4\n",
                 response.body)

    response_cc = response.cc.sort_by { |address| address }
    
    expected_final_cc = expected_cc + @pcb_admin_email_list
    designer = User.find(@mx234a_final_dr.design.designer_id)
    expected_final_cc << designer.email    
    expected_final_cc = expected_final_cc.sort_by { |address| address }.uniq
    assert_equal(expected_final_cc, response_cc)
    
    #
    # Release Review
    response = TrackerMailer.create_design_review_complete_notification(
                 @mx234a_release_dr,
                 @now)
                
    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_release_dr_emails
    
    assert_equal("mx234a: Release Review is complete", 
                 response.subject)
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    assert_equal("The design information is located at " +
                 "#{Pcbtr::PCBTR_BASE_URL}design_review/view/5\n",
                 response.body)

    response_cc = response.cc.sort_by { |address| address }
    
    expected_release_cc = @manager_email_list + @input_gate_email_list
    designer = User.find(@mx234a_release_dr.designer_id)
    expected_release_cc << designer.email
    expected_release_cc << "STD_DC_ECO_Inbox@notes.teradyne.com" if !Pcbtr::DEVEL_SERVER
    
    expected_release_cc = expected_release_cc.sort_by { |address| address }.uniq
    assert_equal(expected_release_cc, response_cc)

  end


  ##############################################################################
  def test_design_review_posting_notification
    #
    # Pre-Artwork Review
    response = TrackerMailer.create_design_review_posting_notification(
                 @mx234a_pre_art_dr,
                 'The requisite posting comment.',
                 false,
                 @now)
                
    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_pre_art_dr_emails
    
    assert_equal("mx234a: The Pre-Artwork review has been posted", 
                 response.subject)
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = @manager_email_list + @input_gate_email_list
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)

    #
    # Final Review
    response = TrackerMailer.create_design_review_posting_notification(
                 @mx234a_final_dr,
                 'Yankees do not suck.  Their fans suck.',
                 true,
                 @now)

    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_final_dr_emails
    
    assert_equal("mx234a: The Final review has been reposted", 
                 response.subject)
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    
    expected_final_cc = expected_cc + @pcb_admin_email_list
    designer = User.find(@mx234a_final_dr.design.designer_id)
    expected_final_cc << designer.email
    expected_final_cc = expected_final_cc.sort_by { |address| address }.uniq
    assert_equal(expected_final_cc, response_cc)
    
  end


  ##############################################################################
  def test_ipd_update

    response = TrackerMailer.create_ipd_update(@root_post,
                                               @now)
                 
    assert_equal("mx234a [IPD] - mx234a Thread 1 subject", 
                 response.subject)
                 
    response_to = response.to.sort_by { |address| address }
    expected_to = [@bob_g.email].sort_by { |address| address }.uniq

    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = @manager_email_list + @input_gate_email_list

    poster = User.find(@root_post.user_id)
    expected_cc << poster.email
    expected_cc += @root_post.direct_children.collect { |post| post.user.email }
    expected_cc  = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)
    
  end


  ##############################################################################
  def test_user_password

    response = TrackerMailer.create_user_password(@scott_g,
                                                  @now)
    assert_equal('Your password', response.subject)
    assert_equal("Your password is #{@scott_g.passwd}\n\nPCB DESIGN TRACKER URL - #{Pcbtr::PCBTR_BASE_URL}tracker\n",
                 response.body)
    assert_equal([@scott_g.email], response.to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    assert_equal(nil,              response.cc)
    
  end


  ##############################################################################
  def test_ping_summary

    response = TrackerMailer.create_ping_summary({},
                                                 @now)
                 
    assert_equal("Summary of reviewers who have not approved/waived design reviews", 
                 response.subject)
                 
    response_to = response.to.sort_by { |address| address }
    expected_to = @manager_email_list + @input_gate_email_list
    expected_to = expected_to.sort_by { |address| address }.uniq
    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    assert_equal(nil,             response.cc)
    
  end


  ##############################################################################
  def test_ping_reviewer

    review_result_list = {:review_list => [ {:design_review => @mx234a_pre_art_dr,
                                             :role          => 'HWENG',
                                             :age           => 12}],
                          :reviewer    => @lee_s}
    response = TrackerMailer.create_ping_reviewer(review_result_list,
                                                  @now)
                 
    assert_equal("Your unresolved Design Review(s)", 
                 response.subject)
                 
    response_to = response.to.sort_by { |address| address }
    expected_to = [@lee_s.email].sort_by { |address| address }.uniq
 
    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    assert_equal(nil,             response.cc)
    
  end
  
  
  ##############################################################################
  def test_reassign_design_review_to_peer
  
    response = TrackerMailer.create_reassign_design_review_to_peer(
                 @lee_s,
                 @rich_a,
                 @scott_g,
                 @mx234a_pre_art_dr,
                 @hweng_role,
                 @now)
                 
    assert_equal("mx234a: You have been assigned to perform the Hardware Engineer (EE) review", 
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@rich_a.email].sort_by { |address| address }.uniq

    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = [@lee_s.email] + @manager_email_list + @input_gate_email_list
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)

  end


  ##############################################################################
  def test_reassign_design_review_from_peer
  
    response = TrackerMailer.create_reassign_design_review_from_peer(
                 @lee_s,
                 @rich_a,
                 @scott_g,
                 @mx234a_pre_art_dr,
                 @hweng_role,
                 @now)
                 
    assert_equal("mx234a: The Hardware Engineer (EE) review has been reassigned to Lee Schaff", 
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@rich_a.email].sort_by { |address| address }.uniq

    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = [@lee_s.email] + @manager_email_list + @input_gate_email_list
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)

  end
  

  ##############################################################################
  def test_tracker_invite
  
    response = TrackerMailer.create_tracker_invite(@lee_s,
                                                   @now)
                 
    assert_equal("Your login information for the PCB Design Tracker", 
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@lee_s.email]
    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    assert_equal(nil,             response.cc)
    
  end


  ##############################################################################
  def test_attachment_update
  
    response = TrackerMailer.create_attachment_update(@mx234a_stackup_doc,
                                                      @lee_s,
                                                      @now)
                 
    assert_equal("A document has been attached for the " +
                 @mx234a_stackup_doc.design.name + " design", 
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    
    expected_to = @manager_email_list

    mx234a_design = @mx234a_stackup_doc.design
    expected_to << mx234a_design.designer.email   if mx234a_design.designer_id > 0
    expected_to << mx234a_design.peer.email       if mx234a_design.peer_id > 0
    expected_to << mx234a_design.input_gate.email if mx234a_design.pcb_input_id > 0

    mx234a_design.design_reviews.each do |design_review|
      expected_to += design_review.reviewers.collect { |r| r.email }
    end

    expected_to = expected_to.uniq.sort_by { |address| address }
    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    
    expected_cc = @input_gate_email_list
    if mx234a_design.pcb_input_id > 0
      pcb_input_gate = User.find(mx234a_design.pcb_input_id)
      expected_cc.delete_if { |email| email == pcb_input_gate.email }
    end
    assert_equal(expected_cc, response.cc)
    
  end


  ##############################################################################
  def test_audit_update

    response = TrackerMailer.create_audit_update(design_checks(:design_check_5),
                                                 'No comment',
                                                 @scott_g,
                                                 @rich_m,
                                                 @now)
               
    expected_subj = @mx234a_final_dr.design.name +
                    " PEER AUDIT: A comment has been entered that requires " +
                    "your attention"  
    assert_equal(expected_subj, response.subject)
    
    response_to = response.to.sort_by { |address| address }

    assert_equal([@scott_g.email],   response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    assert_equal([@rich_m.email], response.cc)
    
  end
  
  
  ##############################################################################
  def test_design_review_modification
  
    cc_list = []
    response = TrackerMailer.create_design_review_modification(@cathy_m,
                                                               @mx234a_pre_art_dr,
                                                               cc_list)

    assert_equal("The mx234a Pre-Artwork Design Review has been modified by Cathy McLaren", 
                 response.subject)

    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_pre_art_dr_emails
    
    # Add the designer, peer, and input gate to the 'To:' field.
    expected_to += [@bob_g.email, @scott_g.email, @cathy_m.email]

    assert_equal(expected_to.uniq.sort, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    assert_equal([@jan_k.email], response_cc)

    cc_list = [@rich_m.email, @siva_e.email, @jan_k.email].sort_by { |address| address }
    response = TrackerMailer.create_design_review_modification(@cathy_m,
                                                               @mx234a_pre_art_dr,
                                                               cc_list)

    assert_equal("The mx234a Pre-Artwork Design Review has been modified by Cathy McLaren", 
                 response.subject)

    response_to = response.to.sort_by { |address| address }
    
    assert_equal(expected_to.uniq.sort, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    
    response_cc = response.cc.sort_by { |address| address }
    assert_equal(cc_list, response_cc)

 
  end
  
  
  ##############################################################################
  def test_audit_team_updates
  end
  
  
  ##############################################################################
  def test_notify_design_review_skipped
  end
  
  
  ##############################################################################
  def test_originator_board_design_entry_deletion
  end
  
  
  ##############################################################################
  def test_board_design_entry_return_to_originator
  end
  
  
  ##############################################################################
  def test_board_design_entry_submission
  end
  
  
  ##############################################################################
  def test_oi_assignment_notification
  end
  
  
  ##############################################################################
  def test_oi_task_update
  end
  

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/tracker_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
