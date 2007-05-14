########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: audit_controller_test.rb
#
# This file contains the functional tests for the audit_controller
#
# $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'
require 'audit_controller'

# Re-raise errors caught by the controller.
class AuditController; def rescue_action(e) raise e end; end

class AuditControllerTest < Test::Unit::TestCase


  def setup
    @controller = AuditController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @emails     = ActionMailer::Base.deliveries
    @emails.clear
    
    @siva_e  = users(:siva_e)
    @scott_g = users(:scott_g)
    @bob_g   = users(:bob_g)
    @rich_m  = users(:rich_m)
    @mathi_n = users(:mathi_n)
  end


  fixtures(:audit_comments,
           :audit_teammates,
           :audits,
           :boards,
           :checklists,
           :checks,
           :designs,
           :design_checks,
           :design_review_results,
           :platforms,
           :projects,
           :prefixes,
           :review_types,
           :revisions,
           :roles,
           :roles_users,
           :sections,
           :subsections,
           :users)
           
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false


  Not_Authorized = 'You are not authorized to view or modify ' +
    'audit information - check your role'


  ######################################################################
  #
  # test_perform_checks
  #
  # Description:
  # This method does the functional testing of the perform_checks method
  # from the AuditController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def test_perform_checks

    # Log in as a designer and perform the checks.
    user = @scott_g
    @request.session[:user]        = user
    @request.session[:active_role] = Role.find_by_name('Designer')
    @request.session[:roles]       = user.roles


    # New Design
    post(:perform_checks,
         :audit_id      => audits(:audit_mx234b).id,
         :subsection_id => subsections(:subsect_30_000).id)
    
    assert_equal(audits(:audit_mx234b).id,        assigns(:audit).id)
    assert_equal(subsections(:subsect_30_000).id, assigns(:subsection).id)
    assert_equal(sections(:section_20_000).id,    assigns(:subsection).section.id)
    assert_equal(15,                 assigns(:total_checks)[:designer])
    assert_equal(9,                  assigns(:total_checks)[:peer])
    assert_equal(4,                  assigns(:checks).size)

    check_id        = 10000
    design_check_id = 20000
    checks = assigns(:checks)
    checks.each do |check|
      assert_equal(check_id,        check.id)
      assert_equal(design_check_id, check[:design_check].id)
      assert_equal(0,               check[:design_check].audit_comments.size)
      check_id        += 1
      design_check_id += 1
    end

