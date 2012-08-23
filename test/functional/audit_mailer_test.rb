########################################################################
#
# Copyright 2012, by Teradyne, Inc., North Reading MA
#
# File: audit_mailer_test.rb
#
# This file contains the unit tests for the Audit Mailer model
#
# Revision History:
#   $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ ) 
require 'test_helper'

class AuditMailerTest < ActionMailer::TestCase

  FIXTURES_PATH = File.expand_path( "../../fixtures", __FILE__ ) 
  CHARSET = "utf-8"

  tests AuditMailer

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
  
  
  test "peer_audit_complete" do

    peer = @audit.design.peer.name
     expected_subject  = 'Catalyst/AC/(pcb252_234_a0_g): The peer audit is complete'
     expected_body     = peer +
                          ' has completed the peer audit review for the ' +
                          @audit.design.directory_name + "\n"

     expected_cc = [@cathy_m.email,
                   @scott_g.email,
                   @jan_k.email,
                   @jim_l.email].sort.join(",")

     response = AuditMailer.peer_audit_complete(@audit)

     assert_equal([users(:bob_g).email], response.to)
     assert_equal Pcbtr::SENDER, response[:from].value
     assert_equal(expected_subject,      response.subject)
     response_cc = response.cc.sort.join(",")
     assert_equal(expected_cc,           response_cc)
     assert_equal(expected_body,         response.body.to_s)

  end
  ##############################################################################


  test "self_audit_complete" do

    designer = User.find(@audit.design.designer_id).name

    response = AuditMailer.self_audit_complete(@audit)

    assert_equal("Catalyst/AC/(pcb252_234_a0_g): The designer's self audit is complete",
                 response.subject)
    assert_equal(designer + ' has completed the self audit review for the ' +
                 @audit.design.directory_name +
                 "\n\nYou can start your peer audit.\n",
                 response.body.to_s)
    assert_equal([@scott_g.email], response.to)
    assert_equal Pcbtr::SENDER, response[:from].value

    response_cc = response.cc.sort_by { |address| address }
    expected_cc = [@cathy_m.email,
                   @bob_g.email,
                   @jan_k.email,
                   @jim_l.email].sort_by { |address| address }
    assert_equal(expected_cc, response_cc)

  end
  ##############################################################################


  test "final_review_warning" do

    design = @audit.design

    response = AuditMailer.final_review_warning(@audit.design)

    assert_equal('Catalyst/AC/(pcb252_234_a0_g): Notification of upcoming Final Review',
                 response.subject)
    assert_equal("Attention! Peer review is underway.  Final review/approval " +
                 "will be required in a few days.",
                 response.body.to_s)

    reviewers = [ users(:espo),       users(:heng_k),
                  users(:lisa_a),     users(:rich_a),
                  users(:matt_d),     users(:jim_l),
                  users(:anthony_g),  users(:tom_f),
                  users(:lee_s) ].uniq.sort_by { |u| u.email }
    to_list   = reviewers.collect { |u| u.email }
    assert_equal(to_list,          response.to.sort_by { |email| email })
    assert_equal Pcbtr::SENDER, response[:from].value

    expected_cc = [@cathy_m.email, @bob_g.email, @jan_k.email].sort_by { |address| address }
    assert_equal(expected_cc, response.cc.sort_by { |email| email })

  end
  ##############################################################################


  test "audit_team_updates" do

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

    response = AuditMailer.audit_team_updates(@bob_g,
                                                @audit,
                                                teammate_list_updates)

    assert_equal('Catalyst/AC/(pcb252_234_a0_g): The audit team has been updated',
                 response.subject)

    response_to = response.to.sort_by { |address| address }
    expected_to = [@scott_g.email, @rich_m.email, @cathy_m.email, @siva_e.email].sort
    assert_equal(expected_to,     response_to)
    assert_equal Pcbtr::SENDER, response[:from].value

    expected_cc = [@bob_g.email, @jim_l.email, @jan_k.email].sort
    assert_equal(expected_cc, response.cc.sort.uniq)

  end
  ##############################################################################


  test "audit_update" do

    response = AuditMailer.audit_update(design_checks(:design_check_5),
                                                 'No comment',
                                                 @scott_g,
                                                 @rich_m)

    expected_subj = 'Catalyst/AC/(pcb252_234_a0_g): PEER AUDIT - A comment ' +
                    'has been entered that requires your attention'
    assert_equal(expected_subj, response.subject)

    response_to = response.to.sort_by { |address| address }

    assert_equal([@scott_g.email],   response_to)
    assert_equal Pcbtr::SENDER, response[:from].value
    assert_equal([@rich_m.email], response.cc)
  end
  ##############################################################################

end
