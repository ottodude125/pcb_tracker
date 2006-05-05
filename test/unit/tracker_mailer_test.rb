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
                           
    @hweng_role = Role.find_by_name('HWENG')
    
    @rich_a  = User.find(users(:rich_a).id)
    @cathy_m = User.find(users(:cathy_m).id)
    @jan_k   = User.find(users(:jan_k).id)
    @jim_l   = User.find(users(:jim_l).id)
    @scott_g = User.find(users(:scott_g).id)
    @bob_g   = User.find(users(:bob_g).id)
    @lee_s   = User.find(users(:lee_s).id)
    
    @root_post = IpdPost.find(ipd_posts(:mx234a_thread_one).id)
    
    @now  = Time.now
    
  end

  def test_peer_audit_complete
  
    peer = User.find(@audit.design.peer_id).name
  
    response = TrackerMailer.create_peer_audit_complete(@audit,
                                                        @now)
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
    assert_equal(expected_cc,      response_cc)
    
  end

  def test_self_audit_complete
  
    designer = User.find(@audit.design.designer_id).name
  
    response = TrackerMailer.create_self_audit_complete(@audit,
                                                        @now)
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
    assert_equal(expected_cc,      response_cc)
    
  end

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
    expected_to = []
    for review_result in @mx234a_pre_art_dr.design_review_results
      expected_to << User.find(review_result.reviewer_id).email
    end
    expected_to = expected_to.sort_by { |address| address }.uniq
    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = []
    manager_role = Role.find_by_name("Manager")
    for manager in manager_role.users
      expected_cc << manager.email if manager.active?
    end
    input_gate_role = Role.find_by_name("PCB Input Gate")
    for input_gate in input_gate_role.users
      expected_cc << input_gate.email if input_gate.active?
    end
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
    expected_to = []
    for review_result in @mx234a_pre_art_dr.design_review_results
      expected_to << User.find(review_result.reviewer_id).email
    end
    expected_to = expected_to.sort_by { |address| address }.uniq
    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = []
    manager_role = Role.find_by_name("Manager")
    for manager in manager_role.users
      expected_cc << manager.email if manager.active?
    end
    input_gate_role = Role.find_by_name("PCB Input Gate")
    for input_gate in input_gate_role.users
      expected_cc << input_gate.email if input_gate.active?
    end
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
    expected_to = []
    for review_result in @mx234a_pre_art_dr.design_review_results
      expected_to << User.find(review_result.reviewer_id).email
    end
    expected_to = expected_to.sort_by { |address| address }.uniq
    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = []
    manager_role = Role.find_by_name("Manager")
    for manager in manager_role.users
      expected_cc << manager.email if manager.active?
    end
    input_gate_role = Role.find_by_name("PCB Input Gate")
    for input_gate in input_gate_role.users
      expected_cc << input_gate.email if input_gate.active?
    end
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)

  end

  def test_design_review_complete_notification
  
    #
    # Pre-Artwork Review
    response = TrackerMailer.create_design_review_complete_notification(
                 @mx234a_pre_art_dr,
                 @now)
                
    response_to = response.to.sort_by { |address| address }
    expected_to = []
    for review_result in @mx234a_pre_art_dr.design_review_results
      expected_to << User.find(review_result.reviewer_id).email
    end
    expected_to = expected_to.sort_by { |address| address }
    
    assert_equal("mx234a: Pre-Artwork Review is complete", 
                 response.subject)
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    assert_equal("The design information is located at " +
                 "#{Pcbtr::PCBTR_BASE_URL}design_review/view/1\n",
                 response.body)

    response_cc = response.cc.sort_by { |address| address }
    expected_cc = []
    manager_role = Role.find_by_name("Manager")
    for manager in manager_role.users
      expected_cc << manager.email if manager.active?
    end
    input_gate_role = Role.find_by_name("PCB Input Gate")
    for input_gate in input_gate_role.users
      expected_cc << input_gate.email if input_gate.active?
    end
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)

    #
    # Final Review
    response = TrackerMailer.create_design_review_complete_notification(
                 @mx234a_final_dr,
                 @now)
                
    response_to = response.to.sort_by { |address| address }
    expected_to = []
    for review_result in @mx234a_final_dr.design_review_results
      expected_to << User.find(review_result.reviewer_id).email
    end
    expected_to = expected_to.sort_by { |address| address }
    
    assert_equal("mx234a: Final Review is complete", 
                 response.subject)
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    assert_equal("The design information is located at " +
                 "#{Pcbtr::PCBTR_BASE_URL}design_review/view/4\n",
                 response.body)

    response_cc = response.cc.sort_by { |address| address }
    
    expected_final_cc = expected_cc
    designer = User.find(@mx234a_final_dr.design.designer_id)
    expected_final_cc << designer.email
    
    pcb_admin_role = Role.find_by_name("PCB Admin")
    for pcb_admin in pcb_admin_role.users
      expected_final_cc << pcb_admin.email if pcb_admin.active?
    end
    
    expected_final_cc = expected_final_cc.sort_by { |address| address }.uniq
    assert_equal(expected_final_cc, response_cc)
    
    #
    # Release Review
    response = TrackerMailer.create_design_review_complete_notification(
                 @mx234a_release_dr,
                 @now)
                
    response_to = response.to.sort_by { |address| address }
    expected_to = []
    for review_result in @mx234a_release_dr.design_review_results
      expected_to << User.find(review_result.reviewer_id).email
    end
    expected_to = expected_to.sort_by { |address| address }
    
    assert_equal("mx234a: Release Review is complete", 
                 response.subject)
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    assert_equal("The design information is located at " +
                 "#{Pcbtr::PCBTR_BASE_URL}design_review/view/5\n",
                 response.body)

    response_cc = response.cc.sort_by { |address| address }
    
    expected_release_cc = []
    manager_role = Role.find_by_name("Manager")
    for manager in manager_role.users
      expected_release_cc << manager.email if manager.active?
    end
    input_gate_role = Role.find_by_name("PCB Input Gate")
    for input_gate in input_gate_role.users
      expected_release_cc << input_gate.email if input_gate.active?
    end
    designer = User.find(@mx234a_release_dr.designer_id)
    expected_release_cc << designer.email
    expected_release_cc << "STD_DC_ECO_Inbox@notes.teradyne.com"
    
    expected_release_cc = expected_release_cc.sort_by { |address| address }.uniq
    assert_equal(expected_release_cc, response_cc)

  end

  def test_design_review_posting_notification
    #
    # Pre-Artwork Review
    response = TrackerMailer.create_design_review_posting_notification(
                 @mx234a_pre_art_dr,
                 'The requisite posting comment.',
                 false,
                 @now)
                
    response_to = response.to.sort_by { |address| address }
    expected_to = []
    for review_result in @mx234a_pre_art_dr.design_review_results
      expected_to << User.find(review_result.reviewer_id).email
    end
    expected_to = expected_to.sort_by { |address| address }
    
    assert_equal("mx234a: The Pre-Artwork review has been posted", 
                 response.subject)
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = []
    manager_role = Role.find_by_name("Manager")
    for manager in manager_role.users
      expected_cc << manager.email if manager.active?
    end
    input_gate_role = Role.find_by_name("PCB Input Gate")
    for input_gate in input_gate_role.users
      expected_cc << input_gate.email if input_gate.active?
    end
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
    expected_to = []
    for review_result in @mx234a_final_dr.design_review_results
      expected_to << User.find(review_result.reviewer_id).email
    end
    expected_to = expected_to.sort_by { |address| address }
    
    assert_equal("mx234a: The Final review has been reposted", 
                 response.subject)
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    
    expected_final_cc = expected_cc
    designer = User.find(@mx234a_final_dr.design.designer_id)
    expected_final_cc << designer.email
    
    pcb_admin_role = Role.find_by_name("PCB Admin")
    for pcb_admin in pcb_admin_role.users
      expected_final_cc << pcb_admin.email if pcb_admin.active?
    end
    
    expected_final_cc = expected_final_cc.sort_by { |address| address }.uniq
    assert_equal(expected_final_cc, response_cc)
    
  end

  def test_ipd_update

    response = TrackerMailer.create_ipd_update(@root_post,
                                               @now)
                 
    assert_equal("mx234a [IPD] - mx234a Thread 1 subject", 
                 response.subject)
                 
    response_to = response.to.sort_by { |address| address }
    expected_to = [@bob_g.email]
    expected_to = expected_to.sort_by { |address| address }.uniq
    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = []
    manager_role = Role.find_by_name("Manager")
    for manager in manager_role.users
      expected_cc << manager.email if manager.active?
    end
    input_gate_role = Role.find_by_name("PCB Input Gate")
    for input_gate in input_gate_role.users
      expected_cc << input_gate.email if input_gate.active?
    end

    poster = User.find(@root_post.user_id)
    expected_cc << poster.email
    for post in @root_post.direct_children
      expected_cc << User.find(post.user_id).email
    end
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)
    
  end

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

  def test_ping_summary

    response = TrackerMailer.create_ping_summary({},
                                                 @now)
                 
    assert_equal("Summary of reviewers who have not approved/waived design reviews", 
                 response.subject)
                 
    response_to = response.to.sort_by { |address| address }
    expected_to = []
    manager_role = Role.find_by_name("Manager")
    for manager in manager_role.users
      expected_to << manager.email if manager.active?
    end
    input_gate_role = Role.find_by_name("PCB Input Gate")
    for input_gate in input_gate_role.users
      expected_to << input_gate.email if input_gate.active?
    end
    expected_to = expected_to.sort_by { |address| address }.uniq
    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    assert_equal(nil,             response.cc)
    
  end

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
    expected_to = [@lee_s.email]
    expected_to = expected_to.sort_by { |address| address }.uniq
    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    assert_equal(nil,             response.cc)
    
  end
  
  
  def test_reassign_design_review_to_peer
  
    response = TrackerMailer.create_reassign_design_review_to_peer(
                 @lee_s,
                 @rich_a,
                 @scott_g,
                 @mx234a_pre_art_dr.design,
                 @hweng_role,
                 @now)
                 
    assert_equal("mx234a: You have been assigned to perform the HWENG review", 
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@rich_a.email]
    expected_to = expected_to.sort_by { |address| address }.uniq
    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = [@lee_s.email]
    manager_role = Role.find_by_name("Manager")
    for manager in manager_role.users
      expected_cc << manager.email if manager.active?
    end
    input_gate_role = Role.find_by_name("PCB Input Gate")
    for input_gate in input_gate_role.users
      expected_cc << input_gate.email if input_gate.active?
    end
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)

  end

  def test_reassign_design_review_from_peer
  
    response = TrackerMailer.create_reassign_design_review_from_peer(
                 @lee_s,
                 @rich_a,
                 @scott_g,
                 @mx234a_pre_art_dr.design,
                 @hweng_role,
                 @now)
                 
    assert_equal("mx234a: The HWENG review has been reassigned to Lee Schaff", 
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@rich_a.email]
    expected_to = expected_to.sort_by { |address| address }.uniq
    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = [@lee_s.email]
    manager_role = Role.find_by_name("Manager")
    for manager in manager_role.users
      expected_cc << manager.email if manager.active?
    end
    input_gate_role = Role.find_by_name("PCB Input Gate")
    for input_gate in input_gate_role.users
      expected_cc << input_gate.email if input_gate.active?
    end
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)

  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/tracker_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
