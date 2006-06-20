########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: checklist_controller_test.rb
#
# This file contains the functional tests for the checklist_controller
#
# Revision History:
#   $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'checklist_controller'

# Re-raise errors caught by the controller.
class ChecklistController; def rescue_action(e) raise e end; end

class ChecklistControllerTest < Test::Unit::TestCase
  def setup
    @controller = ChecklistController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end


  fixtures(:checklists,
	   :checks,
	   :sections,
	   :subsections,
	   :users)


  def test_1_id
    print("\n*** Checklist Controller Test\n")
    print("*** $Id$\n")
  end


  ######################################################################
  #
  # test_copy
  #
  # Description:
  # This method performs the functional testing of the copy method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_copy

    checklist_1_0 = checklists(:checklist_1_0)
    # Try copying without logging in.
    post(:copy,
         :id      => checklist_1_0.id)
    
    assert_redirected_to(:controller => 'user',
	                       :action     => 'login')

    # Try copying from a non-Admin account.
    set_non_admin
    post(:copy,
         :id      => checklist_1_0.id)
    
    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])


    # Try appending from an Admin account
    checklist = Checklist.find(checklist_1_0.id)
    assert_equal(7, checklist.designer_only_count)
    assert_equal(4, checklist.designer_auditor_count)
    assert_equal(2, checklist.dc_designer_only_count)
    assert_equal(5, checklist.dc_designer_auditor_count)
    assert_equal(2, checklist.dr_designer_only_count)
    assert_equal(5, checklist.dr_designer_auditor_count)

    check_count = 0
    sections = Section.find_all("checklist_id=#{checklist_1_0.id}")
    for section in sections
      check_count += Check.find_all("section_id=#{section.id}").size
    end
    assert_equal(12, check_count)

    checklists = Checklist.find_all("1")
    assert_equal(3, checklists.size)

    set_admin
    post(:copy,
         :id      => checklist_1_0.id)

    assert_redirected_to(:action => 'list')
    
    checklists = Checklist.find_all("1", "id ASC")
    assert_equal(4, checklists.size)

    checklist = checklists.pop

    assert_equal(1, checklist.major_rev_number)
    assert_equal(1, checklist.minor_rev_number)

    assert_equal(7, checklist.designer_only_count)
    assert_equal(4, checklist.designer_auditor_count)
    assert_equal(2, checklist.dc_designer_only_count)
    assert_equal(5, checklist.dc_designer_auditor_count)
    assert_equal(2, checklist.dr_designer_only_count)
    assert_equal(5, checklist.dr_designer_auditor_count)

    check_count = 0
    sections = Section.find_all("checklist_id=#{checklist.id}")
    for section in sections
      check_count += Check.find_all("section_id=#{section.id}").size
    end
    assert_equal(12, check_count)


    post(:copy,
         :id      => checklist_1_0.id)
    
    checklists = Checklist.find_all("1", "id ASC")
    assert_equal(5, checklists.size)

    checklist = checklists.pop

    assert_equal(1, checklist.major_rev_number)
    assert_equal(2, checklist.minor_rev_number)

    assert_equal(7, checklist.designer_only_count)
    assert_equal(4, checklist.designer_auditor_count)
    assert_equal(2, checklist.dc_designer_only_count)
    assert_equal(5, checklist.dc_designer_auditor_count)
    assert_equal(2, checklist.dr_designer_only_count)
    assert_equal(5, checklist.dr_designer_auditor_count)

  end


  ######################################################################
  #
  # test_destroy
  #
  # Description:
  # This method performs the functional testing of the destroy method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_destroy

    checklist_0_1 = checklists(:checklist_0_1)
    # Try destroying without logging in.
    post(:destroy,
         :id      => checklist_0_1.id)
    
    assert_redirected_to(:controller => 'user',
                         :action     => 'login')

    # Try destroying from a non-Admin account.
    set_non_admin
    post(:destroy,
         :id      => checklist_0_1.id)
    
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])


    # Try destroying from an Admin account
    check_count = 0
    sections = Section.find_all("checklist_id=#{checklist_0_1.id}")
    subsections = Subsection.find_all("checklist_id=#{checklist_0_1.id}")
    for section in sections
      check_count += Check.find_all("section_id=#{section.id}").size
    end
    assert_equal(17, check_count)
    assert_equal( 4, sections.size)
    assert_equal( 7, subsections.size)

    checklists = Checklist.find_all("1")
    assert_equal(3, checklists.size)

    set_admin
    post(:destroy,
         :id      => checklist_0_1.id)

    assert_redirected_to(:action => 'list')

    checklists = Checklist.find_all("1")
    assert_equal(2, checklists.size)

    check_count = 0
    sections = Section.find_all("checklist_id=#{checklist_0_1.id}")
    subsections = Subsection.find_all("checklist_id=#{checklist_0_1.id}")
    for section in sections
      check_count += Check.find_all("section_id=#{section.id}").size
    end
    assert_equal(0, check_count)
    assert_equal(0, sections.size)
    assert_equal(0, subsections.size)

  end


  ######################################################################
  #
  # test_display_list
  #
  # Description:
  # This method performs the functional testing of the display_list
  # method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_display_list

    checklist_1_0 = checklists(:checklist_1_0)
    
    set_admin
    checklist = { :id => checklist_1_0.id }
    review    = { :review_type => 'full_review' }
    get(:display_list,
        :checklist     => checklist,
        :review        => review)

    assert_equal(checklist_1_0.id, assigns(:checklist).id)
    assert_equal(2,                assigns(:sections).size)
    assert_equal('full_review',    assigns(:review_type))

  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method performs the functional testing of the edit method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_edit

    checklist_0_1 = checklists(:checklist_0_1)
    
    # Try editing without logging in.
    post(:edit,
         :id      => checklist_0_1.id)
    
    assert_redirected_to(:controller => 'user',
                         :action     => 'login')

    # Try destroying from a non-Admin account.
    set_non_admin
    post(:edit,
         :id    => checklist_0_1.id)
    
    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    set_admin
    post(:edit,
         :id      => checklist_0_1.id)

    assert_response 200

  end
  

  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method performs the functional testing of the list method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_list

    # Try editing without logging in.
    post(:list)
    
    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')

    # Try destroying from a non-Admin account.
    set_non_admin
    post(:list)
    
    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    set_admin
    post(:list)

    assert_response 200
    assert_equal(3, assigns(:checklists).size)

  end


  ######################################################################
  #
  # test_release
  #
  # Description:
  # This method performs the functional testing of the release method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_release

    checklist_0_1 = checklists(:checklist_0_1)
    
    # Try releasing without logging in.
    post(:release,
         :id      => checklist_0_1.id)
    
    assert_redirected_to(:controller => 'user',
                         :action     => 'login')

    # Try releasing from a non-Admin account.
    checklists = Checklist.find_all('1')
    assert_equal(3, checklists.size)

    checklist = Checklist.find(checklist_0_1.id)
    assert_equal(0, checklist.major_rev_number)
    assert_equal(1, checklist.minor_rev_number)

    set_non_admin
    post(:release,
         :id      => checklist_0_1.id)
    
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only],     flash['notice'])

    set_admin
    post(:release,
         :id      => checklist_0_1.id)

    assert_redirected_to(:action => 'list')
    assert_equal('Checklist successfully released', flash['notice'])

    checklists = Checklist.find_all('1')
    assert_equal(3, checklists.size)

    checklist = Checklist.find(checklist_0_1.id)
    assert_equal(3, checklist.major_rev_number)
    assert_equal(0, checklist.minor_rev_number)

  end


  ######################################################################
  #
  # test_select_view
  #
  # Description:
  # This method performs the functional testing of the select_view method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_select_view

    checklist_1_0 = checklists(:checklist_1_0)
    
    set_admin
    get(:select_view,
        :id           => checklist_1_0.id)

    assert_equal(checklist_1_0.id, assigns(:checklist).id)
  end

  ######################################################################
  #
  # test_view
  #
  # Description:
  # This method performs the functional testing of the view method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_view

    checklist_1_0 = checklists(:checklist_1_0)
    
    set_admin
    get(:view,
        :id => checklist_1_0.id)

    assert_equal(checklist_1_0.id, assigns(:checklist).id)

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
  def dump(message)

    checklists = Checklist.find_all("1", "id ASC")

    print "\n"
    print "*** #{message} \n"
    print " Number of checklists: #{checklists.size}\n\n"
    print "|********************************************************|\n"
    print "|     ID      |   MAJOR REV |  MINOR REV  |\n"
    for c in checklists
      printf("|%12s |%12s |%12s |\n",
	     c.id, c.major_rev_number, c.minor_rev_number)
    end
    print "|********************************************************|\n"
  end


  def dump_checklist(id)
    print "\n"
    print "  *** Dumping checklist ***\n"

    cl = Checklist.find(id)

    print "  ID:  #{cl.id}\n"
      print "  REV: #{cl.major_rev_number}.#{cl.minor_rev_number}\n" 

      section_list = Section.find_all("checklist_id='#{cl.id}'", 
                                      'sort_order ASC')
    print "\n    #{section_list.size} sections\n"
    for sect in section_list
      print "\n    #{sect.name} [#{sect.id}]\n"
      print "        Full Review: "
      print "YES\n" if sect.full_review?
      print "No\n"  if not sect.full_review?
      print "        Date Code:   "
      print "YES\n" if sect.date_code_check?
      print "No\n"  if not sect.date_code_check?
      print "        Dot Rev:     "
      print "YES\n" if sect.dot_rev_check?
      print "No\n"  if not sect.dot_rev_check?

      subsection_list = Subsection.find_all("section_id='#{sect.id}'",
                                            'sort_order ASC')
      print "\n      #{subsection_list.size} subsections\n"
      for subsect in subsection_list
        print "\n      #{subsect.name} [#{subsect.id}]\n"
        print "        Full Review: "
        print "YES\n" if subsect.full_review?
        print "No\n"  if not subsect.full_review?
        print "        Date Code:   "
        print "YES\n" if subsect.date_code_check?
        print "No\n"  if not subsect.date_code_check?
        print "        Dot Rev:     "
        print "YES\n" if subsect.dot_rev_check?
        print "No\n"  if not subsect.dot_rev_check?

        check_list = Check.find_all("subsection_id='#{subsect.id}'",
                                    'sort_order ASC')
        print "\n      #{check_list.size} checks\n"
        for check in check_list
          print "\n      #{check.check} [#{check.id}]\n"
          print "        Full Review: "
          print "YES\n" if check.full_review?
          print "No\n"  if not check.full_review?
          print "        Date Code:   "
          print "YES\n" if check.date_code_check?
          print "No\n"  if not check.date_code_check?
          print "        Dot Rev:     "
          print "YES\n" if check.dot_rev_check?
          print "No\n"  if not check.dot_rev_check?
        end
      end
    end
    print "\n  *************************\n"
  end


end
