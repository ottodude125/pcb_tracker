########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: subsection_controller_test.rb
#
# This file contains the functional tests for the subsection_controller
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'
require 'subsection_controller'

# Re-raise errors caught by the controller.
class SubsectionController; def rescue_action(e) raise e end; end

class SubsectionControllerTest < Test::Unit::TestCase
  def setup
    @controller = SubsectionController.new
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

  def test_1_id
    print ("\n*** Subsection Controller Test\n")
    print ("*** $Id$\n")
  end
  
  ######################################################################
  #
  # test_append
  #
  # Description:
  # This method does the functional testing of the append method.
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
  def test_append

    # Try editing without logging in.
    post(:append,
         :id      => subsections(:subsection_01_1_1).id)
    
    assert_redirected_to(:controller => 'user',
                         :action     => 'login')

    # Try editing from a non-Admin account.
    set_non_admin
    post(:append,
         :id      => subsections(:subsection_01_1_1).id)
    
    assert_redirected_to(:controller => 'tracker',
			                   :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try editing from an Admin account
    set_admin
    post(:append,
         :id      => subsections(:subsection_01_1_1).id)

    assert_response 200
    section_01_1 = sections(:section_01_1)
    assert_equal(section_01_1.id,
		             assigns(:new_subsection).section_id)
    assert_equal(section_01_1.checklist_id,
		             assigns(:new_subsection).checklist_id)

  end
  

  ######################################################################
  #
  # test_append_subsection
  #
  # Description:
  # This method does the functional testing of the append_subsection
  # method.
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
  def test_append_subsection

    set_admin
    new_subsection = {
      'date_code_check' => '1',
      'dot_rev_check'   => '1',
      'full_review'     => '1',
      'name'            => 'New Subsection',
      'note'            => 'New subsection note',
      'url'             => 'www.pirateball.com'
    }
    subsection = {'id' => subsections(:subsection_01_1_1).id}

    section_01_1 = sections(:section_01_1)
    subsections = Subsection.find_all("section_id=#{section_01_1.id}")
    assert_equal(2, subsections.size)

    post(:append_subsection,
         :new_subsection     => new_subsection,
         :subsection         => subsection)

    assert_equal('Appended subsection successfully.', flash['notice'])
    assert_redirected_to(:id         => section_01_1.checklist_id,
                         :action     => 'edit',
                         :controller => 'checklist')

    subsections = Subsection.find_all("section_id=#{section_01_1.id}",
				                              'sort_order ASC')
    assert_equal(3, subsections.size)

    1.upto(subsections.size) { |x| assert_equal((x), subsections[x-1][:sort_order])}

    assert_equal(subsections(:subsection_01_1_1).id, subsections[0][:id])
    assert_equal('New Subsection',                   subsections[1][:name])
    assert_equal(subsections(:subsection_01_1_2).id, subsections[2][:id])

  end

  ######################################################################
  #
  # test_create_first
  #
  # Description:
  # This method does the functional testing of the create_first
  # method.
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
  def test_create_first

    @request.session[:user]        = nil
    @request.session[:active_role] = nil
    @request.session[:roles]       = nil
    get(:create_first,
        :id            => subsections(:subsection_01_1_1).section_id)
    
    assert_redirected_to(:controller => 'tracker',
			                   :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    set_admin
    section_01_1 = sections(:section_01_1)
    get(:create_first,
        :id            => section_01_1.id)

    assert_response 200
    assert_equal(section_01_1.id, assigns(:section).id)
    assert_equal(section_01_1.id, assigns(:new_subsection).section_id)
    assert_equal(section_01_1.checklist_id,
		             assigns(:new_subsection).checklist_id)
    assert_equal(1,               assigns(:new_subsection).sort_order)
    assert_equal(section_01_1.date_code_check,
		             assigns(:new_subsection).date_code_check)
  end

  ######################################################################
  #
  # test_destroy
  #
  # Description:
  # This method does the functional testing of the test_destroy method.
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
  def test_destroy
    
    checklist = Checklist.find(subsections(:subsection_01_1_1).checklist_id)
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
        :id            => subsections(:subsection_01_1_1).id)
    
    assert_redirected_to(:controller => 'user',
			                   :action     => 'login')
    assert_equal('Please log in', flash[:notice])

    set_non_admin
    get(:destroy,
	      :id            => subsections(:subsection_01_1_1).id)
    
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only],  flash['notice'])

    set_admin
    section_01_1 = sections(:section_01_1)
    subsections = Subsection.find_all("section_id=#{section_01_1.id}",
				      'sort_order ASC')
    assert_equal(2, subsections.size)
    assert_equal(subsections(:subsection_01_1_1).sort_order,
                 subsections[0].sort_order)
    assert_equal(subsections(:subsection_01_1_2).sort_order,
                 subsections[1].sort_order)

    subsection_01_1_1 = subsections(:subsection_01_1_1)
    checks = Check.find_all("subsection_id=#{subsection_01_1_1.id}")
    assert_equal(3, checks.size)
    section_01_1 = sections(:section_01_1)
    checks = Check.find_all("section_id=#{section_01_1.id}")
    assert_equal(6, checks.size)

    get(:destroy,
        :id            => subsection_01_1_1.id)

    assert_equal('Subsection deletion successful.', flash['notice'])

    checks = Check.find_all("section_id=#{section_01_1.id}")
    assert_equal(3, checks.size)
    checks = Check.find_all("subsection_id=#{subsection_01_1_1.id}",
			                      'sort_order ASC')
    assert_equal(0, checks.size)

    subsections = Subsection.find_all("section_id=#{section_01_1.id}",
				      'sort_order ASC')

    assert_equal(1, subsections.size)
    assert_equal(subsections(:subsection_01_1_2).id, subsections[0].id)

    0.upto(subsections.size-1) { |x| 
      assert_equal((x + 1), subsections[x].sort_order)
    }

    checklist = Checklist.find(section_01_1.checklist_id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(3, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(0, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(0, checklist.dr_designer_auditor_count)

    subsection_01_1_2 = subsections(:subsection_01_1_2)
    checks = Check.find_all("subsection_id=#{subsection_01_1_2.id}")
    assert_equal(3, checks.size)

    get(:destroy,
        :id            => subsection_01_1_2.id)

    checks = Check.find_all("section_id=#{section_01_1.id}")
    assert_equal(0, checks.size)
    checks = Check.find_all("subsection_id=#{subsection_01_1_1.id}",
			                      'sort_order ASC')
    assert_equal(0, checks.size)

    checklist = Checklist.find(subsection_01_1_1.checklist_id)
    assert_equal(3, checklist.designer_only_count)
    assert_equal(3, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(0, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(0, checklist.dr_designer_auditor_count)

    subsection_01_2_1 = subsections(:subsection_01_2_1)
    checks = Check.find_all("subsection_id=#{subsection_01_2_1.id}")
    assert_equal(3, checks.size)

    get(:destroy,
        :id            => subsection_01_2_1.id)

    section_01_2 = sections(:section_01_2)
    checks = Check.find_all("section_id=#{section_01_2.id}")
    assert_equal(3, checks.size)
    checks = Check.find_all("subsection_id=#{subsection_01_2_1.id}",
			                      'sort_order ASC')
    assert_equal(0, checks.size)

    checklist = Checklist.find(sections(:section_01_1).checklist_id)
    assert_equal(0, checklist.designer_only_count)
    assert_equal(3, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(0, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(0, checklist.dr_designer_auditor_count)

  end

  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the test_edit method.
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
    post(:edit,
         :id => subsections(:subsection_01_1_1).id)
    
    assert_redirected_to(:controller => 'user',
			                   :action     => 'login')

    # Try editing from a non-Admin account.
    set_non_admin
    post(:edit,
	       :id => subsections(:subsection_01_1_1).id)
    
    assert_redirected_to(:controller => 'tracker',
			                   :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try editing from an Admin account
    set_admin
    post(:edit,
         :id => subsections(:subsection_01_1_1).id)

    assert_response 200
    assert_equal(subsections(:subsection_01_1_1).id,
		             assigns(:subsection).id)

    assert_raise(ActiveRecord::RecordNotFound) {
                   post(:edit,
                   :id => 32423423)
    }

  end


  ######################################################################
  #
  # test_insert
  #
  # Description:
  # This method does the functional testing of the insert method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  # Verifies the following
  #   - User can not insert unless logged in as an ADMIN
  #   - 
  #
  ######################################################################
  #
  def test_insert

    # Try inserting from a non-Admin account.
    set_non_admin
    post(:insert,
	       :id => subsections(:subsection_01_1_1).id)
    
    assert_redirected_to(:controller => 'tracker',
			                   :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try inserting from an Admin account
    set_admin
    post(:insert,
         :id => subsections(:subsection_01_1_1).id)

    assert_response 200
    assert_equal(subsections(:subsection_01_1_1).checklist_id,
                 assigns(:new_subsection).checklist_id)
    assert_equal(subsections(:subsection_01_1_1).section_id,
                 assigns(:new_subsection).section_id)


  end


  ######################################################################
  #
  # test_insert_first
  #
  # Description:
  # This method does the functional testing of the insert_first
  # method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #   - 
  #
  ######################################################################
  #
  def test_insert_first

    set_admin
    section_01_3 = sections(:section_01_3)
    subsections = Subsection.find_all("section_id=#{section_01_3.id}")
    assert_equal(0, subsections.size)
    section_01_3 = sections(:section_01_3)
    subsections_in_checklist = Subsection.find_all("checklist_id=#{section_01_3.checklist_id}")
    assert_equal(7, subsections_in_checklist.size)

    new_subsection = {
      'name'   => 'subsection_01_3_1',
      'note'   => 'adding the first subsection',
      'url'    => 'www.pirateball.com',
      'date_code_check' => '1',
      'dot_rev_check'   => '1',
      'full_review'     => '1'
    }

    post(:insert_first,
         :new_subsection => new_subsection,
         :section        => { 'id' => sections(:section_01_3).id })
    
    section_01_3 = sections(:section_01_3)
    subsections = Subsection.find_all("section_id=#{section_01_3.id}")
    assert_equal(1, subsections.size)
    subsections_in_checklist = Subsection.find_all("checklist_id=#{section_01_3.checklist_id}")
    assert_equal(8, subsections_in_checklist.size)

    subsection = subsections.pop

    assert_equal(1,                         subsection.sort_order)
    assert_equal(section_01_3.id,           subsection.section_id)
    assert_equal(section_01_3.checklist_id, subsection.checklist_id)

    # Verify the counters were not impacted.
    checklist = Checklist.find(subsections(:subsection_01_1_1).checklist_id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(3, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(3, checklist.dr_designer_auditor_count)
    
  end


  ######################################################################
  #
  # test_insert_subsection
  #
  # Description:
  # This method does the functional testing of the insert_subsection
  # method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #   - 
  #
  ######################################################################
  #
  def test_insert_subsection

    set_admin
    section_01_1 = sections(:section_01_1)
    subsections = Subsection.find_all("section_id=#{section_01_1.id}")
    assert_equal(2, subsections.size)

    new_subsection = {
      'name'   => 'subsection_01_1_0.5',
      'note'   => 'inserting before the first subsection',
      'url'    => '',
      'date_code_check' => '1',
      'dot_rev_check'   => '1',
      'full_review'     => '1'
    }

    post(:insert_subsection,
         :new_subsection => new_subsection,
         :subsection     => { 'id' => subsections(:subsection_01_1_1).id })

    subsections = Subsection.find_all("section_id=#{section_01_1.id}",
				                              'sort_order ASC')
    assert_equal(3, subsections.size)

    assert_equal('subsection_01_1_0.5', subsections[0].name)
    assert_equal('Subsection 1 Note',   subsections[1].note)
    assert_equal('Subsection 2 Note',   subsections[2].note)

  end


  ######################################################################
  #
  # test_move_down
  #
  # Description:
  # This method does the functional testing of the move_down
  # method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #   - 
  #
  ######################################################################
  #
  def test_move_down

    section_01_2 = sections(:section_01_2)
    subsects = Subsection.find_all("section_id=#{section_01_2.id}",
				                           'sort_order ASC')
    assert_equal(subsections(:subsection_01_2_1).id, subsects[0].id)
    assert_equal(subsections(:subsection_01_2_2).id, subsects[1].id)
    assert_equal(subsections(:subsection_01_2_3).id, subsects[2].id)
    assert_equal(3, subsects.size)

    set_non_admin
    get(:move_down,
        :id       => subsections(:subsection_01_2_2).id)

    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])
    assert_redirected_to(:controller => 'tracker',
			                   :action     => 'index')

    set_admin
    get(:move_down,
        :id       => subsections(:subsection_01_2_1).id)

    assert('Subsections were re-ordered', flash['notice'])
    assert_redirected_to(:action => 'edit',
			                   :id     => subsections(:subsection_01_2_2).checklist.id)
    
    subsects = Subsection.find_all("section_id=#{section_01_2.id}",
				   'sort_order ASC')
    assert_equal(subsections(:subsection_01_2_2).id, subsects[0].id)
    assert_equal(subsections(:subsection_01_2_1).id, subsects[1].id)
    assert_equal(subsections(:subsection_01_2_3).id, subsects[2].id)
    assert_equal(3, subsects.size)

  end


  ######################################################################
  #
  # test_move_up
  #
  # Description:
  # This method does the functional testing of the move_up
  # method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #   - 
  #
  ######################################################################
  #
  def test_move_up

    section_01_2 = sections(:section_01_2)
    subsects = Subsection.find_all("section_id=#{section_01_2.id}",
			                             'sort_order ASC')
    assert_equal(subsections(:subsection_01_2_1).id, subsects[0].id)
    assert_equal(subsections(:subsection_01_2_2).id, subsects[1].id)
    assert_equal(subsections(:subsection_01_2_3).id, subsects[2].id)
    assert_equal(3, subsects.size)

    set_non_admin

    get(:move_up,
        :id       => subsections(:subsection_01_2_2).id)

    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])
    assert_redirected_to(:controller => 'tracker',
			                   :action     => 'index')

    set_admin
    get(:move_up,
	      :id       => subsections(:subsection_01_2_2).id)

    assert('Subsections were re-ordered', flash['notice'])
    assert_redirected_to(:action => 'edit',
			                   :id     => subsections(:subsection_01_2_2).checklist.id)
    
    subsects = Subsection.find_all("section_id=#{section_01_2.id}",
				   'sort_order ASC')
    assert_equal(subsections(:subsection_01_2_2).id, subsects[0].id)
    assert_equal(subsections(:subsection_01_2_1).id, subsects[1].id)
    assert_equal(subsections(:subsection_01_2_3).id, subsects[2].id)
    assert_equal(3, subsects.size)

  end


  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update
  # method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #   - 
  #
  ######################################################################
  #
  def test_update

    set_admin

    subsection_01_1_2 = subsections(:subsection_01_1_2)
    subsection_01_1_1 = subsections(:subsection_01_1_1)
    subsect = Subsection.find(subsection_01_1_2.id)
    assert_equal(subsection_01_1_1.url, subsect.url)

    subsect.url = 'www.yahoo.com'
    get(:update,
        :subsection => subsect.attributes)

    assert_equal('Subsection was successfully updated.', flash['notice'])
    assert_redirected_to(:controller => 'checklist',
			                   :action     => 'edit',
                         :id         => subsection_01_1_1.checklist_id)

  end


  private


  ######################################################################
  #
  # dump
  #
  # Description:
  # This method dumps subsection data.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #   - 
  #
  ######################################################################
  #
  def dump(message, section_id=0)

    if (section_id == 0)
      subsections = Subsection.find_all("1", "section_id ASC")
    else
      subsections = Subsection.find_all("section_id=#{section_id}",
					"sort_order ASC")
    end
    print "\n"
    print "*** #{message} \n"
    print " Number of subsections: #{subsections.size}\n\n"
    print "|********************************************************|\n"
    print "|     ID      |   CHECKLIST |   SECTION   |  SORT ORDER  |\n"
    for s in subsections
      printf("|%12s |%12s |%12s | %12s |",
	     s.id, s.checklist_id, s.section_id, s.sort_order)
      print "\n"
    end
    print "|********************************************************|\n"
  end

end
