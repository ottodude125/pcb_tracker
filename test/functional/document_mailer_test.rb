########################################################################
#
# Copyright 2012, by Teradyne, Inc., North Reading MA
#
# File: document_mailer_test.rb
#
# This file contains the unit tests for the Document Mailer model
#
# Revision History:
#   $Id$
#
########################################################################

require 'test_helper'

class DocumentMailerTest < ActionMailer::TestCase
  FIXTURES_PATH = File.expand_path( "../../fixtures", __FILE__ ) 
  CHARSET = "utf-8"

  tests DocumentMailer

  #include ActionMailer::Quoting


  ##############################################################################
  def setup
    ActionMailer::Base.delivery_method    = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries         = []

    #@expected = TMail::Mail.new
    #@expected.set_content_type "text", "plain", { "charset" => CHARSET }
    
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
    
  end
  ##############################################################################


  test "attachment_update" do

    subject  = 'TESTING: A document has been attached'
    response = DocumentMailer.attachment_update(@mx234a_stackup_doc,
                                                      @lee_s,
                                                      subject)

    assert_equal("Catalyst/AC/(pcb252_234_a0_g): #{subject}",
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
    assert_equal Pcbtr::SENDER, response[:from].value

    expected_cc = @input_gate_email_list
    if mx234a_design.pcb_input_id > 0
      pcb_input_gate = User.find(mx234a_design.pcb_input_id)
      expected_cc.delete_if { |email| email == pcb_input_gate.email }
    end
    assert_equal(expected_cc, response.cc)

  end
  ##############################################################################


end
