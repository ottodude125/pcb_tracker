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
    
    @checklist_101 = checklists(:checklists_101)
  end


  fixtures(:checklists,
	   :checks,
	   :sections,
	   :subsections,
	   :users)


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
    post(:copy, :id => checklist_1_0.id)
    assert_redirected_to(:controller => 'user', :action => 'login')

    # Try copying from a non-Admin account.
    set_non_admin
    post(:copy, :id => checklist_1_0.id)
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])


    # Try appending from an Admin account
    checklist = Checklist.find(checklist_1_0.id)
    assert_equal(7, checklist.designer_only_count)
    assert_equal(4, checklist.designer_auditor_count)
    assert_equal(2, checklist.dc_designer_only_count)
    assert_equal(5, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(2, checklist.dr_designer_auditor_count)

    check_count = 0
    checklist.each_check { |ch| check_count += 1 }
    assert_equal(12, check_count)

    checklist_count = Checklist.count

    set_admin
    post(:copy, :id => checklist_1_0.id)

    assert_redirected_to(:action => 'list')
    
    checklists = Checklist.find(:all, :order => "id ASC")
    checklist_count += 1
    assert_equal(checklist_count, checklists.size)

    checklist = checklists.pop

    assert_equal(1, checklist.major_rev_number)
    assert_equal(1, checklist.minor_rev_number)

    assert_equal(7, checklist.designer_only_count)
    assert_equal(4, checklist.designer_auditor_count)
    assert_equal(2, checklist.dc_designer_only_count)
    assert_equal(5, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(2, checklist.dr_designer_auditor_count)

    check_count = 0
    checklist.each_check { |ch| check_count += 1 }
    assert_equal(12, check_count)


    post(:copy, :id => checklist_1_0.id)
    
    checklists = Checklist.find(:all, :order => "id ASC")
    checklist_count += 1
    assert_equal(checklist_count, checklists.size)

    checklist = checklists.pop

    assert_equal(1, checklist.major_rev_number)
    assert_equal(2, checklist.minor_rev_number)

    assert_equal(7, checklist.designer_only_count)
    assert_equal(4, checklist.designer_auditor_count)
    assert_equal(2, checklist.dc_designer_only_count)
    assert_equal(5, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(2, checklist.dr_designer_auditor_count)

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
    post(:destroy, :id => checklist_0_1.id)
    assert_redirected_to(:controller => 'user', :action => 'login')

    # Try destroying from a non-Admin account.
    set_non_admin
    post(:destroy, :id => checklist_0_1.id)
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])


    total_checks      = Check.count
    total_subsections = Subsection.count
    total_sections    = Section.count
    total_checklists  = Checklist.count
    
    ids = { :checks      => [],
            :subsections => [],
            :sections    => [] }

    checklist_0_1.sections.each do |section|
      ids[:sections] << section.id
      section.subsections.each do |subsection|
        ids[:subsections] << subsection.id
        subsection.checks.each do |check|
          ids[:checks] << check.id
        end
      end
    end


    set_admin
    post(:destroy, :id => checklist_0_1.id)

    assert_redirected_to(:action => 'list')


    total_checks      -= ids[:checks].size
    total_subsections -= ids[:subsections].size
    total_sections    -= ids[:sections].size
    
    assert_equal(total_checks,       Check.count)
    assert_equal(total_subsections,  Subsection.count)
    assert_equal(total_sections,     Section.count)
    assert_equal(total_checklists-1, Checklist.count)

    all_checks      = Check.find(:all)
    all_subsections = Subsection.find(:all)
    all_sections    = Section.find(:all)
    all_checklists  = Checklist.find(:all)
    ids[:checks].each { |id| assert(!all_checks.detect { |c| c.id == id }) }
    ids[:subsections].each { |id| assert(!all_subsections.detect { |ss| ss.id == id })}
    ids[:sections].each { |id| assert(!all_sections.detect { |s| s.id == id })}
    assert(!all_checklists.detect { |cl| cl.id == checklist_0_1 })
    
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

    # Try listing without logging in.
    post(:list)
    
    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')

    # Try listing from a non-Admin account.
    set_non_admin
    post(:list)
    
    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    checklist_count = Checklist.count
    set_admin
    post(:list)

    assert_response(200)
    assert_equal(checklist_count, assigns(:checklists).size)

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
    post(:release, :id => checklist_0_1.id)
    
    assert_redirected_to(:controller => 'user', :action => 'login')

    # Try releasing from a non-Admin account.
    checklist_count = Checklist.count

    checklist = Checklist.find(checklist_0_1.id)
    assert_equal(0, checklist.major_rev_number)
    assert_equal(1, checklist.minor_rev_number)

    set_non_admin
    post(:release, :id => checklist_0_1.id)
    
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only],     flash['notice'])

    set_admin
    post(:release, :id => checklist_0_1.id)

    assert_redirected_to(:action => 'list')
    assert_equal('Checklist successfully released', flash['notice'])

    assert_equal(checklist_count, Checklist.count)
 
    checklist = Checklist.find(checklist_0_1.id)
    assert_equal(@checklist_101.major_rev_number+1, checklist.major_rev_number)
    assert_equal(0,                                 checklist.minor_rev_number)

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
                                      'position')
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
                                            'position')
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
                                    'position')
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
