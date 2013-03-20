########################################################################
#
# Copyright 2012, by Teradyne, Inc., North Reading MA
#
# File: board_design_entry_mailer_test.rb
#
# This file contains the unit tests for the BoardDesignEntry Mailer model
#
# Revision History:
#   $Id$
#
########################################################################

require 'test_helper'

class BoardDesignEntryMailerTest < ActionMailer::TestCase

  FIXTURES_PATH = File.expand_path( "../../fixtures", __FILE__ ) 
  CHARSET = "utf-8"

  tests BoardDesignEntryMailer

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


  test "originator_board_design_entry_deletion" do

    response = BoardDesignEntryMailer.originator_board_design_entry_deletion(
               '666-666-a0 b',
               @lee_s)

    assert_equal('The 666-666-a0 b has been removed from the PCB Engineering ' +
                 'Entry list',
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@cathy_m.email, @jan_k.email].sort

    assert_equal(expected_to, response_to)
    assert_equal Pcbtr::SENDER,  response[:from].value

    response_cc = response.cc.sort_by { |address| address }

    expected_cc = [@lee_s.email, @jim_l.email].sort
    assert_equal(expected_cc, response_cc)

  end
  ##############################################################################

  
  test "board_design_entry_return_to_originator" do

    response = BoardDesignEntryMailer.board_design_entry_return_to_originator(
               board_design_entries(:la021c), @cathy_m)

    assert_equal('The 942-021-00 design entry has been returned by PCB',
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@lee_s.email]

    assert_equal(expected_to, response_to)
    assert_equal Pcbtr::SENDER,  response[:from].value

    response_cc = response.cc.sort_by { |address| address }

    expected_cc = [@cathy_m.email, @jan_k.email, @jim_l.email].sort
    assert_equal(expected_cc, response_cc)

  end
  ##############################################################################
  
  
  test "board_design_entry_submission" do

    response = BoardDesignEntryMailer.board_design_entry_submission(
               board_design_entries(:la021c))

    assert_equal('The 942-021-00 design entry has been submitted for entry to PCB Design',
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [@cathy_m.email, @jan_k.email, @jim_l.email].sort

    assert_equal(expected_to, response_to)
    assert_equal Pcbtr::SENDER,  response[:from].value

    response_cc = response.cc.sort_by { |address| address }

    expected_cc = [@lee_s.email].sort
    assert_equal(expected_cc, response_cc)

  end
  ##############################################################################

end