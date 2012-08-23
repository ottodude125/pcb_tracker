########################################################################
#
# Copyright 2012, by Teradyne, Inc., North Reading MA
#
# File: design_mailer_test.rb
#
# This file contains the unit tests for the Design Mailer model
#
# Revision History:
#   $Id$
#
########################################################################
require File.expand_path( "../../test_helper", __FILE__ ) 
require 'test_helper'

class DesignMailerTest < ActionMailer::TestCase
  
  FIXTURES_PATH = File.expand_path( "../../fixtures", __FILE__ ) 
  CHARSET = "utf-8"

  tests DesignMailer

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


  test "design_modification" do

    cc_list = []
    comment = 'design modifcation test comment'

    expected_body    = comment + "\n\n\n" +
                       "NOTE: The design information is located at " +
                       "<%= Pcbtr::PCBTR_BASE_URL %>design_review/view/<%= @design_review_id%>"

    expected_subject = 'Catalyst/AC/(pcb252_234_a0_g): The Pre-Artwork design review has been modified by Cathy McLaren'
    
    response = DesignMailer.design_modification(@cathy_m,
                                                        @mx234a_pre_art_dr.design,
                                                        comment,
                                                        cc_list)
   
    assert_equal(expected_subject, response.subject)

    response_to = response.to.sort_by { |address| address }
    expected_to = @mx234a_pre_art_dr_emails

    # Add the designer, peer, and input gate to the 'To:' field.
    expected_to += [@bob_g.email, @scott_g.email, @cathy_m.email]

    assert_equal(expected_to.uniq.sort, response_to)
    assert_equal Pcbtr::SENDER,  response[:from].value

    response_cc = response.cc.sort_by { |address| address }
    assert_equal([@jan_k.email], response_cc)

    cc_list = [@rich_m.email, @siva_e.email, @jan_k.email].sort_by { |address| address }
    response = DesignMailer.design_modification(@cathy_m,
                                                        @mx234a_pre_art_dr.design,
                                                        comment,
                                                        cc_list)

    assert_equal(expected_subject, response.subject)

    response_to = response.to.sort_by { |address| address }

    assert_equal(expected_to.uniq.sort, response_to)
    assert_equal Pcbtr::SENDER,  response[:from].value

    response_cc = response.cc.sort_by { |address| address }
    assert_equal(cc_list, response_cc)
    

  end
  ##############################################################################
 
 
   test "reviewer_modification_notification" do

    role = roles(:mechanical)

    response = DesignMailer.reviewer_modification_notification(
                 @mx234a_final_dr,
                 role,
                 users(:tom_f),
                 users(:dave_l),
                 users(:dave_l) )

    assert_equal('Catalyst/AC/(pcb252_234_a0_g): ' +
                 role.display_name                 +
                 ' reviewer changed for the '      +
                 @mx234a_final_dr.review_type.name +
                 ' design review',
                 response.subject)
    response_to = response.to.sort_by { |address| address }
    expected_to = [users(:dave_l).email]

    assert_equal(expected_to, response_to)
    assert_equal Pcbtr::SENDER,  response[:from].value

    response_cc = response.cc.sort_by { |address| address }

    expected_cc = [@cathy_m.email,
                   @jan_k.email,
                   @jim_l.email,
                   users(:tom_f).email].sort
    assert_equal(expected_cc, response_cc)

  end
  ##############################################################################


  test "reviewer_role_creation_notification" do
     
  end

end
