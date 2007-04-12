########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: check_controller_test.rb
#
# This file contains the functional tests for the check_controller
#
# Revision History:
#   $Id$
#
########################################################################
#
# TO DO:
# 
# 1) Verify you can not modify a check that is part of a 
#    released checklist.
#

require File.dirname(__FILE__) + '/../test_helper'
require 'check_controller'

# Re-raise errors caught by the controller.
class CheckController; def rescue_action(e) raise e end; end

class CheckControllerTest < Test::Unit::TestCase
  def setup
    @controller = CheckController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:checklists,
	   :checks,
	   :roles,
	   :roles_users,
	   :sections,
	   :subsections,
	   :users)


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the test_edit method
  # from the CheckController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  # Verifies the following
  #   - User can not edit unless logged in as an ADMIN
  #   - The proper http response is received when a valid check ID
  #     is provided.
  #
  # TO DO: 1) Verify the counts after checkbox modifications.
  #
  ######################################################################
  #
  def test_edit

    # Try editing without logging in.
    check_05 = checks(:check_05)
    post(:edit,
         :id => check_05.id)
    
    assert_redirected_to(:controller => 'user',
                         :action     => 'login')

    # Try editing from a non-Admin account.
    set_non_admin
    post(:edit,
         :id => check_05.id)
    
    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try editing from an Admin account
    set_admin
    post(:edit,
         :id => check_05.id)

    assert_response 200
    assert_equal(check_05.id, assigns(:check).id)

    assert_raise(ActiveRecord::RecordNotFound) {
      post(:edit, :id => 32423423)
    }
  end


  ######################################################################
  #
  # test_insert_check
  #
  # Description:
  # This method does the functional testing of the insert_check method
  # from the CheckController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_insert_check

    section_01_1      = sections(:section_01_1)
    subsection_01_1_1 = subsections(:subsection_01_1_1)
    
    set_admin
    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(3, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(3, checklist.dr_designer_auditor_count)

    new_check = {
      'date_code_check' => '1',
      'full_review'     => '1',
      'title'           => 'First New Check',
      'dot_rev_check'   => '1',
      'url'             => '',
      'check'           => 'new check',
      'check_type'      => 'designer_auditor'
    }

    check = { 'id' => checks(:check_01).id }
    assert_equal(3, Check.count("subsection_id=#{subsection_01_1_1.id}"))
    checks = Check.find(:all,
                        :conditions => "section_id=#{section_01_1.id}")
    assert_equal(6, checks.size)

    post(:insert_check,
         :new_check => new_check,
         :check     => check)

    assert_equal('Inserted check successfully.', flash['notice'])
    assert_redirected_to(:id => subsection_01_1_1.id,
                                :action => 'modify_checks')

    assert_equal(7, Check.count("section_id=#{section_01_1.id}"))
    checks = Check.find(:all,
                        :conditions => "subsection_id=#{subsection_01_1_1.id}",
                        :order      => 'sort_order ASC')
    assert_equal(4, checks.size)

    assert_equal('First New Check', checks[0].title)
    assert_equal(checks(:check_01).id, checks[1].id)
    assert_equal(checks(:check_02).id, checks[2].id)
    assert_equal(checks(:check_03).id, checks[3].id)

    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(6, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(4, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(4, checklist.dr_designer_auditor_count)


    new_check = {
      'date_code_check' => '1',
      'full_review'     => '1',
      'title'           => 'New Check',
      'dot_rev_check'   => '0',
      'url'             => '',
      'check'           => 'text',
      'check_type'      => 'designer_only'
    }
    check = { 'id' => checks(:check_06).id }

    subsection_01_1_2 = subsections(:subsection_01_1_2)
    assert_equal(3, Check.count("subsection_id=#{subsection_01_1_2.id}"))

    post(:insert_check,
         :new_check => new_check,
         :check     => check)
	 
    assert_equal(8, Check.count("section_id=#{section_01_1.id}"))
    checks = Check.find(:all,
                        :conditions => "subsection_id=#{subsection_01_1_2.id}",
                        :order      => 'sort_order ASC')
    assert_equal(4, checks.size)

    assert_equal(checks(:check_04).id, checks[0][:id])
    assert_equal(checks(:check_05).id, checks[1][:id])
    assert_equal('New Check',          checks[2][:title])
    assert_equal(checks(:check_06).id, checks[3][:id])

    checklist = Checklist.find(subsection_01_1_2.checklist_id)
    assert_equal(7, checklist.designer_only_count)
    assert_equal(6, checklist.designer_auditor_count)
    assert_equal(1, checklist.dc_designer_only_count)
    assert_equal(4, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(4, checklist.dr_designer_auditor_count)


    new_check = {
      'date_code_check' => '1',
      'full_review'     => '1',
      'title'           => 'Second New Check in subsect 2',
      'dot_rev_check'   => '1',
      'url'             => '',
      'check'           => 'text',
      'check_type'      => 'designer_only'
    }
    check = { 'id' => checks(:check_04).id }

    post(:insert_check,
         :new_check => new_check,
         :check     => check)

    assert_equal(9, Check.count("section_id=#{section_01_1.id}"))	 
    checks = Check.find(:all,
                        :conditions => "subsection_id=#{subsection_01_1_2.id}",
                        :order      => 'sort_order ASC')
    assert_equal(5, checks.size)

    0.upto(checks.size-1) { |x| assert_equal((x+1), checks[x][:sort_order]) }

    assert_equal('Second New Check in subsect 2',
		 checks[0][:title])
    assert_equal(checks(:check_04).id, checks[1][:id])
    assert_equal(checks(:check_05).id, checks[2][:id])
    assert_equal('New Check',          checks[3][:title])
    assert_equal(checks(:check_06).id, checks[4][:id])

    checklist = Checklist.find(subsection_01_1_2.checklist_id)
    assert_equal(8, checklist.designer_only_count)
    assert_equal(6, checklist.designer_auditor_count)
    assert_equal(2, checklist.dc_designer_only_count)
    assert_equal(4, checklist.dc_designer_auditor_count)
    assert_equal(1, checklist.dr_designer_only_count)
    assert_equal(4, checklist.dr_designer_auditor_count)

  end


  ######################################################################
  #
  # test_insert
  #
  # Description:
  # This method does the functional testing of the insert method
  # from the CheckController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_insert

    # Try editing without logging in.
    post :insert
    
    assert_redirected_to(:controller => 'user',
                         :action     => 'login')

    # Try editing from a non-Admin account.
    set_non_admin
    post :insert
    
    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try editing from an Admin account
    set_admin
    check_04 = checks(:check_04)
    post(:insert,
         :id      => check_04.id)

    assert_response 200
    assert_equal(check_04.section_id,    assigns(:new_check).section_id)
    assert_equal(check_04.subsection_id, assigns(:new_check).subsection_id)
    assert_equal(check_04.check_type,    assigns(:new_check).check_type)

  end


  ######################################################################
  #
  # test_append_check
  #
  # Description:
  # This method does the functional testing of the append_check method
  # from the CheckController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_append_check

    set_admin
    subsection_01_1_1 = subsections(:subsection_01_1_1)
    section_01_1      = sections(:section_01_1)
    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(3, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(3, checklist.dr_designer_auditor_count)

    new_check = {
      'date_code_check' => '1',
      'full_review'     => '1',
      'title'           => 'New Check APPEND',
      'dot_rev_check'   => '1',
      'url'             => '',
      'check'           => 'text',
      'check_type'      => 'designer_auditor'
    }
    check = {'id' => checks(:check_03).id}
    assert_equal(3, Check.count("subsection_id=#{subsection_01_1_1.id}"))
    assert_equal(6, Check.count("section_id=#{section_01_1.id}"))

    post(:append_check,
         :new_check => new_check,
         :check     => check)
	 
    assert_equal('Appended check successfully.', flash['notice'])
    assert_redirected_to(:id     => subsection_01_1_1.id,
                         :action => 'modify_checks')

    assert_equal(7, Check.count("section_id=#{section_01_1.id}"))
    checks = Check.find(:all,
                        :conditions => "subsection_id=#{subsection_01_1_1.id}",
                        :order      => 'sort_order ASC')
    assert_equal(4, checks.size)

    0.upto(checks.size-1) { |x| assert_equal(x+1, checks[x][:sort_order]) }

    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(6, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(4, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(4, checklist.dr_designer_auditor_count)

    assert_equal(checks(:check_01).id,        checks[0][:id])
    assert_equal(checks(:check_02).id,        checks[1][:id])
    assert_equal(checks(:check_03).id,        checks[2][:id])
    assert_equal('New Check APPEND',          checks[3][:title])

  end


  ######################################################################
  #
  # test_append
  #
  # Description:
  # This method does the functional testing of the append method
  # from the CheckController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_appends

    # Try editing without logging in.
    post :append
    
    assert_redirected_to(:controller => 'user',
                         :action     => 'login')

    # Try editing from a non-Admin account.
    set_non_admin
    post :append
    
    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try editing from an Admin account
    set_admin
    post(:append,
         :id      => checks(:check_01).id)

    assert_response 200
    assert_equal(checks(:check_01).section_id,
                 assigns(:new_check).section_id)
    assert_equal(checks(:check_01).subsection_id,
                 assigns(:new_check).subsection_id)
    assert_equal(checks(:check_01).check_type,
                 assigns(:new_check).check_type)

  end


  ######################################################################
  #
  # test_modify_checks
  #
  # Description:
  # This method does the functional testing of the modify_checks method
  # from the CheckController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_modify_checks

    subsection_01_1_1 = subsections(:subsection_01_1_1)
    # Try editing without logging in.
    @request.session[:user]        = nil
    @request.session[:active_role] = nil
    @request.session[:roles]       = nil
    get(:modify_checks,
        :id            => subsection_01_1_1.id)
    
    assert_redirected_to(:controller => 'user',
                         :action     => 'login')
    assert_equal('Please log in', flash[:notice])

    # Try editing from an Admin account
    set_admin
    get(:modify_checks,
        :id            => subsection_01_1_1.id)
    
    assert_response 200
    assert_equal(subsection_01_1_1.id, assigns(:subsection).id)
    # TODO:
    # Is there a better way to test than with hard code?
    # The only query I can think of is the same one that 
    # is used in the method
    assert_equal(3, assigns(:checks).size)

    # Try with a subsection that has no checks.
    subsection_01_2_3 = subsections(:subsection_01_2_3)
    get(:modify_checks,
        :id            => subsection_01_2_3.id)

    assert_redirected_to(:action => 'add_first',
                         :id     => subsection_01_2_3.id)
  end


  ######################################################################
  #
  # test_add_first
  #
  # Description:
  # This method does the functional testing of the add_first method
  # from the CheckController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_add_first

    subsection_01_2_3 = subsections(:subsection_01_2_3)
    
    @request.session[:user]        = nil
    @request.session[:active_role] = nil
    @request.session[:roles]       = nil
    get(:add_first,
        :id            => subsection_01_2_3.id)
    
    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    set_admin
    get(:add_first,
        :id            => subsection_01_2_3.id)

    assert_response 200
    assert_equal(1, assigns(:new_check).sort_order)

  end


  ######################################################################
  #
  # test_insert_first
  #
  # Description:
  # This method does the functional testing of the insert_first method
  # from the CheckController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_insert_first

    subsection_01_1_1 = subsections(:subsection_01_1_1)
    set_admin
    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(3, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(3, checklist.dr_designer_auditor_count)

    new_check = {
      'date_code_check' => '1',
      'full_review'     => '0',
      'title'           => 'First Check',
      'dot_rev_check'   => '1',
      'url'             => '',
      'check'           => 'text',
      'check_type'      => 'yes_no'
    }

    subsection_01_2_3 = subsections(:subsection_01_2_3)
    section_01_2      = sections(:section_01_2)
    
    assert_equal(0, Check.count("subsection_id=#{subsection_01_2_3.id}"))
    assert_equal(6, Check.count("section_id=#{section_01_2.id}"))

    post(:insert_first,
         :new_check  => new_check,
         :section    => { 'id'           => subsection_01_2_3.section_id,
                          'checklist_id' => subsection_01_2_3.checklist_id },
	 :subsection => { 'id' => subsection_01_2_3.id })
	 
    assert_equal('Added first check successfully.',
		 flash['notice'])
    assert_redirected_to(:controller => 'checklist',
                         :action     => 'edit',
                         :id         => subsection_01_2_3.checklist_id)


    assert_equal(7, Check.count("section_id=#{section_01_2.id}"))
    checks = Check.find(:all,
                        :conditions => "subsection_id=#{subsection_01_2_3.id}",
                        :order      => 'sort_order ASC')
    assert_equal(1, checks.size)
    assert_equal('First Check',   checks[0][:title])

    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(1, checklist.dc_designer_only_count)
    assert_equal(3, checklist.dc_designer_auditor_count)
    assert_equal(1, checklist.dr_designer_only_count)
    assert_equal(3, checklist.dr_designer_auditor_count)

  end


  ######################################################################
  #
  # test_move_down
  #
  # Description:
  # This method does the functional testing of the move_down method
  # from the CheckController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_move_down

    subsection_01_1_1 = subsections(:subsection_01_1_1)
    checks = Check.find(:all,
                        :conditions => "subsection_id=#{subsection_01_1_1.id}",
                        :order      => 'sort_order ASC')
    assert_equal(checks(:check_01).id, checks[0].id)
    assert_equal(checks(:check_02).id, checks[1].id)
    assert_equal(checks(:check_03).id, checks[2].id)

    set_admin
    get(:move_down,
        :id         => checks(:check_02).id);
    
    assert_equal('Checks were re-ordered', flash['notice'])
    assert_redirected_to(:action => 'modify_checks',
                         :id     => subsection_01_1_1.id)

    checks = Check.find(:all,
                        :conditions => "subsection_id=#{subsection_01_1_1.id}",
                        :order      => 'sort_order ASC')
    assert_equal(checks(:check_01).id, checks[0].id)
    assert_equal(checks(:check_03).id, checks[1].id)
    assert_equal(checks(:check_02).id, checks[2].id)

  end


  ######################################################################
  #
  # test_move_up
  #
  # Description:
  # This method does the functional testing of the move_up method
  # from the CheckController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_move_up

    subsection_01_1_1 = subsections(:subsection_01_1_1)
    checks = Check.find(:all,
                        :conditions => "subsection_id=#{subsection_01_1_1.id}",
                        :order      => 'sort_order ASC')
    assert_equal(checks(:check_01).id, checks[0].id)
    assert_equal(checks(:check_02).id, checks[1].id)
    assert_equal(checks(:check_03).id, checks[2].id)

    set_admin
    get(:move_up,
        :id         => checks(:check_03).id);
    
    assert_equal('Checks were re-ordered', flash['notice'])
    assert_redirected_to(:action => 'modify_checks',
                         :id     => subsection_01_1_1.id)

    checks = Check.find(:all,
                        :conditions => "subsection_id=#{subsection_01_1_1.id}",
                        :order      => 'sort_order ASC')
    assert_equal(checks(:check_01).id, checks[0].id)
    assert_equal(checks(:check_03).id, checks[1].id)
    assert_equal(checks(:check_02).id, checks[2].id)

  end


  ######################################################################
  #
  # test_destroy
  #
  # Description:
  # This method does the functional testing of the destroy method
  # from the CheckController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_destroy

    subsection_01_1_1 = subsections(:subsection_01_1_1)
    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(3, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(3, checklist.dr_designer_auditor_count)

    @request.session[:user]        = nil
    @request.session[:active_role] = nil
    @request.session[:roles]       = nil

    get(:destroy,
        :id            => checks(:check_02).id)
    
    assert_redirected_to(:controller => 'user',
                         :action     => 'login')
    assert_equal('Please log in', flash[:notice])

    set_non_admin
    get(:destroy,
        :id            => checks(:check_02).id)
    
    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    set_admin
    section_01_1 = sections(:section_01_1)
    subsection_id = checks(:check_02).subsection_id
    assert_equal(3, Check.count("subsection_id=#{subsection_id}"))
    assert_equal(6, Check.count("section_id=#{section_01_1.id}"))

    get(:destroy,
        :id            => checks(:check_02).id)

    assert_equal('Check deletion successful.', flash['notice'])
    assert_equal(5, Check.count("section_id=#{section_01_1.id}"))
    checks = Check.find(:all,
                        :conditions => "subsection_id=#{subsection_id}",
                        :order      => 'sort_order ASC')
    assert_equal(2, checks.size)

    0.upto(checks.size-1) { |x| assert_equal(x+1, checks[x][:sort_order]) }
    
    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(4, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(2, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(2, checklist.dr_designer_auditor_count)

  end


  ######################################################################
  #
  # test_destroy_list
  #
  # Description:
  # This method does the functional testing of the destroy_list method
  # from the CheckController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_destroy_list

    subsection_01_1_1 = subsections(:subsection_01_1_1)
    
    set_non_admin
    get(:destroy_list,
        :id            => subsection_01_1_1.id)
    
    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    set_admin
    section_01_1 = sections(:section_01_1)
    assert_equal(3, Check.count("subsection_id=#{subsection_01_1_1.id}"))
    assert_equal(6, Check.count("section_id=#{section_01_1.id}"))

    get(:destroy_list,
        :id            => subsection_01_1_1.id)

    assert_equal('All checks deleted successfully', flash['notice'])
    assert_redirected_to(:controller => 'checklist',
                         :action     => 'edit',
                         :id         => subsection_01_1_1.checklist_id)

    assert_equal(3, Check.count("section_id=#{section_01_1.id}"))
    assert_equal(0, Check.count("subsection_id=#{subsection_01_1_1.id}"))

    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(3, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(0, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(0, checklist.dr_designer_auditor_count)

    get(:destroy_list,
        :id            => subsections(:subsection_01_1_2).id)

    subsection_01_1_2 = subsections(:subsection_01_1_2)
    assert_equal(0, Check.count("section_id=#{section_01_1.id}"))
    assert_equal(0, Check.count("subsection_id=#{subsection_01_1_2.id}"))

    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(3, checklist.designer_only_count)
    assert_equal(3, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(0, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(0, checklist.dr_designer_auditor_count)

    subsection_01_2_1 = subsections(:subsection_01_2_1)
    section_01_2      = sections(:section_01_2)
    get(:destroy_list,
        :id            => subsection_01_2_1.id)

    assert_equal(3, Check.count("section_id=#{section_01_2.id}"))
    assert_equal(0, Check.count("subsection_id=#{subsection_01_2_1.id}"))

    checklist = Checklist.find(subsection_01_2_1.checklist_id)
    assert_equal(0, checklist.designer_only_count)
    assert_equal(3, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(0, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(0, checklist.dr_designer_auditor_count)

    subsection_01_2_2 = subsections(:subsection_01_2_2)
    get(:destroy_list,
        :id            => subsection_01_2_2.id)

    assert_equal(0, Check.count("section_id=#{section_01_2.id}"))
    assert_equal(0, Check.count("subsection_id=#{subsection_01_2_1.id}"))

    checklist = Checklist.find(subsection_01_2_1.checklist_id)
    assert_equal(0, checklist.designer_only_count)
    assert_equal(0, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(0, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(0, checklist.dr_designer_auditor_count)

    subsection_10_1_1 = subsections(:subsection_10_1_1)
    get(:destroy_list,
        :id            => subsection_10_1_1.id)

    assert_equal('This is a released checklist.  No checks were deleted.', 
                 flash['notice'])
    assert_redirected_to(:controller => 'checklist',
                         :action     => 'edit',
                         :id         => subsection_10_1_1.checklist_id)

  end


  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update method
  # from the CheckController class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_update

    section_01_1      = sections(:section_01_1)
    subsection_01_1_1 = subsections(:subsection_01_1_1)
    
    set_admin

    assert_equal(6, Check.count("section_id=#{section_01_1.id}"))
    assert_equal(3, Check.count("subsection_id=#{subsection_01_1_1.id}"))

    check = Check.find(checks(:check_01).id)
    assert(checks(:check_01).id, check.id)

    check.check_type = 'designer_only'
    get(:update,
        :check  => check.attributes)

    assert_equal('Check was successfully updated.', flash['notice'])
    assert_redirected_to(:action => 'modify_checks',
                         :id     => subsection_01_1_1.id)

    assert_equal(6, Check.count("section_id=#{section_01_1.id}"))
    assert_equal(3, Check.count("subsection_id=#{subsection_01_1_1.id}"))

    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(1, checklist.dc_designer_only_count)
    assert_equal(2, checklist.dc_designer_auditor_count)
    assert_equal(1, checklist.dr_designer_only_count)
    assert_equal(2, checklist.dr_designer_auditor_count)

    check.full_review = 1
    get(:update,
        :check  => check.attributes)

    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(7, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(1, checklist.dc_designer_only_count)
    assert_equal(2, checklist.dc_designer_auditor_count)
    assert_equal(1, checklist.dr_designer_only_count)
    assert_equal(2, checklist.dr_designer_auditor_count)

    check.date_code_check = 0
    get(:update,
        :check  => check.attributes)

    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(7, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(2, checklist.dc_designer_auditor_count)
    assert_equal(1, checklist.dr_designer_only_count)
    assert_equal(2, checklist.dr_designer_auditor_count)

    check.dot_rev_check = 0
    get(:update,
        :check  => check.attributes)

    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(7, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(2, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(2, checklist.dr_designer_auditor_count)

    check.full_review = 0
    get(:update,
        :check  => check.attributes)

    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(2, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(2, checklist.dr_designer_auditor_count)

    check.check_type      = 'designer_auditor'
    check.date_code_check = 1
    get(:update,
        :check  => check.attributes)

    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(3, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(2, checklist.dr_designer_auditor_count)

    check.dot_rev_check = 1
    get(:update,
        :check  => check.attributes)

    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(3, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(3, checklist.dr_designer_auditor_count)


    check = Check.find(checks(:check_14).id)
    assert(checks(:check_14).id, check.id)

    check.check_type = 'designer_only'
    get(:update,
        :check  => check.attributes)

    assert_equal('Check is locked.  The parent checklist is released.',
                 flash['notice'])


  end



  def dump(message, subsection_id=0)

    if (subsection_id == 0)
      checks = Check.find_all("1", "subsection_id ASC")
    else
      checks = Check.find_all("subsection_id=#{subsection_id}",
			      "sort_order ASC")
    end

    print "\n"
    print "*** #{message} \n"
    print " Number of checks: #{checks.size}\n\n"
    print "|********************************************************|\n"
    print "|     ID      |  SUBSECTION |   SECTION   |  SORT ORDER  |\n"
    for c in checks
      printf("|%12s |%12s |%12s | %12s |",
	     c.id, c.subsection_id, c.section_id, c.sort_order)
      print "\n"
    end
    print "|********************************************************|\n"
  end


  def dump_types(message, checklist_id=0)

    if (checklist_id == 0)
      checks = Check.find_all("1", "subsection_id ASC")
    else
      checks = Array.new
      subsections = Subsection.find_all("checklist_id=#{checklist_id}",
					"id ASC")
      for subsection in subsections
	sschecks = Check.find_all("subsection_id=#{subsection.id}",
				  "id ASC")
	checks += sschecks
      end
    end

    print "\n"
    print "*** #{message} \n"
    print " Number of checks: #{checks.size}\n\n"
    print "|********************************************************|\n"
    print "|     ID      | DATE CODE | DOT REV |  FULL |  TYPE\n"
    for c in checks
      printf("|%12s |%10s |%8s | %5s | %s",
	     c.id, 
	     c.date_code_check.to_s, 
	     c.dot_rev_check.to_s, 
	     c.full_review,
	     c.check_type)
      print "\n"
    end
    print "|********************************************************|\n"

    totals = {
      :fr_da => 0,
      :fr_do => 0,
      :dc_da => 0,
      :dc_do => 0,
      :dr_da => 0,
      :dr_do => 0
    }
    for c in checks
      if c.full_review == 1
	totals[:fr_da] += 1 if c.check_type == 'designer_auditor'
	totals[:fr_do] += 1 if c.check_type == 'designer_only' or c.check_type == 'yes_no'
      end
      if c.date_code_check == 1
	totals[:dc_da] += 1 if c.check_type == 'designer_auditor'
	totals[:dc_do] += 1 if c.check_type == 'designer_only' or c.check_type == 'yes_no'
      end
      if c.dot_rev_check == 1
	totals[:dr_da] += 1 if c.check_type == 'designer_auditor'
	totals[:dr_do] += 1 if c.check_type == 'designer_only' or c.check_type == 'yes_no'
      end
    end

    print "\n"
    print"Full Review, Designer/Auditor:       #{totals[:fr_da]}\n"
    print"Full Review, Designer Only:          #{totals[:fr_do]}\n"
    print"Date Code  Review, Designer/Auditor: #{totals[:dc_da]}\n"
    print"Date Code  Review, Designer Only:    #{totals[:dc_do]}\n"
    print"Dot Rev Review, Designer/Auditor:    #{totals[:dr_da]}\n"
    print"Dot Rev Review, Designer Only:       #{totals[:dr_do]}\n"
  end


end
