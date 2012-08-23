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

require File.expand_path( "../../test_helper", __FILE__ ) 
require 'tracker_mailer'

class TrackerMailersTest < ActionMailer::TestCase
  FIXTURES_PATH = File.expand_path( "../../fixtures", __FILE__ ) 
  CHARSET = "utf-8"

  tests TrackerMailer

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


  test "broadcast_message" do

    recipients       = [@bala_g, @scott_g, @cathy_m]
    recipient_emails = recipients.collect { |user| user.email }
    response = TrackerMailer.broadcast_message('This is a test',
                                                      'Test Message!',
                                                      recipient_emails,
                                                      'Test_User_Group')

    assert_equal('This is a test',    response.subject)
    assert_equal(['Test_User_Group'], response.to)
    assert_equal Pcbtr::SENDER,              response[:from].value
    assert_equal(recipient_emails,    response.cc)
 

    recipients = [  @jan_k, @bob_g, @jim_l, @rich_a ]
    recipient_emails = recipients.collect { |user| user.email }
    response = TrackerMailer.broadcast_message('This is a test',
                                                      'Test Message!',
                                                      recipient_emails)

    assert_equal('This is a test',             response.subject)
#    assert_equal(['PCB_Design_Tracker_Users'], response.to)
    assert_equal Pcbtr::SENDER,              response[:from].value
    assert_equal(recipient_emails,             response.cc)

  end
  ##############################################################################


  private
    #def read_fixture(action)
    #  IO.readlines("#{FIXTURES_PATH}/tracker_mailer/#{action}")
    #end


    #def encode(subject)
    #  quoted_printable(subject, CHARSET)
    #end
end