#    # Date Code Design
    audit      = audits(:audit_la453a_eco1)
    section    = sections(:section_20_000)
    subsection = subsections(:subsect_30_000)
    post(:perform_checks,
         :audit_id      => audit.id,
         :subsection_id => subsection.id)

    assert_equal(audit.id,      assigns(:audit).id)
    assert_equal(subsection.id, assigns(:subsection).id)
    assert_equal(section.id,    assigns(:subsection).section.id)
    assert_equal(7,             assigns(:total_checks)[:designer])
    assert_equal(5,             assigns(:total_checks)[:peer])
    assert_equal(3,             assigns(:checks).size)

    check_id        = 10000
    design_check_id = 20600
    checks = assigns(:checks).each do |check|
      assert_equal(check_id,        check.id)
      assert_equal(design_check_id, check[:design_check].id)
      assert_equal(0,               check[:design_check].audit_comments.size)
      check_id        += 1
      design_check_id += 1
    end

    # Dot Rev Design
    audit      = audits(:audit_la453a1)
    section    = sections(:section_20_000)
    subsection = subsections(:subsect_30_000)
    post(:perform_checks, 
         :audit_id      => audit.id, 
         :subsection_id => subsection.id)
    
    assert_equal(audit.id,      assigns(:audit).id)
    assert_equal(subsection.id, assigns(:subsection).id)
    assert_equal(section.id,    assigns(:subsection).section.id)
    assert_equal(7,             assigns(:total_checks)[:designer])
    assert_equal(5,             assigns(:total_checks)[:peer])
    assert_equal(1,             assigns(:checks).size)

    check_id        = 10003
    design_check_id = 20500

    assigns(:checks).each do |check|
      assert_equal(check_id,        check.id)
      assert_equal(design_check_id, check[:design_check].id)
      assert_equal(0,               check[:design_check].audit_comments.size)
      check_id        += 1
      design_check_id += 1
    end
  end


  ######################################################################
  #
  # test_update_design_checks
  #
  # Description:
  # This method does the functional testing of the update_design_checks
  # method from the AuditController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def test_update_design_checks

    # Log in as a designer and get the audit listing.
    designer = @rich_m
    set_user(@rich_m.id, 'Designer')

    audit = Audit.find(audits(:audit_mx234b).id)
    assert_equal(designer.id, audit.design.designer_id)
    assert(!audit.designer_complete?)
    assert(!audit.auditor_complete?)
    assert_equal(1, audit.audit_teammates.size)
    
    assert_equal(0, @emails.size)
    
    start_time = Time.now


    # This check should fail to update because no comment is included.
    post(:update_design_checks,
         :audit         => {:id => audits(:audit_mx234b).id},
         :subsection    => {:id => subsections(:subsect_30_000).id},
         :check_10000   => {
           :designer_result => 'Waived',
           :design_check_id => '20000',
           :comment         => ''},
         :check_10001   => {
           :design_check_id => '20001',
           :comment         => ''},
         :check_10002   => {
           :design_check_id => '20002',
           :comment         => ''},
         :check_10003   => {
           :design_check_id => '20003',
           :comment         => ''})

    post(:perform_checks,
         :audit_id      => audits(:audit_mx234b).id,
         :subsection_id => subsections(:subsect_30_000).id)

    assert_equal(0, assigns(:audit).designer_completed_checks)
    assert_equal(0, assigns(:audit).auditor_completed_checks)

    audit.reload
    assert_equal(1, audit.audit_teammates.size)

    assigns(:checks).each do |check|
      assert_equal('None', check[:design_check].designer_result)
      assert_equal(0,      check[:design_check].audit_comments.size)
    end 


    post(:update_design_checks,
         :audit         => {:id => audits(:audit_mx234b).id},
         :subsection    => {:id => subsections(:subsect_30_000).id},
         :check_10000   => {
           :designer_result => 'Waived',
           :design_check_id => '20000',
           :comment         => 'This is not needed.'},
         :check_10001   => {
           :designer_result => 'Verified',
           :design_check_id => '20001',
           :comment         => ''},
         :check_10002   => {
           :designer_result => 'N/A',
           :design_check_id => '20002',
           :comment         => ''},
         :check_10003   => {
           :designer_result => 'Verified',
           :design_check_id => '20003',
           :comment         => ''})

    post(:perform_checks,
         :audit_id      => audits(:audit_mx234b).id,
         :subsection_id => subsections(:subsect_30_000).id)

    assert_equal(4, assigns(:audit).designer_completed_checks)
    assert_equal(0, assigns(:audit).auditor_completed_checks)


    audit.reload
    assert_equal(1, audit.audit_teammates.size)

    results = %w{Waived Verified N/A Verified}
    comment_count = { 10000 => 1 } 
    comment_count.default= 0

    assigns(:checks).each do |check|
      assert_equal(results.shift,           check[:design_check].designer_result)
      assert_equal(comment_count[check.id], check[:design_check].audit_comments.size)
    end 


    post(:update_design_checks,
         :audit         => {:id => audits(:audit_mx234b).id},
         :subsection    => {:id => subsections(:subsect_30_000).id},
         :check_10000   => {
           :designer_result => 'Verified',
           :design_check_id => '20000',
           :comment         => ''},
         :check_10001   => {
           :designer_result => 'Verified',
           :design_check_id => '20001',
           :comment         => ''},
         :check_10002   => {
           :designer_result => 'N/A',
           :design_check_id => '20002',
           :comment         => ''},
         :check_10003   => {
           :designer_result => 'Verified',
           :design_check_id => '20003',
           :comment         => ''})

    post(:perform_checks,
         :audit_id      => audits(:audit_mx234b).id,
         :subsection_id => subsections(:subsect_30_000).id)

    assert_equal(4, assigns(:audit).designer_completed_checks)
    assert_equal(0, assigns(:audit).auditor_completed_checks)

    audit.reload
    assert_equal(1, audit.audit_teammates.size)

    results = %w{Verified Verified N/A Verified} 

    assigns(:checks).each do |check|
      assert_equal(results.shift,           check[:design_check].designer_result)
      assert_equal(comment_count[check.id], check[:design_check].audit_comments.size)
    end 

    # No comment is included for the 'No' response - only one will update.
    post(:update_design_checks,
         :audit         => {:id => audits(:audit_mx234b).id},
         :subsection    => {:id => subsections(:subsect_30_001).id},
         :check_10004   => {
           :designer_result => 'Yes',
           :design_check_id => '20004',
           :comment         => ''},
         :check_10005   => {
           :designer_result => 'No',
           :design_check_id => '20005',
           :comment         => ''})

    post(:perform_checks,
         :audit_id      => audits(:audit_mx234b).id,
         :subsection_id => subsections(:subsect_30_001).id)

    assert_equal(5, assigns(:audit).designer_completed_checks)
    assert_equal(0, assigns(:audit).auditor_completed_checks)

    audit.reload
    assert_equal(1, audit.audit_teammates.size)

    results = %w{Yes None} 

    assigns(:checks).each do |check|
      assert_equal(results.shift,           check[:design_check].designer_result)
      assert_equal(comment_count[check.id], check[:design_check].audit_comments.size)
    end 

    # The 'No' response should update this time.
    post(:update_design_checks,
         :audit         => {:id => audits(:audit_mx234b).id},
         :subsection    => {:id => subsections(:subsect_30_001).id},
         :check_10004   => {
           :designer_result => 'Yes',
           :design_check_id => '20004',
           :comment         => ''},
         :check_10005   => {
           :designer_result => 'No',
           :design_check_id => '20005',
           :comment         => 'Go Red Sox!'})

    post(:perform_checks,
         :audit_id      => audits(:audit_mx234b).id,
         :subsection_id => subsections(:subsect_30_001).id)

    assert_equal(6, assigns(:audit).designer_completed_checks)
    assert_equal(0, assigns(:audit).auditor_completed_checks)

    audit.reload
    assert_equal(1, audit.audit_teammates.size)

    results = %w{Yes No}
    comment_count[10005] = 1

    assigns(:checks).each do |check|
      assert_equal(results.shift,           check[:design_check].designer_result)
      assert_equal(comment_count[check.id], check[:design_check].audit_comments.size)
    end 

    post(:update_design_checks,
         :audit         => {:id => audits(:audit_mx234b).id},
         :subsection    => {:id => subsections(:subsect_30_002).id},
         :check_10006   => {
           :designer_result => 'Waived',
           :design_check_id => '20006',
           :comment         => 'Comment One'},
         :check_10007   => {
           :designer_result => 'Waived',
           :design_check_id => '20007',
           :comment         => 'Comment Two'})

    post(:perform_checks,
         :audit_id      => audits(:audit_mx234b).id,
         :subsection_id => subsections(:subsect_30_002).id)

    assert_equal(8, assigns(:audit).designer_completed_checks)
    assert_equal(0, assigns(:audit).auditor_completed_checks)

    audit.reload
    assert_equal(1, audit.audit_teammates.size)

    results = %w{Waived Waived}
    10006.upto(10007) { |i| comment_count[i] = 1}

    assigns(:checks).each do |check|
      assert_equal(results.shift,           check[:design_check].designer_result)
      assert_equal(comment_count[check.id], check[:design_check].audit_comments.size)
    end 


    post(:update_design_checks,
         :audit         => {:id => audits(:audit_mx234b).id},
         :subsection    => {:id => subsections(:subsect_30_003).id},
         :check_10008   => {
           :designer_result => 'Waived',
           :design_check_id => '20008',
           :comment         => 'Comment One'},
         :check_10009   => {
           :designer_result => 'Waived',
           :design_check_id => '20009',
           :comment         => 'Comment Two'},
         :check_10010   => {
           :designer_result => 'Verified',
           :design_check_id => '20010',
           :comment         => 'Comment Three'},
         :check_10011   => {
           :designer_result => 'Verified',
           :design_check_id => '20011',
           :comment         => 'Comment Four'})

    post(:perform_checks,
         :audit_id      => audits(:audit_mx234b).id,
         :subsection_id => subsections(:subsect_30_003).id)

    assert_equal(12, assigns(:audit).designer_completed_checks)
    assert_equal(0,  assigns(:audit).auditor_completed_checks)

    audit.reload
    assert_equal(1, audit.audit_teammates.size)

    results = %w{Waived Waived Verified Verified} 
    10008.upto(10011) { |i| comment_count[i] = 1}

    assigns(:checks).each do |check|
      assert_equal(results.shift,           check[:design_check].designer_result)
      assert_equal(comment_count[check.id], check[:design_check].audit_comments.size)
    end 


    post(:update_design_checks,
         :audit         => {:id => audits(:audit_mx234b).id},
         :subsection    => {:id => subsections(:subsect_30_004).id},
         :check_10012   => {
           :designer_result => 'Waived',
           :design_check_id => '20012',
           :comment         => 'Comment One'},
         :check_10013   => {
           :designer_result => 'Waived',
           :design_check_id => '20013',
           :comment         => 'Comment Two'},
         :check_10014   => {
           :designer_result => 'N/A',
           :design_check_id => '20014',
           :comment         => 'Comment Three'})

    post(:perform_checks,
         :audit_id      => audits(:audit_mx234b).id,
         :subsection_id => subsections(:subsect_30_004).id)

    assert_equal(15, assigns(:audit).designer_completed_checks)
    assert_equal(0,  assigns(:audit).auditor_completed_checks)

    audit.reload
    assert_equal(1, audit.audit_teammates.size)

    results = %w{Waived Waived N/A} 
    10012.upto(10014) { |i| comment_count[i] = 1}

    assigns(:checks).each do |check|
      assert_equal(results.shift,           check[:design_check].designer_result)
      assert_equal(comment_count[check.id], check[:design_check].audit_comments.size)
    end 

    # Verify that audit is reporting that the self audit is complete, but the peer audit
    # is not complete.
    assert(assigns(:audit).designer_complete?)
    assert(!assigns(:audit).auditor_complete?)
    
    # Verify the 2 emails are sent when the self audit
    # completes
    assert_equal(2, @emails.size)
    email = @emails.pop
    assert_equal("Notification of upcoming Final Review for mx234b",  email.subject)
    email = @emails.pop
    assert_equal("mx234b: The designer has completed the self-audit", email.subject)

    # Log in as an auditor and get the audit listing.
    user = @scott_g
    @request.session[:user]             = user
    @request.session[:active_role].name = 'Designer'
    @request.session[:roles]            = user.roles
    
    post(:update_design_checks,
         :audit         => {:id => audits(:audit_mx234b).id},
         :subsection    => {:id => subsections(:subsect_30_000).id},
         :check_10000   => {
           :auditor_result  => 'Verified',
           :design_check_id => '20000',
           :comment         => ''},
         :check_10001   => {
           :auditor_result  => 'N/A',
           :design_check_id => '20001',
           :comment         => ''},
         :check_10002   => {
           :auditor_result  => 'Waived',
           :design_check_id => '20002',
           :comment         => ''},
         :check_10003   => {
           :auditor_result  => 'Comment',
           :design_check_id => '20003',
           :comment         => ''})

    post(:perform_checks,
         :audit_id      => audits(:audit_mx234b).id,
         :subsection_id => subsections(:subsect_30_000).id)
       
    assert_equal(15, assigns(:audit).designer_completed_checks)
    assert_equal(2,  assigns(:audit).auditor_completed_checks)

    audit.reload
    assert_equal(1, audit.audit_teammates.size)

    results = %w{Verified N/A None None}

    assigns(:checks).each do |check|
      assert_equal(results.shift,           check.design_check.auditor_result)
      assert_equal(comment_count[check.id], check.design_check.audit_comments.size)
    end

    post(:update_design_checks,
         :audit         => {:id => audits(:audit_mx234b).id},
         :subsection    => {:id => subsections(:subsect_30_000).id},
         :check_10000   => {
           :auditor_result  => 'Verified',
           :design_check_id => '20000',
           :comment         => ''},
         :check_10001   => {
           :auditor_result  => 'Comment',
           :design_check_id => '20001',
           :comment         => 'Withdrew N/A'},
         :check_10002   => {
           :auditor_result  => 'Waived',
           :design_check_id => '20002',
           :comment         => ''},
         :check_10003   => {
           :auditor_result  => 'Comment',
           :design_check_id => '20003',
           :comment         => ''})

    post(:perform_checks,
         :audit_id      => audits(:audit_mx234b).id,
         :subsection_id => subsections(:subsect_30_000).id)
       
    assert_equal(15, assigns(:audit).designer_completed_checks)
    assert_equal(1,  assigns(:audit).auditor_completed_checks)

    audit.reload
    assert_equal(1, audit.audit_teammates.size)

    results = %w{Verified Comment None None}
    comment_count[10001] = 1
 
    assigns(:checks).each do |check|
      assert_equal(results.shift,           check.design_check.auditor_result)
      assert_equal(comment_count[check.id], check.design_check.audit_comments.size)
    end

    post(:update_design_checks,
         :audit         => {:id => audits(:audit_mx234b).id},
         :subsection    => {:id => subsections(:subsect_30_000).id},
         :check_10000   => {
           :auditor_result  => 'N/A',
           :design_check_id => '20000',
           :comment         => 'Comment One'},
         :check_10001   => {
           :auditor_result  => 'Verified',
           :design_check_id => '20001',
           :comment         => 'Comment Two'},
         :check_10002   => {
           :auditor_result  => 'Waived',
           :design_check_id => '20002',
           :comment         => 'Comment Three'},
         :check_10003   => {
           :auditor_result  => 'Verified',
           :design_check_id => '20003',
           :comment         => 'Comment Four'})

    post(:perform_checks,
         :audit_id      => audits(:audit_mx234b).id,
         :subsection_id => subsections(:subsect_30_000).id)

    assert_equal(15, assigns(:audit).designer_completed_checks)
    assert_equal(4,  assigns(:audit).auditor_completed_checks)

    audit.reload
    assert_equal(1, audit.audit_teammates.size)

    results = %w{N/A Verified Waived Verified}
    10000.upto(10003) { |i| comment_count[i] += 1 }
    
    assigns(:checks).each do |check|
      assert_equal(results.shift,           check.design_check.auditor_result)
      assert_equal(comment_count[check.id], check.design_check.audit_comments.size)
    end

    post(:update_design_checks,
         :audit         => {:id => audits(:audit_mx234b).id},
         :subsection    => {:id => subsections(:subsect_30_002).id},
         :check_10006   => {
           :auditor_result  => 'N/A',
           :design_check_id => '20006',
           :comment         => 'Comment One'},
         :check_10007   => {
           :auditor_result  => 'Verified',
           :design_check_id => '20007',
           :comment         => 'Comment Two'})

    post(:perform_checks,
         :audit_id      => audits(:audit_mx234b).id,
         :subsection_id => subsections(:subsect_30_002).id)

    assert_equal(15, assigns(:audit).designer_completed_checks)
    assert_equal(6,  assigns(:audit).auditor_completed_checks)

    audit.reload
    assert_equal(1, audit.audit_teammates.size)

    results = %w{N/A Verified} 
    10006.upto(10007) { |i| comment_count[i] += 1 }
    
    assigns(:checks).each do |check|
      assert_equal(results.shift,           check.design_check.auditor_result)
      assert_equal(comment_count[check.id], check.design_check.audit_comments.size)
    end


    post(:update_design_checks,
         :audit         => {:id => audits(:audit_mx234b).id},
         :subsection    => {:id => subsections(:subsect_30_004).id},
         :check_10012   => {
           :auditor_result  => 'N/A',
           :design_check_id => '20012',
           :comment         => 'Comment One'},
         :check_10013   => {
           :auditor_result  => 'Verified',
           :design_check_id => '20013',
           :comment         => 'Comment Two'},
         :check_10014   => {
           :auditor_result  => 'Waived',
           :design_check_id => '20014',
           :comment         => 'Comment Three'})

    post(:perform_checks,
         :audit_id      => audits(:audit_mx234b).id,
         :subsection_id => subsections(:subsect_30_004).id)

    assert_equal(15, assigns(:audit).designer_completed_checks)
    assert_equal(9,  assigns(:audit).auditor_completed_checks)
    assert(assigns(:audit).designer_complete?)
    assert(assigns(:audit).auditor_complete?)

    audit.reload
    assert_equal(0, audit.audit_teammates.size)

    results = %w{N/A Verified Waived} 
    10012.upto(10014) { |i| comment_count[i] += 1 }
    
    assigns(:checks).each do |check|
      assert_equal(results.shift,           check.design_check.auditor_result)
      assert_equal(comment_count[check.id], check.design_check.audit_comments.size)
    end

  end


  ######################################################################
  #
  # test_print
  #
  # Description:
  # This method does the functional testing of the print method
  # from the AuditController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def test_print

    # Test a new board
    get(:print,
        :id => audits(:audit_mx234b).id)

    audit = assigns(:audit)
    assert_equal('mx234b',      audit.design.name)
    assert_equal('2.0',         audit.checklist.revision)
    assert_equal(@rich_m.name,  audit.design.designer.name)
    assert_equal(@scott_g.name, audit.design.peer.name)

    #              Section      Subsection   Check IDs
    #                ID             ID
    validate = { '20000' => { '30000' => [10000, 10001, 10002, 10003],
                              '30001' => [10004, 10005] } ,
                 '20001' => { '30002' => [10006, 10007],
                              '30003' => [10008, 10009, 10010, 10011],
                              '30004' => [10012, 10013, 10014] } }
    
    validate_print_variables(validate, audit.checklist.sections)


    # Test a date code
    get(:print,
        :id => audits(:audit_la453b_eco2).id)

    audit = assigns(:audit)
    assert_equal('la453b4_eco2', audit.design.name)
    assert_equal('1.0',          audit.checklist.revision)
    assert_equal(@scott_g.name,  audit.design.designer.name)
    assert_equal(@rich_m.name,   audit.design.peer.name)

    #              Section      Subsection   Check IDs
    #                ID             ID
    validate = {'3' => { '5' => [13, 14] } }

    validate_print_variables(validate, audit.checklist.sections)


    # Test a dot rev
    get(:print,
        :id => audits(:audit_la454c3).id)

    audit = assigns(:audit)
    assert_equal('la454c3',     audit.design.name)
    assert_equal('1.0',         audit.checklist.revision)
    assert_equal(@rich_m.name,  audit.design.designer.name)
    assert_equal(@scott_g.name, audit.design.peer.name)

    validate_print_variables(validate, audit.checklist.sections)
    display = assigns(:display)

  end


  ######################################################################
  #
  # test_show_sections
  #
  # Description:
  # This method does the functional testing of the show_sections method
  # from the AuditController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def test_show_sections

    audit_mx234c = audits(:audit_mx234c)

    # Verify that show_sections redirects to the home page if the user is not logged in.
    get(:show_sections, :id => audit_mx234c.id)

    notice = "#{Pcbtr::PCBTR_BASE_URL}#{@request.parameters[:controller]}/" +
             "#{@request.parameters[:action]} - unavailable unless logged in."
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal(notice, flash['notice'])

    
    user = User.find(@rich_m.id)
    @request.session[:user]        = user
    @request.session[:active_role] = Role.find_by_name('Designer')
    @request.session[:roles]       = user.roles

    get(:show_sections,
        :id => audit_mx234c.id)

    assert_equal("mx234c", assigns(:board_name))
    lines = assigns(:checklist_index)

    expected = Array[
      { 'bg_color'     => '0', 
        :section => 
          {'name'             => 'section_10_1',
           'id'               => '3'
          },
        'subsections' => Array[{
            'name'             => 'subsection_10_1_1',
            'percent_complete' => 0.0,
            'questions'        => 0,
            'checks'           => 2,
            'url'              => 'www.eds.com',
            'id'               => 5,
            'note'             => 'id - 5'
          },
          {
            'name'             => 'subsection_10_1_2',
            'percent_complete' => 0.0,
            'questions'        => 0,
            'checks'           => 4,
            'url'              => 'www.eds.com',
            'id'               => 6,
            'note'             => 'id - 6'
          }
        ]
      },
      { 'bg_color'     => '343434', 
        :section      => 
          { 'name'             => 'section_10_2',
            'id'               => '4'
          },
        'subsections' => Array[{
            'name'             => 'subsection_10_2_1',
            'percent_complete' => 0.0,
            'questions'        => 0,
            'checks'           => 3,
            'url'              => 'www.google.com',
            'id'               => 7,
            'note'             => 'id - 7'
          },
          {
            'name'             => 'subsection_10_2_2',
            'percent_complete' => 0.0,
            'questions'        => 0,
            'checks'           => 3,
            'url'              => 'www.google.com',
            'id'               => 8,
            'note'             => 'id - 8'
          }
        ]
      }
    ]
    
    i = 0
    for line in lines
      line.each { |k,v|	
        if k != 'subsections'
          section = expected[i][k]
          assert_equal(section['id'].to_i, v.id)
          assert_equal(section['name'],    v.name)
        else
          0.upto(line[k].size-1) { |idx|
            expected_vals = expected[i][k][idx]
            actual_vals = line['subsections'][idx]
            actual_vals.each { |key,actual_value|
              assert_equal(expected_vals[key], actual_value)
            }
          }
        end
      }
      i += 1
    end

    get(:show_sections,
        :id => audits(:audit_la453b_eco2).id)

    assert_equal("la453b4_eco2", assigns(:board_name))
    lines = assigns(:checklist_index)

    expected = Array[
      { 'bg_color'     => '0', 
        :section      => 
          { 'name'             => 'section_10_1',
            'id'               => '3'
          },
        'subsections' => Array[{
            'name'             => 'subsection_10_1_1',
            'percent_complete' => 0.0,
            'questions'        => 0,
            'checks'           => 2,
            'url'              => 'www.eds.com',
            'id'               => 5,
            'note'             => 'id - 5'
          },
          {
            'name'             => 'subsection_10_1_2',
            'percent_complete' => 0.0,
            'questions'        => 0,
            'checks'           => 4,
            'url'              => 'www.eds.com',
            'id'               => 6,
            'note'             => 'id - 6'
          }
        ]
      }
    ]
    
    i = 0
    lines.each do |line|
      line.each { |k,v|	
        if k != 'subsections'
          section = expected[i][k]
          assert_equal(section['id'].to_i, v.id)
          assert_equal(section['name'],    v.name)
        else
          0.upto(line[k].size-1) { |idx|
            expected_vals = expected[i][k][idx]
            actual_vals = line['subsections'][idx]
            actual_vals.each { |key,actual_value|
              assert_equal(expected_vals[key], actual_value)
            }
          }
        end
      }
      i += 1
    end


    get(:show_sections,
        :id => audits(:audit_la454c3).id)

    assert_equal("la454c3", assigns(:board_name))
    lines = assigns(:checklist_index)

    expected = Array[
      { 'bg_color'     => '0', 
        :section      => 
          { 'name'             => 'section_10_1',
            'id'               => '3'
          },
        'subsections' => Array[{
            'name'             => 'subsection_10_1_1',
            'percent_complete' => 0.0,
            'questions'        => 0,
            'checks'           => 2,
            'url'              => 'www.eds.com',
            'id'               => 5,
            'note'             => 'id - 5'
          },
          {
            'name'             => 'subsection_10_1_2',
            'percent_complete' => 0.0,
            'questions'        => 0,
            'checks'           => 4,
            'url'              => 'www.eds.com',
            'id'               => 6,
            'note'             => 'id - 6'
          }
        ]
      }
    ]
    
    i = 0
    lines.each do |line|
      line.each { |k,v|	
        if k != 'subsections'
          section = expected[i][k]
          assert_equal(section['id'].to_i, v.id)
          assert_equal(section['name'],    v.name)
        else
          0.upto(line[k].size-1) { |idx|
            expected_vals = expected[i][k][idx]
            actual_vals = line['subsections'][idx]
            actual_vals.each { |key,actual_value|
              assert_equal(expected_vals[key], actual_value)
            }
          }
        end
      }
      i += 1
    end

    get(:show_sections,
        :id => audits(:audit_in_peer_audit).id)

    assert_equal("mx999b", assigns(:board_name))
    lines = assigns(:checklist_index)

    expected = Array[
      { 'bg_color'     => '0', 
        :section      => 
          { 'name'             => 'section_10_1',
            'id'               => '3'
          },
        'subsections' => Array[{
            'name'             => 'subsection_10_1_1',
            'percent_complete' => 0.0,
            'questions'        => 0,
            'checks'           => 2,
            'url'              => 'www.eds.com',
            'id'               => 5,
            'note'             => 'id - 5'
          },
          {
            'name'             => 'subsection_10_1_2',
            'percent_complete' => 0.0,
            'questions'        => 0,
            'checks'           => 0,
            'url'              => 'www.eds.com',
            'id'               => 6,
            'note'             => 'id - 6'
          }
        ]
      },
      { 'bg_color'     => '343434', 
        :section      => 
          { 'name'             => 'section_10_2',
            'id'               => '4'
          },
        'subsections' => Array[{
            'name'             => 'subsection_10_2_1',
            'percent_complete' => 0.0,
            'questions'        => 0,
            'checks'           => 0,
            'url'              => 'www.google.com',
            'id'               => 7,
            'note'             => 'id - 7'
          },
          {
            'name'             => 'subsection_10_2_2',
            'percent_complete' => 0.0,
            'questions'        => 0,
            'checks'           => 3,
            'url'              => 'www.google.com',
            'id'               => 8,
            'note'             => 'id - 8'
          }
        ]
      }
    ]
    
    i = 0
    lines.each do |line|
      line.each { |k,v|
        if k != 'subsections'
          section = expected[i][k]
          assert_equal(section['id'].to_i, v.id)
          assert_equal(section['name'],    v.name)
        else
          0.upto(line[k].size-1) { |idx|
            expected_vals = expected[i][k][idx]
            actual_vals = line['subsections'][idx]
            actual_vals.each { |key, actual_value|
              assert_equal(expected_vals[key], actual_value)
            }
          }
        end
      }
      i += 1
    end

  end
  
  
  ######################################################################
  #
  # test_auditor_list
  #
  # Description:
  # This method does the functional testing of the show_sections method
  # from the AuditController class
  #
  ######################################################################
  #
  def test_auditor_list

    mx234c_audit = audits(:audit_mx234c)
    set_user(@rich_m.id, 'Designer')
    
    post(:auditor_list, :id => mx234c_audit.id)
    
    assert_equal(mx234c_audit, assigns(:audit))
    
    auditor_list = assigns(:auditor_list)
    
    lead_designer = mx234c_audit.design.designer
    lead_peer     = mx234c_audit.design.peer
    
    assert_equal(lead_designer, auditor_list[:lead_designer])
    assert_equal(lead_peer,     auditor_list[:lead_peer])
    
    expected_self_auditors = [@siva_e,
                              @scott_g,
                              @bob_g,
                              @rich_m,
                              @mathi_n]
    assert_equal(expected_self_auditors, auditor_list[:self_list])
    
    # Remove the self auditor to get the list of peers
    expected_peer_auditors = expected_self_auditors - [@rich_m]
    assert_equal(expected_peer_auditors, auditor_list[:peer_list])

    checklist_sections = [sections(:section_10_1), 
                          sections(:section_10_2)]
    
    auditor_list[:sections].each do |section|
      expected_section = checklist_sections.shift

      assert_equal(lead_designer,         section[:self_auditor])
      assert_equal(lead_peer,             section[:peer_auditor])
      assert_equal(expected_section.name, section[:section].name)
    end
    
    # No updates should have been made to audit teammates
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => @rich_m.id.to_s,
                                   :section_id_4 => @rich_m.id.to_s},
         :peer_auditor         => {:section_id_3 => @scott_g.id.to_s,
                                   :section_id_4 => @scott_g.id.to_s})

    mx234c_audit.reload                    
    assert_equal(0, mx234c_audit.audit_teammates.size)

    # No updates should have been made to audit teammates - can not assign
    # same person to be the peer and self auditor
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => @bob_g.id.to_s,
                                   :section_id_4 => @bob_g.id.to_s},
         :peer_auditor         => {:section_id_3 => @bob_g.id.to_s,
                                   :section_id_4 => @bob_g.id.to_s})

    mx234c_audit.reload                    
    assert_equal(0, mx234c_audit.audit_teammates.size)
    assert_equal('WARNING: Assignments not made <br />' +
                 '         Robert Goldin can not be both ' +
                 'self and peer auditor for section_10_1<br />' +
                 '         Robert Goldin can not be both ' +
                 'self and peer auditor for section_10_2<br />',
                 flash['notice'])
    
    # There should be 1 teammates record
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => @rich_m.id.to_s, 
                                   :section_id_4 => @bob_g.id.to_s},
         :peer_auditor         => {:section_id_3 => @scott_g.id.to_s,
                                   :section_id_4 => @scott_g.id.to_s})

    mx234c_audit.reload    
    teammates = mx234c_audit.audit_teammates
    assert_equal(1, teammates.size)

    teammate = teammates.pop
    assert_equal(@bob_g.id,                  teammate.user_id)
    assert_equal(sections(:section_10_2).id, teammate.section_id)
    assert(teammate.self?)
         
    # There should be no audit teammates records.
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => @rich_m.id.to_s,
                                   :section_id_4 => @rich_m.id.to_s},
         :peer_auditor         => {:section_id_3 => @scott_g.id.to_s,
                                   :section_id_4 => @scott_g.id.to_s})

    mx234c_audit.reload    
    assert_equal(0, mx234c_audit.audit_teammates.size)
    
    
    # There should be 1 teammate record
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => @rich_m.id.to_s, 
                                   :section_id_4 => @rich_m.id.to_s},
         :peer_auditor         => {:section_id_3 => @scott_g.id.to_s,
                                   :section_id_4 => @bob_g.id.to_s})

    mx234c_audit.reload    
    teammates = mx234c_audit.audit_teammates
    assert_equal(1, teammates.size)
    teammate = teammates.pop
    assert_equal(@bob_g.id,                  teammate.user_id)
    assert_equal(sections(:section_10_2).id, teammate.section_id)
    assert(!teammate.self?)
         
    # There should be 1 teammates record
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => @rich_m.id.to_s, 
                                   :section_id_4 => @bob_g.id.to_s},
         :peer_auditor         => {:section_id_3 => @scott_g.id.to_s,
                                   :section_id_4 => @scott_g.id.to_s})

    mx234c_audit.reload    
    teammates = mx234c_audit.audit_teammates
    assert_equal(1, teammates.size)
    teammate = teammates.pop
    assert_equal(@bob_g.id,                  teammate.user_id)
    assert_equal(sections(:section_10_2).id, teammate.section_id)
    assert(teammate.self?)
         
    # There should be 1 teammate record
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => @rich_m.id.to_s, 
                                   :section_id_4 => @rich_m.id.to_s},
         :peer_auditor         => {:section_id_3 => @scott_g.id.to_s,
                                   :section_id_4 => @bob_g.id.to_s})

    mx234c_audit.reload    
    teammates = mx234c_audit.audit_teammates
    assert_equal(1, teammates.size)
    teammate = teammates.pop
    assert_equal(@bob_g.id,                  teammate.user_id)
    assert_equal(sections(:section_10_2).id, teammate.section_id)
    assert(!teammate.self?)

    # There should be 1 teammate record
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => @rich_m.id.to_s, 
                                   :section_id_4 => @rich_m.id.to_s},
         :peer_auditor         => {:section_id_3 => @scott_g.id.to_s,
                                   :section_id_4 => @bob_g.id.to_s})

    mx234c_audit.reload    
    teammates = mx234c_audit.audit_teammates
    assert_equal(1, teammates.size)
    teammate = teammates.pop
    assert_equal(@bob_g.id,                  teammate.user_id)
    assert_equal(sections(:section_10_2).id, teammate.section_id)
    assert(!teammate.self?)


    # There should be 2 teammate records
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => @bob_g.id.to_s, 
                                   :section_id_4 => @bob_g.id.to_s},
         :peer_auditor         => {:section_id_3 => @scott_g.id.to_s,
                                   :section_id_4 => @scott_g.id.to_s})

    mx234c_audit.reload    
    teammates = mx234c_audit.audit_teammates.sort_by { |at| at.section_id}
    assert_equal(2, teammates.size)
    assert_equal(@bob_g.id,                  teammates[0].user_id)
    assert_equal(sections(:section_10_1).id, teammates[0].section_id)
    assert(teammates[0].self?)
    assert_equal(@bob_g.id,                  teammates[1].user_id)
    assert_equal(sections(:section_10_2).id, teammates[1].section_id)
    assert(teammates[1].self?)


    # There should be 2 teammate records
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => @bob_g.id.to_s, 
                                   :section_id_4 => @bob_g.id.to_s},
         :peer_auditor         => {:section_id_3 => @scott_g.id.to_s,
                                   :section_id_4 => @scott_g.id.to_s})

    mx234c_audit.reload    
    teammates = mx234c_audit.audit_teammates.sort_by { |at| at.section_id}
    assert_equal(2, teammates.size)
    assert_equal(@bob_g.id,                  teammates[0].user_id)
    assert_equal(sections(:section_10_1).id, teammates[0].section_id)
    assert(teammates[0].self?)
    assert_equal(@bob_g.id,                  teammates[1].user_id)
    assert_equal(sections(:section_10_2).id, teammates[1].section_id)
    assert(teammates[1].self?)
         
  end
  

private


  def validate_print_variables(validate, sections)
  
    assert_equal(validate.size, sections.size)
    i = 0
    
    # Go through the sections that were sent to the view.
    sections.each do |section|

      # Verify the Section ID
      section_key = section.id.to_s
      assert_not_nil(validate[section_key])
      
      # Verify the number of subsections
      expected_subsections = validate[section_key]
      assert_equal(expected_subsections.size, section.subsections.size)

      # Verify the Subsection IDs
      expected_ids = expected_subsections.collect { |key, val| key.to_i }
      actual_ids   = section.subsections.collect { |s| s.id }
      assert_equal(expected_ids.sort, actual_ids.sort)
      
      
      section.subsections.each do |subsection|

        #Verify the subsection ID
        subsection_key = subsection.id.to_s
        expected_subsection = expected_subsections[subsection_key]
        assert_not_nil(expected_subsection) 
      
        assert_equal(expected_subsection.size, subsection.checks.size)

        check_ids = subsection.checks.collect { |ch| ch.id }
        assert_equal(expected_subsection, check_ids)

      end

      i += 1
   
    end

  end
 

end
