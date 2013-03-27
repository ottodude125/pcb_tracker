########################################################################
#
# Copyright 2012, by Teradyne, Inc., North Reading MA
#
# File: design_review_mailer_test.rb
#
# This file contains the unit tests for the Design Review Mailer model
#
# Revision History:
#   $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ ) 
require 'test_helper'

class DesignReviewMailerTest < ActionMailer::TestCase

  FIXTURES_PATH = File.expand_path( "../../fixtures", __FILE__ ) 
  CHARSET = "utf-8"
  
  setup do
    ActionMailer::Base.delivery_method    = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries         = []

    #@expected = TMail::Mail.new
    #@expected.set_content_type "text", "plain", { "charset" => CHARSET }
    
    @design_review = design_reviews(:mx234a_pre_artwork)
    @comment = design_review_comments(:comment_one)
    
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

    @slm_vendor_email_list = []
    slm_vendor_role = Role.find_by_name("SLM-Vendor Notify")
    for slm_vendor in slm_vendor_role.users
      @slm_vendor_email_list << slm_vendor.email if slm_vendor.active?
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
    
   end
  ##############################################################################

=begin
  test "posting" do
    mail = DesignReviewMailer.design_review_posting_notification(
           @design_review, @comment)
    assert_match( /The Pre-Artwork design review has been posted/, mail.subject )
    assert_equal 14, mail.to.size
    assert_equal Pcbtr::SENDER, mail[:from].value
    assert_match( /posted the Pre-Artwork review/, mail.body.encoded )
  end
  ##############################################################################
=end  
  
  test "design_review_posting_notification" do
    #
    # Pre-Artwork Review
    response = DesignReviewMailer.design_review_posting_notification(
                 @mx234a_pre_art_dr,
                 'The requisite posting comment.',
                 false)

    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_pre_art_dr_emails

    assert_equal('Catalyst/AC/(pcb252_234_a0_g): The Pre-Artwork design review has been posted',
                 response.subject)
    assert_equal(expected_to, response_to)
    assert_equal Pcbtr::SENDER,  response[:from].value

    response_cc = response.cc.sort_by { |address| address }
    expected_cc = @manager_email_list + @input_gate_email_list + @slm_vendor_email_list
    expected_cc << @bob_g.email
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)

    #
    # Final Review
    response = DesignReviewMailer.design_review_posting_notification(
                 @mx234a_final_dr,
                 'Yankees do not suck.  Their fans suck.',
                 true)

    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_final_dr_emails

    assert_equal('Catalyst/AC/(pcb252_234_a0_g): The Final design review has been reposted',
                 response.subject)
    assert_equal(expected_to, response_to)
    assert_equal Pcbtr::SENDER,  response[:from].value

    response_cc = response.cc.sort_by { |address| address }

    expected_final_cc = expected_cc + @pcb_admin_email_list
    designer = User.find(@mx234a_final_dr.design.designer_id)
    expected_final_cc << designer.email
    expected_final_cc = expected_final_cc.sort_by { |address| address }.uniq
    assert_equal(expected_final_cc, response_cc)

  end
  ##############################################################################

=begin
  test "update" do
    mail = DesignReviewMailer.design_review_update(
      @jim_l, @design_review, @comment)
    assert_equal "Update", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal Pcbtr::SENDER, mail[:from].value
    assert_match "Hi", mail.body.encoded
  end
  ##############################################################################
=end
  
  test "design_review_update" do

    subject = 'Catalyst/AC/(pcb252_234_a0_g): ' + @mx234a_pre_art_dr.review_type.name

    #
    # Test a comment only update.
    response = DesignReviewMailer.design_review_update(
                 @cathy,
                 @mx234a_pre_art_dr,
                 true,
                 {})

    assert_equal(subject + " - Comments added",
                 response.subject)

    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_pre_art_dr_emails

    assert_equal(expected_to,     response_to)
    assert_equal Pcbtr::SENDER, response[:from].value

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

    response = DesignReviewMailer.design_review_update(
                 @rich_a,
                 @mx234a_pre_art_dr,
                 false,
                 {:TDE => 'APPROVED'})

    assert_equal(subject + "  TDE - APPROVED - No comments",
                 response.subject)

    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_pre_art_dr_emails

    assert_equal(expected_to,     response_to)
    assert_equal Pcbtr::SENDER, response[:from].value

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

    response = DesignReviewMailer.design_review_update(
                 @rich_a,
                 @mx234a_pre_art_dr,
                 true,
                 {:TDE   => 'WAIVED'})

    assert_equal(subject + "  TDE - WAIVED - See comments",
                 response.subject)

    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_pre_art_dr_emails

    assert_equal(expected_to,     response_to)
    assert_equal Pcbtr::SENDER, response[:from].value

    response_cc = response.cc.sort_by { |address| address }
    expected_cc = (@manager_email_list + @input_gate_email_list) - expected_to
    expected_cc << @bob_g.email
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)

  end
  ##############################################################################

