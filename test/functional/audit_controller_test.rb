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
  end

  fixtures(:audit_comments,
           :audit_teammates,
           :audits,
           :boards,
           :checklists,
           :checks,
           :designs,
           :design_checks,
           :platforms,
           :projects,
           :prefixes,
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

    # Log in as a designer and get the audit listing.
    user = User.find(users(:scott_g).id)
    @request.session[:user]        = user
    @request.session[:active_role] = Role.find_by_name('Designer')
    @request.session[:roles]       = user.roles

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
    for check in checks
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
    designer = User.find(users(:rich_m).id)
    set_user(users(:rich_m).id, 'Designer')

    audit = Audit.find(audits(:audit_mx234b).id)
    assert_equal(designer.id, audit.design.designer_id)
    assert(!audit.designer_complete?)
    assert(!audit.auditor_complete?)
    assert(1, audit.audit_teammates.size)
    
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

    checks = assigns(:checks)
    for check in checks
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
    checks = assigns(:checks)
    for check in checks
      assert_equal(results.shift, check[:design_check].designer_result)
      if check.id != 10000
        assert_equal(0, check[:design_check].audit_comments.size)
      else
        assert_equal(1, check[:design_check].audit_comments.size)
      end
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
    checks = assigns(:checks)
    for check in checks
      assert_equal(results.shift, check[:design_check].designer_result)
      if check.id != 10000
        assert_equal(0, check[:design_check].audit_comments.size)
      else
        assert_equal(1, check[:design_check].audit_comments.size)
      end
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
    checks = assigns(:checks)
    for check in checks
      assert_equal(results.shift, check[:design_check].designer_result)
      assert_equal(0,             check[:design_check].audit_comments.size)
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
    checks = assigns(:checks)
    for check in checks
      assert_equal(results.shift, check[:design_check].designer_result)
      if check.id == 10004
        assert_equal(0, check[:design_check].audit_comments.size)
      else
        assert_equal(1, check[:design_check].audit_comments.size)
      end
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
    checks = assigns(:checks)
    for check in checks
      assert_equal(results.shift, check[:design_check].designer_result)
      assert_equal(1,             check[:design_check].audit_comments.size)
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
    checks = assigns(:checks)
    for check in checks
      assert_equal(results.shift, check[:design_check].designer_result)
      assert_equal(1,             check[:design_check].audit_comments.size)
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
    checks = assigns(:checks)
    for check in checks
      assert_equal(results.shift, check[:design_check].designer_result)
      assert_equal(1,             check[:design_check].audit_comments.size)
    end 


    # Log in as an auditor and get the audit listing.
    user = User.find(users(:scott_g).id)
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
    checks = assigns(:checks)
    for check in checks
      assert_equal(results.shift, check[:design_check].auditor_result)
      if check.id != 10000
        assert_equal(0, check[:design_check].audit_comments.size)
      else
        assert_equal(1, check[:design_check].audit_comments.size)
      end
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
    checks = assigns(:checks)
    for check in checks
      assert_equal(results.shift, check[:design_check].auditor_result)
      if check.id != 10000
        assert_equal(1, check[:design_check].audit_comments.size)
      else
        assert_equal(2, check[:design_check].audit_comments.size)
        created_on = Time.now
        for comment in check[:design_check].audit_comments
          assert(comment.created_on < created_on)
          created_on = comment.created_on
        end
      end
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
    checks = assigns(:checks)
    for check in checks
      assert_equal(results.shift, check[:design_check].auditor_result)
      assert_equal(2,             check[:design_check].audit_comments.size)
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
    checks = assigns(:checks)
    for check in checks
      assert_equal(results.shift, check[:design_check].auditor_result)
      assert_equal(2,             check[:design_check].audit_comments.size)
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

    summary = assigns(:summary)
    assert_equal('mx234b',      summary[:board_number])
    assert_equal('2.0',         summary[:checklist_rev])
    assert_equal(users(:rich_m).name,  summary[:designer])
    assert_equal(users(:scott_g).name, summary[:auditor])

    display = assigns(:display)

    validate = Array[
      {:section => 20000, 
       :subsect => 30000, 
       :checks  => [10000, 10001, 10002, 10003]},
      {:section => 20000, 
       :subsect => 30001, 
       :checks  => [10004, 10005]},
      {:section => 20001, 
       :subsect => 30002, 
       :checks  => [10006, 10007]},
      {:section => 20001,
       :subsect => 30003,
       :checks  => [10008, 10009, 10010, 10011]},
      {:section => 20001,
       :subsect => 30004,
	:checks => [10012, 10013, 10014]}]

    assert_equal(validate.size, display.size)
    i = 0
    display.each { |item|
      summary = validate[i][:summary]
      assert_equal(validate[i][:section],     item[:section].id)
      assert_equal(validate[i][:subsect],     item[:subsect].id)
      assert_equal(validate[i][:checks].size, item[:check_info].size)

      0.upto(validate[i][:checks].size - 1) { |j|
        assert_equal(validate[i][:checks][j],
                     item[:check_info][j][:check][:id])
      }
      i += 1
    }

    # Test a date code
    get(:print,
        :id => audits(:audit_la453b_eco2).id)

    summary = assigns(:summary)
    assert_equal('la453b4_eco2',  summary[:board_number])
    assert_equal('1.0',           summary[:checklist_rev])
    assert_equal(users(:scott_g).name,   summary[:designer])
    assert_equal(users(:rich_m).name,    summary[:auditor])

    display = assigns(:display)

    validate = Array[
      {:section => 3, :subsect =>  5, :checks => [13, 14]}]

    assert_equal(1, display.size)
    i = 0
    display.each { |item| 
      assert_equal(validate[i][:section],     item[:section].id)
      assert_equal(validate[i][:subsect],     item[:subsect].id)
      assert_equal(validate[i][:checks].size, item[:check_info].size)

      0.upto(validate[i][:checks].size - 1) { |j|
        assert_equal(validate[i][:checks][j],
                     item[:check_info][j][:check][:id])
      }
      i += 1
    }
    assert_equal(1, display.size)


    # Test a dot rev
    get(:print,
        :id => audits(:audit_la454c3).id)

    summary = assigns(:summary)
    assert_equal('la454c3',     summary[:board_number])
    assert_equal('1.0',         summary[:checklist_rev])
    assert_equal(users(:rich_m).name,  summary[:designer])
    assert_equal(users(:scott_g).name, summary[:auditor])

    display = assigns(:display)

    assert_equal(1, display.size)
    i = 0
    display.each { |item| 
      assert_equal(validate[i][:section],     item[:section].id)
      assert_equal(validate[i][:subsect],     item[:subsect].id)
      assert_equal(validate[i][:checks].size, item[:check_info].size)

      0.upto(validate[i][:checks].size - 1) { |j|
        assert_equal(validate[i][:checks][j],
                     item[:check_info][j][:check][:id])
      }
      i += 1
    }
    assert_equal(1, display.size)

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

    rich_m = users(:rich_m)
    
    audit_mx234c = audits(:audit_mx234c)

    user = User.find(rich_m.id)
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
    set_user(users(:rich_m).id, 'Designer')
    
    post(:auditor_list, :id => mx234c_audit.id)
    
    assert_equal(mx234c_audit, assigns(:audit))
    
    auditor_list = assigns(:auditor_list)
    
    lead_designer = mx234c_audit.design.designer
    lead_peer     = mx234c_audit.design.peer
    
    assert_equal(lead_designer, auditor_list[:lead_designer])
    assert_equal(lead_peer,     auditor_list[:lead_peer])
    
    expected_self_auditors = [users(:scott_g),
                              users(:bob_g),
                              users(:rich_m)]
    assert_equal(expected_self_auditors, auditor_list[:self_list])
    
    expected_peer_auditors = [users(:scott_g),  users(:bob_g)]
    assert_equal(expected_peer_auditors, auditor_list[:peer_list])

    checklist_sections = [sections(:section_10_1), 
                          sections(:section_10_2)]
    
    for section in auditor_list[:sections]
      expected_section = checklist_sections.shift

      assert_equal(lead_designer,         section[:self_auditor])
      assert_equal(lead_peer,             section[:peer_auditor])
      assert_equal(expected_section.name, section[:section].name)
    end
    
    bob_g   = users(:bob_g)
    rich_m  = users(:rich_m)
    scott_g = users(:scott_g)
    # No updates should have been made to audit teammates
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => rich_m.id.to_s,
                                   :section_id_4 => rich_m.id.to_s},
         :peer_auditor         => {:section_id_3 => scott_g.id.to_s,
                                   :section_id_4 => scott_g.id.to_s})

    mx234c_audit.reload                    
    assert_equal(0, mx234c_audit.audit_teammates.size)
    
    # There should be 1 teammates record
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => rich_m.id.to_s, 
                                   :section_id_4 => bob_g.id.to_s},
         :peer_auditor         => {:section_id_3 => scott_g.id.to_s,
                                   :section_id_4 => scott_g.id.to_s})

    mx234c_audit.reload    
    teammates = mx234c_audit.audit_teammates
    assert_equal(1, teammates.size)

    teammate = teammates.pop
    assert_equal(bob_g.id,                   teammate.user_id)
    assert_equal(sections(:section_10_2).id, teammate.section_id)
    assert_equal(true,                       teammate.self?)
         
    # There should be no audit teammates records.
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => rich_m.id.to_s,
                                   :section_id_4 => rich_m.id.to_s},
         :peer_auditor         => {:section_id_3 => scott_g.id.to_s,
                                   :section_id_4 => scott_g.id.to_s})

    mx234c_audit.reload    
    assert_equal(0, mx234c_audit.audit_teammates.size)
    
    
    # There should be 1 teammate record
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => rich_m.id.to_s, 
                                   :section_id_4 => rich_m.id.to_s},
         :peer_auditor         => {:section_id_3 => scott_g.id.to_s,
                                   :section_id_4 => bob_g.id.to_s})

    mx234c_audit.reload    
    teammates = mx234c_audit.audit_teammates
    assert_equal(1, teammates.size)
    teammate = teammates.pop
    assert_equal(bob_g.id,                   teammate.user_id)
    assert_equal(sections(:section_10_2).id, teammate.section_id)
    assert_equal(false,                      teammate.self?)
         
    # There should be 1 teammates record
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => rich_m.id.to_s, 
                                   :section_id_4 => bob_g.id.to_s},
         :peer_auditor         => {:section_id_3 => scott_g.id.to_s,
                                   :section_id_4 => scott_g.id.to_s})

    mx234c_audit.reload    
    teammates = mx234c_audit.audit_teammates
    assert_equal(1, teammates.size)
    teammate = teammates.pop
    assert_equal(bob_g.id,                   teammate.user_id)
    assert_equal(sections(:section_10_2).id, teammate.section_id)
    assert_equal(true,                       teammate.self?)
         
    # There should be 1 teammate record
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => rich_m.id.to_s, 
                                   :section_id_4 => rich_m.id.to_s},
         :peer_auditor         => {:section_id_3 => scott_g.id.to_s,
                                   :section_id_4 => bob_g.id.to_s})

    mx234c_audit.reload    
    teammates = mx234c_audit.audit_teammates
    assert_equal(1, teammates.size)
    teammate = teammates.pop
    assert_equal(bob_g.id,                   teammate.user_id)
    assert_equal(sections(:section_10_2).id, teammate.section_id)
    assert_equal(false,                      teammate.self?)

    # There should be 1 teammate record
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => rich_m.id.to_s, 
                                   :section_id_4 => rich_m.id.to_s},
         :peer_auditor         => {:section_id_3 => scott_g.id.to_s,
                                   :section_id_4 => bob_g.id.to_s})

    mx234c_audit.reload    
    teammates = mx234c_audit.audit_teammates
    assert_equal(1, teammates.size)
    teammate = teammates.pop
    assert_equal(bob_g.id,                   teammate.user_id)
    assert_equal(sections(:section_10_2).id, teammate.section_id)
    assert_equal(false,                      teammate.self?)


    # There should be 2 teammate records
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => bob_g.id.to_s, 
                                   :section_id_4 => bob_g.id.to_s},
         :peer_auditor         => {:section_id_3 => scott_g.id.to_s,
                                   :section_id_4 => scott_g.id.to_s})

    mx234c_audit.reload    
    teammates = mx234c_audit.audit_teammates.sort_by { |at| at.section_id}
    assert_equal(2, teammates.size)
    assert_equal(bob_g.id,                   teammates[0].user_id)
    assert_equal(sections(:section_10_1).id, teammates[0].section_id)
    assert_equal(true,                       teammates[0].self?)
    assert_equal(bob_g.id,                   teammates[1].user_id)
    assert_equal(sections(:section_10_2).id, teammates[1].section_id)
    assert_equal(true,                       teammates[1].self?)


    # There should be 2 teammate records
    post(:update_auditor_list,
         :audit                => {:id => mx234c_audit.id},
         :self_auditor         => {:section_id_3 => bob_g.id.to_s, 
                                   :section_id_4 => bob_g.id.to_s},
         :peer_auditor         => {:section_id_3 => scott_g.id.to_s,
                                   :section_id_4 => scott_g.id.to_s})

    mx234c_audit.reload    
    teammates = mx234c_audit.audit_teammates.sort_by { |at| at.section_id}
    assert_equal(2, teammates.size)
    assert_equal(bob_g.id,                   teammates[0].user_id)
    assert_equal(sections(:section_10_1).id, teammates[0].section_id)
    assert_equal(true,                       teammates[0].self?)
    assert_equal(bob_g.id,                   teammates[1].user_id)
    assert_equal(sections(:section_10_2).id, teammates[1].section_id)
    assert_equal(true,                       teammates[1].self?)
         
  end
  

  private


  def dump_audit(audit_id,
                 msg     = '',
                 details = false)

    print "\n#################### DUMP AUDIT ####################\n"
    print msg + "\n"

    designer_results = {}
    auditor_results  = {}

    audit           = Audit.find(audit_id)
    design_checks   = DesignCheck.find_all_by_audit_id(audit_id)
    design_check_list = {}
    for design_check in design_checks
      design_check_list[design_check.check_id] = design_check
    end

    print "\n### DUMP AUDIT for #{audit.design.name}   AUDIT ID: #{audit_id}\n"
    print "    DESIGNER COMPLETE: #{audit.designer_complete?}\n"
    designer = User.find(audit.design.designer_id).name
    auditor  = User.find(audit.design.peer_id).name
    print "    DESIGNER: #{designer}\n"
    print "    DESIGNER COMPLETED CHECKS: #{audit.designer_completed_checks}\n"
    print "    AUDITOR: #{auditor}\n"
    print "    AUDITOR COMPLETE: #{audit.auditor_complete?}\n"
    print "    AUDITOR COMPLETED CHECKS: #{audit.auditor_completed_checks}\n"
    print "    CHECKLIST [#{audit.checklist_id}]\n"

    sections = Section.find_all_by_checklist_id(audit.checklist_id, 
                                                "sort_order ASC")
    print "    NUMBER OF SECTIONS: #{sections.size}\n" if details
    for section in sections
      subsections = Subsection.find_all_by_section_id(section.id,
                                                      "sort_order ASC")
      if details
        print "\n    SECTION ID: #{section.id}\n"
        print "    NUMBER OF SUBSECTIONS: #{subsections.size}\n"     
      end

      for subsection in subsections
        checks = Check.find_all_by_subsection_id(subsection.id,
                                                 "sort_order ASC")
        if details
          print "\n    SUBSECTION ID: #{subsection.id}\n"
          print "    NUMBER OF DESIGN CHECKS: [#{checks.size}]\n"
        end

        for check in checks

          design_check = design_check_list[check.id]

          if details
            print "      DESIGN_CHECK ID: #{design_check.id}\n"
            print "      AUDIT ID: #{design_check.audit_id}\n"
            print "      CHECK ID: #{design_check.check_id}\n"
            auditor  = User.find(design_check.auditor_id).name
            designer = User.find(design_check.designer_id).name
            print "      AUDITOR: #{auditor}\n"
            print "      DESIGNER: #{designer}\n"
            print "      AUDITOR RESULT #{design_check.auditor_result}\n"
            print "      DESIGNER RESULT #{design_check.designer_result}\n\n"
          end

          designer_results[design_check.designer_result] = 0 if !designer_results[design_check.designer_result]
          auditor_results[design_check.auditor_result]   = 0 if !auditor_results[design_check.auditor_result]

          designer_results[design_check.designer_result] += 1
          auditor_results[design_check.auditor_result]   += 1

        end
      end
    end

    print "*********************** DESIGNER RESULTS \n"
    designer_results.each { |k,v| print "   #{k} => #{v}\n" }

    print "*********************** AUDITOR RESULTS \n"
    auditor_results.each { |k,v| print "   #{k} => #{v}\n" }

  end
 

  def dump_audits

    audit_list      = Audit.find_all(nil, 'id ASC')
    section_list    = Section.find_all
    subsection_list = Subsection.find_all
    check_list      = Check.find_all
    dc_list         = DesignCheck.find_all

    print "\n Total number of audits:        #{audit_list.size}"
      print "\n Total number of sections:      #{section_list.size}"
      print "\n Total number of subsections:   #{subsection_list.size}"
      print "\n Total number of checks:        #{check_list.size}"
      print "\n Total number of design_checks: #{dc_list.size}" 

      for audit in audit_list
        design = audit.design
        board  = audit.design.board

        sections = Section.find_all("checklist_id='#{audit.checklist_id}'",
                                    'sort_order ASC')

        print "\n\n -------------------------------------\n"
        print "  audit id:          #{audit.id}\n"
          print "  audit checklistid: #{audit.checklist_id}\n"
          print "  design:            #{design.name} [#{design.id}]\n"
        print "  board:             #{board.name} [#{board.id}]\n"
        print " -------------------------------------\n"
        
        for section in sections 

          section_list.delete_if { |sect| section.id == sect.id }

          print "  section:           #{section.name} [#{section.id}]\n"
          subsections = Subsection.find_all("section_id='#{section.id}'",
                                            'sort_order ASC')
          for subsect in subsections

            subsection_list.delete_if { |subsection| subsection.id == subsect.id }

            print "  subsection:        #{subsect.name} [#{subsect.id}]\n"
            checks = Check.find_all("subsection_id='#{subsect.id}'",
                                    'sort_order ASC')
            for check in checks

              check_list.delete_if { |ch| ch.id == check.id }

              print "  check:             #{check.check} [#{check.id}]  "
              design_checks = DesignCheck.find_all("audit_id='#{audit.id}' and check_id='#{check.id}'")
              if design_checks == nil
                print 'WARNING: No design check'
              else
                dc = design_checks.shift

                if dc == nil
                  print "No associated design check"
                else
                  dc_list.delete_if { |design_ch| design_ch.id == dc.id }
                  print " design check id: #{dc.id}" 
                end
                if design_checks.size > 0
                  print '\nWARNING: Found more than 1 design check'
                end
              end
              print "\n"
            end
          end
        end
        
      end

    print "\n\n"
    if section_list.size == 0
      print "All section records have been used.\n"
    else
      print "The following #{section_list.size} section record(s) were not used.\n"
      for sect in section_list
        print "  *** section: #{sect.name} [#{sect.id}]\n"
      end
    end

    print "\n\n"
    if subsection_list.size == 0
      print "All subsection records have been used.\n"
    else
      print "The following #{subsection_list.size} subsection record(s) were not used.\n"
      for subsect in subsection_list
        print "  *** subsection: #{subsect.name} [#{subsect.id}]\n"
      end
    end
    
    print "\n\n"
    if check_list.size == 0
      print "All check records have been used.\n"
    else
      print "The following #{check_list.size} check record(s) were not used.\n"
      for check in check_list
        print "  *** check: #{check.check} [#{check.id}]\n"
      end
    end
    
    print "\n\n"
    if dc_list.size == 0
      print "All design check records have been used.\n"
    else
      print "The following #{dc_list.size} design check record(s) were not used.\n"
      for dc in dc_list
        print "  *** design check: #{dc.id} :: [#{dc.audit_id}/#{dc.check_id}]\n"
      end
    end
    
  end
  
  
end
