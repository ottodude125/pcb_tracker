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
           :board_design_entries,
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
           :ftp_notifications,
           :ipd_posts,
           :oi_assignments,
           :part_numbers,
           :platforms,
           :prefixes,
           :projects,
           :review_statuses,
           :roles_users,
           :review_types,
           :roles,
           :sections,
           :users)


  ##############################################################################
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
    
    @audit   = Audit.find(audits(:audit_mx234a).id)
    
    @mx234a_pre_art_dr   = design_reviews(:mx234a_pre_artwork)
    @mx234a_release_dr   = design_reviews(:mx234a_release)
    @mx234a_final_dr     = design_reviews(:mx234a_final)
    @mx234a_placement_dr = design_reviews(:mx234a_placement)
                           
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
    @bala_g  = users(:bala_g)
    
    @mx234a_stackup_doc = DesignReviewDocument.find(
                            design_review_documents(:mx234a_stackup_doc).id)
    
    @root_post     = ipd_posts(:mx234a_thread_one)
    @response_post = ipd_posts(:mx234a_thread_one_a)
    
    @now  = Time.now
    
  end


  ##############################################################################
  def test_peer_audit_complete
  
    peer = @audit.design.peer.name

    response = TrackerMailer.create_peer_audit_complete(@audit, @now)
    
    assert_equal(@audit.design.directory_name +
                 ': The peer auditor has completed the audit', 
                 response.subject)
    assert_equal(peer + ' has completed the peer audit review for the ' +
                 @audit.design.directory_name + "\n",
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
    
    assert_equal(@audit.design.directory_name +
                 ': The designer has completed the self-audit', 
                 response.subject)
    assert_equal(designer + ' has completed the self audit review for the ' +
                 @audit.design.directory_name + 
                 "\n\nYou can start your peer audit.\n",
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
  def test_ftp_notification
  
    ftp_notification = ftp_notifications(:mx234a)
    message  = "NO RESPONSE IS REQUIRED!\n"
    message += "NOTIFICATION THAT FILES HAVE BEEN FTP'D TO VENDOR FOR BOARD FABRICATION\n"
    message += "Date: " + Time.now.to_s + "\n"
    message += "Division: " + ftp_notification.division.name + "\n"
    message += "Assembly/BOM Number: " + ftp_notification.assembly_bom_number + "\n"
    message += "Design Files Located at: /hwnet/" + ftp_notification.design_center.pcb_path
    message += "/" + ftp_notification.design.name + "/public/\n"
    message += "Files Size, Date, and Name: " + ftp_notification.file_data + "\n"
    message += "Rev Date: " + ftp_notification.revision_date + "\n"
    message += "Vendor: " + ftp_notification.fab_house.name + "\n"

    response = TrackerMailer.create_ftp_notification(message,
                                                     ftp_notification,
                                                     @now)
    
    assert_equal(ftp_notification.design.directory_name +
                 ": Bare Board Files have been transmitted to " +
                 ftp_notification.fab_house.name, 
                 response.subject)
    assert_equal(message, response.body)

    reviewers = [ users(:espo),       users(:heng_k),
                  users(:lisa_a),     users(:rich_a),
                  users(:matt_d),     users(:jim_l),
                  users(:anthony_g),  users(:tom_f),
                  users(:lee_s) ].uniq.sort_by { |u| u.email }
    to_list   = reviewers.collect { |u| u.email }      
    assert_equal(to_list,          response.to.sort_by { |email| email })
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = [@cathy_m.email,
                   @bob_g.email,
                   @jan_k.email].sort_by { |address| address }
    assert_equal(expected_cc, response_cc)
    
  end


  ##############################################################################
  def test_final_review_warning
  
    design = @audit.design
    
    response = TrackerMailer.create_final_review_warning(@audit.design, @now)
     
    assert_equal('Notification of upcoming Final Review for ' + @audit.design.directory_name, 
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
  
    subject = "#{@mx234a_pre_art_dr.design.directory_name}::" +
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
    expected_cc = (@manager_email_list + @input_gate_email_list) - expected_to
    expected_cc << @bob_g.email
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
    review_result.save

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
    expected_cc = (@manager_email_list + @input_gate_email_list) - expected_to
    expected_cc << @bob_g.email
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
    review_result.save

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
    expected_cc = (@manager_email_list + @input_gate_email_list) - expected_to
    expected_cc << @bob_g.email
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
    
    assert_equal("pcb252_234_a0_g: Pre-Artwork Review is complete", 
                 response.subject)
    assert_equal(expected_to,      response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    assert_equal("The design information is located at " +
                 "#{Pcbtr::PCBTR_BASE_URL}design_review/view/1\n",
                 response.body)

    response_cc = response.cc.sort_by { |address| address }
    expected_cc = @manager_email_list + @input_gate_email_list
    expected_cc << @bob_g.email
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal((expected_cc - expected_to), response_cc)

    #
    # Final Review
    response = TrackerMailer.create_design_review_complete_notification(
                 @mx234a_final_dr,
                 @now)
                
    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_final_dr_emails
    
    assert_equal("pcb252_234_a0_g: Final Review is complete", 
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
    assert_equal((expected_final_cc - expected_to), response_cc)
    
    #
    # Release Review
    response = TrackerMailer.create_design_review_complete_notification(
                 @mx234a_release_dr,
                 @now)
                
    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_release_dr_emails
    
    assert_equal("pcb252_234_a0_g: Release Review is complete", 
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
    expected_release_cc << "STD_DC_ECO_Inbox@notes.teradyne.com" if ENV['RAILS_ENV'] == 'production'
    
    expected_release_cc << @bob_g.email
    expected_release_cc = expected_release_cc.sort_by { |address| address }.uniq
    assert_equal((expected_release_cc - expected_to), response_cc)

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
    
    assert_equal("pcb252_234_a0_g: The Pre-Artwork review has been posted", 
                 response.subject)
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = @manager_email_list + @input_gate_email_list
    expected_cc << @bob_g.email
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal((expected_cc - expected_to), response_cc)

    #
    # Final Review
    response = TrackerMailer.create_design_review_posting_notification(
                 @mx234a_final_dr,
                 'Yankees do not suck.  Their fans suck.',
                 true,
                 @now)

    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_final_dr_emails
    
    assert_equal("pcb252_234_a0_g: The Final review has been reposted", 
                 response.subject)
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    
    expected_final_cc = expected_cc + @pcb_admin_email_list
    designer = User.find(@mx234a_final_dr.design.designer_id)
    expected_final_cc << designer.email
    expected_final_cc = expected_final_cc.sort_by { |address| address }.uniq
    assert_equal((expected_final_cc - expected_to), response_cc)
    
  end


  ##############################################################################
  def test_ipd_update

    response = TrackerMailer.create_ipd_update(@root_post,
                                               @now)
                 
    assert_equal("pcb252_234_a0_g [IPD] - mx234a Thread 1 subject", 
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
    expected_cc += @root_post.users.collect{ |user| user.email }
    expected_cc  = expected_cc.sort_by { |address| address }.uniq
    
    assert_equal((expected_cc - expected_to), response_cc)
    
    response = TrackerMailer.create_ipd_update(@response_post,
                                               @now)
                 
    assert_equal("pcb252_234_a0_g [IPD] - mx234a Thread 1 First Response Subject", 
                 response.subject)
                 
    response_to = response.to.sort_by { |address| address }
    expected_to = [@bob_g.email, @lee_s.email].sort_by { |address| address }.uniq

    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    expected_cc = @manager_email_list + @input_gate_email_list

    poster = User.find(@root_post.user_id)
    expected_cc << poster.email
    expected_cc += @root_post.direct_children.collect { |post| post.user.email }
    expected_cc += @root_post.users.collect{ |user| user.email }
    expected_cc -= [@lee_s.email]
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

    subject = "Summary of reviewers who have not approved/waived design reviews"

    response = TrackerMailer.create_ping_summary({},{})
                                  
    response_to = response.to.sort_by { |address| address }
    expected_to = @manager_email_list + @input_gate_email_list
    expected_to = expected_to.sort_by { |address| address }.uniq
    
    assert_equal(subject,         response.subject)
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
                 
    assert_equal("pcb252_234_a0_g: You have been assigned to perform the Hardware Engineer (EE) review", 
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
  def notest_snapshot
  
    exception = Exception.new("Test Exeception")
    trace     = { :line_1 => 'first line', :line_2 => 'second_line'}
    session   = { :user   => @scott_g,
                  :info   => 'Session Info'}
    params    = { :action => 'test_action' }
    env       = {}
  
    response = TrackerMailer.create_snapshot(exception,
                                             trace,
                                             session,
                                             params,
                                             env,
                                             @now)
                 
    assert_equal("252-234-a0 g: You have been assigned to perform the Hardware Engineer (EE) review", 
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
                 
    assert_equal("pcb252_234_a0_g: The Hardware Engineer (EE) review has been reassigned to Lee Schaff", 
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
                 @mx234a_stackup_doc.design.part_number.pcb_display_name + 
                 " design", 
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
               
    expected_subj = @mx234a_final_dr.design.directory_name +
                    ' PEER AUDIT: A comment has been entered that requires ' +
                    'your attention'  
    assert_equal(expected_subj, response.subject)
    
    response_to = response.to.sort_by { |address| address }

    assert_equal([@scott_g.email],   response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    assert_equal([@rich_m.email], response.cc)
    
  end
  
  
  ##############################################################################
  def test_design_modification
  
    cc_list = []
    comment = 'design modifcation test comment'
    
    expected_body    = comment + "\n\n\n" +
                       "NOTE: The design information is located at <%= Pcbtr::PCBTR_BASE_URL %>design_review/view/<%= @design_review_id%>"
                       
    expected_subject = "The pcb252_234_a0_g Pre-Artwork Design Review has been modified by Cathy McLaren"

    response = TrackerMailer.create_design_modification(@cathy_m,
                                                        @mx234a_pre_art_dr.design,
                                                        comment,
                                                        cc_list)

    assert_equal(expected_subject, response.subject)

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
    response = TrackerMailer.create_design_modification(@cathy_m,
                                                        @mx234a_pre_art_dr.design,
                                                        comment,
                                                        cc_list)

    assert_equal(expected_subject, response.subject)

    response_to = response.to.sort_by { |address| address }
    
    assert_equal(expected_to.uniq.sort, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    
    response_cc = response.cc.sort_by { |address| address }
    assert_equal(cc_list, response_cc)

 
  end
  
  
  ##############################################################################
  def test_audit_team_updates
    
    teammate_list_updates =
      { 'self' => [ { :action   => 'Added',
                      :teammate => AuditTeammate.new(
                                     :audit_id   => @audit.id,
                                     :section_id => sections(:section_01_1),
                                     :user_id    => @siva_e.id,
                                     :self       => 1)},
                    { :action   => 'Added',
                      :teammate => AuditTeammate.new(
                                     :audit_id   => @audit.id,
                                     :section_id => sections(:section_01_2),
                                     :user_id    => @rich_m.id,
                                     :self       => 1)} ], 
        'peer' => [ { :action   => 'Added',
                      :teammate => AuditTeammate.new(
                                     :audit_id   => @audit.id,
                                     :section_id => sections(:section_01_1),
                                     :user_id    => @scott_g.id,
                                     :self       => 0)},
                    { :action   => 'Added',
                      :teammate => AuditTeammate.new(
                                     :audit_id   => @audit.id,
                                     :section_id => sections(:section_01_2),
                                     :user_id    => @cathy_m.id,
                                     :self       => 0)}] }

    response = TrackerMailer.create_audit_team_updates(@bob_g,
                                                       @audit,
                                                       teammate_list_updates,
                                                       @now)
                 
    assert_equal('The audit team for the ' + 
                 @audit.design.directory_name + ' has been updated', 
                 response.subject)
                 
    response_to = response.to.sort_by { |address| address }
    expected_to = [@scott_g.email, @rich_m.email, @cathy_m.email, @siva_e.email].sort
    assert_equal(expected_to,     response_to)
    assert_equal([Pcbtr::SENDER], response.from)
    assert_equal(@now.to_s,       response.date.to_s)

    expected_cc = [@bob_g.email, @jim_l.email, @jan_k.email].sort
    assert_equal(expected_cc, response.cc.sort.uniq)
    
  end
  
  
  ##############################################################################
  def test_notify_design_review_skipped

    response = TrackerMailer.create_notify_design_review_skipped(
                 @mx234a_placement_dr,
                 @mx234a_placement_dr.designer,
                 @now)
                
    assert_equal(@mx234a_placement_dr.design.part_number.pcb_display_name +
                 ': The ' + @mx234a_placement_dr.review_type.name +
                  ' design review has been skipped', 
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@jim_l.email, @cathy_m.email, @jan_k.email].sort
    
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    
    expected_cc = [@bob_g.email]
    assert_equal(expected_cc, response_cc)
    
  end
  
  
  ##############################################################################
  def test_originator_board_design_entry_deletion

    response = TrackerMailer.create_originator_board_design_entry_deletion(
               '666-666-a0 b',
               @lee_s,
               @now)
                
    assert_equal('The 666-666-a0 b has been removed from the PCB Engineering ' +
                 'Entry list', 
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@cathy_m.email, @jan_k.email].sort
    
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    
    expected_cc = [@lee_s.email, @jim_l.email].sort
    assert_equal(expected_cc, response_cc)
    
  end
  
  
  ##############################################################################
  def test_board_design_entry_return_to_originator

    response = TrackerMailer.create_board_design_entry_return_to_originator(
               board_design_entries(:la021c),
               @cathy_m,
               @now)
                
    assert_equal('The ' + board_design_entries(:la021c).part_number.pcb_display_name +
                 ' design entry has been returned by PCB', 
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@lee_s.email]
    
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    
    expected_cc = [@cathy_m.email, @jan_k.email, @jim_l.email].sort
    assert_equal(expected_cc, response_cc)
    
  end
  
  
  ##############################################################################
  def test_board_design_entry_submission

    response = TrackerMailer.create_board_design_entry_submission(
               board_design_entries(:la021c),
               @now)
                
    assert_equal('The ' + board_design_entries(:la021c).part_number.pcb_display_name +
                 ' has been submitted for entry to PCB Design',
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@cathy_m.email, @jan_k.email, @jim_l.email].sort
    
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    
    expected_cc = [@lee_s.email].sort
    assert_equal(expected_cc, response_cc)
    
  end
  
  
  ##############################################################################
  def test_reviewer_modification_notification

    role = roles(:mechanical)
    
    response = TrackerMailer.create_reviewer_modification_notification(
                 @mx234a_final_dr,
                 role,
                 users(:tom_f),
                 users(:dave_l),
                 users(:dave_l),
                 @now)
                
    assert_equal(role.display_name + ' reviewer changed for ' +
                 @mx234a_final_dr.design.part_number.pcb_display_name + ' ' +
                 @mx234a_final_dr.review_type.name + ' Design Review',
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [users(:dave_l).email]
    
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    
    expected_cc = [@cathy_m.email, 
                   @jan_k.email, 
                   @jim_l.email, 
                   users(:tom_f).email].sort
    assert_equal(expected_cc, response_cc)
    
  end
  
  
  ##############################################################################
  def test_oi_assignment_notification
    
    oi_assignment = oi_assignments(:first)
    oi_assignment_list = [oi_assignment]
    response = TrackerMailer.create_oi_assignment_notification(
                 oi_assignment_list,
                 @now)
                
    assert_equal("Work Assignment Created for the " +
                 oi_assignment.oi_instruction.design.directory_name,
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@siva_e.email]
    
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    
    expected_cc = [@cathy_m.email, 
                   @scott_g.email,
                   @jan_k.email, 
                   @jim_l.email, 
                   @bala_g.email].sort
    assert_equal(expected_cc, response_cc)
    
  end
  
  
  ##############################################################################
  def test_oi_task_update
    
    oi_assignment = oi_assignments(:first)
    response = TrackerMailer.create_oi_task_update(oi_assignment,
                                                   @siva_e,
                                                   'completed',
                                                   'not' == 'reset',
                                                   @now)
                
    assert_equal(oi_assignment.oi_instruction.design.directory_name +
                 ':: Work Assignment Update - Completed',
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@scott_g.email]
    
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    
    expected_cc = [@cathy_m.email, 
                   @siva_e.email,
                   @jan_k.email, 
                   @jim_l.email, 
                   @bala_g.email].sort
    assert_equal(expected_cc, response_cc)

    
    response = TrackerMailer.create_oi_task_update(oi_assignment,
                                                   @scott_g,
                                                   'not' == 'completed',
                                                   'reset',
                                                   @now)
                
    assert_equal(oi_assignment.oi_instruction.design.directory_name +
                 ':: Work Assignment Update - Reopened',
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@siva_e.email]
    
    assert_equal(expected_to, response_to)
    assert_equal([Pcbtr::SENDER],  response.from)
    assert_equal(@now.to_s,        response.date.to_s)
    
    response_cc = response.cc.sort_by { |address| address }
    
    expected_cc = [@cathy_m.email, 
                   @scott_g.email,
                   @jan_k.email, 
                   @jim_l.email, 
                   @bala_g.email].sort
    assert_equal(expected_cc, response_cc)

  end
 
  
   
  ##############################################################################
  def test_broadcast_message
    
    recipients       = [@bala_g, @scott_g, @cathy_m]
    recipient_emails = recipients.collect { |user| user.email }
    response = TrackerMailer.create_broadcast_message('This is a test',
                                                      'Test Message!',
                                                      recipients,
                                                      'Test_User_Group',
                                                      @now)
                
    assert_equal('This is a test',    response.subject)
    assert_equal(['Test_User_Group'], response.to)
    assert_equal([Pcbtr::SENDER],     response.from)
    assert_equal(@now.to_s,           response.date.to_s)
    assert_equal(recipient_emails,    response.bcc)
    assert_nil(response.cc)


    recipients = [  @jan_k, @bob_g, @jim_l, @rich_a ]
    recipient_emails = recipients.collect { |user| user.email }
    response = TrackerMailer.create_broadcast_message('This is a test',
                                                      'Test Message!',
                                                      recipients,
                                                      @now)
                
    assert_equal('This is a test',             response.subject)
#    assert_equal(['PCB_Design_Tracker_Users'], response.to)
    assert_equal([Pcbtr::SENDER],              response.from)
    assert_equal(recipient_emails,             response.bcc)
    assert_nil(response.cc)
    assert(@now.to_i          <= response.date.to_i)
    assert(response.date.to_i <= Time.now.to_i)

  end


  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/tracker_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