=begin
  test "complete" do
    mail = DesignReviewMailer.design_review_complete_notification(@design_review)
    assert_match( /design review is complete/, mail.subject )
    assert_equal 14, mail.to.size
    assert_equal Pcbtr::SENDER, mail[:from].value
    assert_match( /design review is complete/, mail.body.encoded )
  end  
  ##############################################################################
=end  
  
  test "design_review_complete_notification" do

    #
    # Pre-Artwork Review
    response = DesignReviewMailer.design_review_complete_notification(
                 @mx234a_pre_art_dr)

    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_pre_art_dr_emails

    assert_equal('Catalyst/AC/(pcb252_234_a0_g): The Pre-Artwork design review is complete',
                 response.subject)
    assert_equal(expected_to,      response_to)
    assert_equal Pcbtr::SENDER,  response[:from].value

    assert_equal("The design information is located at \n" +
                 "#{Pcbtr::PCBTR_BASE_URL}design_review/view/1\n",
                 response.body.to_s)

    response_cc = response.cc.sort_by { |address| address }
    expected_cc = @manager_email_list + @input_gate_email_list
    expected_cc << @bob_g.email
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal((expected_cc - expected_to), response_cc)

    #
    # Final Review
    response = DesignReviewMailer.design_review_complete_notification(@mx234a_final_dr)

    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_final_dr_emails

    assert_equal('Catalyst/AC/(pcb252_234_a0_g): The Final design review is complete',
                 response.subject)
    assert_equal(expected_to, response_to)
    assert_equal Pcbtr::SENDER,  response[:from].value

    assert_equal("The design information is located at \n" +
                 "#{Pcbtr::PCBTR_BASE_URL}design_review/view/4\n",
                 response.body.to_s)

    response_cc = response.cc.sort_by { |address| address }

    expected_final_cc = expected_cc + @pcb_admin_email_list
    designer = User.find(@mx234a_final_dr.design.designer_id)
    expected_final_cc << designer.email
    expected_final_cc = expected_final_cc.sort_by { |address| address }.uniq
    assert_equal((expected_final_cc - expected_to), response_cc)

    #
    # Release Review
    response = DesignReviewMailer.design_review_complete_notification(
                 @mx234a_release_dr)

    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_release_dr_emails

    assert_equal('Catalyst/AC/(pcb252_234_a0_g): The Release design review is complete',
                 response.subject)
    assert_equal(expected_to, response_to)
    assert_equal Pcbtr::SENDER,  response[:from].value

    assert_equal("The design information is located at \n" +
                 "#{Pcbtr::PCBTR_BASE_URL}design_review/view/5\n",
                 response.body.to_s)

    response_cc = response.cc.sort_by { |address| address }

    expected_release_cc = @manager_email_list + @input_gate_email_list
    designer = User.find(@mx234a_release_dr.designer_id)
    expected_release_cc << designer.email

    expected_release_cc << @bob_g.email
    expected_release_cc = expected_release_cc.sort_by { |address| address }.uniq
    assert_equal((expected_release_cc - expected_to), response_cc)

  end
  ##############################################################################

=begin
  test "reassign_to_peer" do
    mail = DesignReviewMailer.reassign_to_peer
    assert_equal "Reassign to peer", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end
  ##############################################################################


  test "reassign_from_peer" do
    mail = DesignReviewMailer.reassign_from_peer
    assert_equal "Reassign from peer", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end
  ##############################################################################


  test "skipped" do
    mail = DesignReviewMailer.skipped
    assert_equal "Skipped", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end
  ##############################################################################
=end

  test "notify_design_review_skipped" do

    response = DesignReviewMailer.notify_design_review_skipped(
                 @mx234a_placement_dr,
                 @mx234a_placement_dr.designer)

    assert_equal('Catalyst/AC/(pcb252_234_a0_g): The '  +
                 @mx234a_placement_dr.review_type.name  +
                 ' design review has been skipped',
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@jim_l.email, @cathy_m.email, @jan_k.email].sort

    assert_equal(expected_to, response_to)
    assert_equal Pcbtr::SENDER,  response[:from].value

    response_cc = response.cc.sort_by { |address| address }

    expected_cc = [@bob_g.email]
    assert_equal(expected_cc, response_cc)

  end
  ##############################################################################


 test "ftp_notification" do

    ftp_notification = ftp_notifications(:mx234a)
    message  = ""
    message += "NO RESPONSE IS REQUIRED!\n"
    message += "NOTIFICATION THAT FILES HAVE BEEN FTP'D TO VENDOR FOR BOARD FABRICATION\n"
    message += "Date: " + Time.now.to_s + "\n"
    message += "Division: " + ftp_notification.division.name + "\n"
    message += "Assembly/BOM Number: " + ftp_notification.assembly_bom_number + "\n"
    message += "Design Files Located at: /hwnet/" + ftp_notification.design_center.pcb_path
    message += "/" + ftp_notification.design.name + "/public/\n"
    message += "Files Size, Date, and Name: " + ftp_notification.file_data + "\n"
    message += "Rev Date: " + ftp_notification.revision_date + "\n"
    message += "Vendor: " + ftp_notification.fab_house.name + "\n"

    recipients  = ""
    recipients += "recipents: espedicto_pichardo@notes.teradyne.com, "
    recipients += "heng_kit_too@notes.teradyne.com, "
    recipients += "lee_schaff@notes.teradyne.com, "
    recipients += "tom_flack@notes.teradyne.com, "
    recipients += "anthony_gentile@notes.teradyne.com, "
    recipients += "James_Light@notes.teradyne.com, "
    recipients += "matt_disanzo@notes.teradyne.com, "
    recipients += "rich_ahamed@notes.teradyne.com, "
    recipients += "lisa_austin@notes.teradyne.com\n"
    recipients += "cc       : Robert_Goldin@notes.teradyne.com, "
    recipients += "jan_kasting@notes.teradyne.com, "
    #recipients += "James_Light@notes.teradyne.com, "
    recipients += "Cathy_McLaren@notes.teradyne.com\n"
    #recipients += "bcc      : \n"

    response = DesignReviewMailer.ftp_notification(message, ftp_notification)

    assert_equal('Catalyst/AC/(pcb252_234_a0_g): Bare Board Files have been transmitted to ' +
                 ftp_notification.fab_house.name,
                 response.subject)
    assert_equal( recipients + message, response.body.to_s)

    reviewers = [ users(:espo),       users(:heng_k),
                  users(:lisa_a),     users(:rich_a),
                  users(:matt_d),     users(:jim_l),
                  users(:anthony_g),  users(:tom_f),
                  users(:lee_s) ].uniq.sort_by { |u| u.email }
    to_list   = reviewers.collect { |u| u.email }
    assert_equal(to_list,          response.to.sort_by { |email| email })
    assert_equal Pcbtr::SENDER,  response[:from].value

    response_cc = response.cc.sort_by { |address| address }
    expected_cc = [@cathy_m.email,
                   @bob_g.email,
                   @jan_k.email].sort_by { |address| address }
    assert_equal(expected_cc, response_cc)

  end
  ##############################################################################


  test "reassign_design_review_to_peer" do

    response = DesignReviewMailer.reassign_design_review_to_peer(
                 @lee_s,
                 @rich_a,
                 @scott_g,
                 @mx234a_pre_art_dr,
                 @hweng_role)

    assert_equal('Catalyst/AC/(pcb252_234_a0_g): You have been assigned to ' +
                 'perform the Hardware Engineer (EE) review',
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@rich_a.email].sort_by { |address| address }.uniq

    assert_equal(expected_to,     response_to)
    assert_equal Pcbtr::SENDER, response[:from].value

    response_cc = response.cc.sort_by { |address| address }
    expected_cc = [@lee_s.email] + @manager_email_list + @input_gate_email_list
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)

  end
  ##############################################################################
  
  
  test "reassign_design_review_from_peer" do

    response = DesignReviewMailer.reassign_design_review_from_peer(
                 @lee_s,
                 @rich_a,
                 @scott_g,
                 @mx234a_pre_art_dr,
                 @hweng_role)

    assert_equal('Catalyst/AC/(pcb252_234_a0_g): The Hardware Engineer (EE) ' +
                 'review has been reassigned to Lee Schaff',
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@rich_a.email].sort_by { |address| address }.uniq

    assert_equal(expected_to,     response_to)
    assert_equal Pcbtr::SENDER, response[:from].value

    response_cc = response.cc.sort_by { |address| address }
    expected_cc = [@lee_s.email] + @manager_email_list + @input_gate_email_list
    expected_cc = expected_cc.sort_by { |address| address }.uniq
    assert_equal(expected_cc, response_cc)

  end
  ##############################################################################

end
