########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: check_test.rb
#
# This file contains the unit tests for the check model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class CheckTest < Test::Unit::TestCase
  fixtures :checks

  def setup
    @check = Check.find(checks(:check_18).id)
  end


  ######################################################################
  def test_create
    assert_kind_of Check,  @check

    check_18 = checks(:check_18)
    assert_equal check_18.id,              @check.id
    assert_equal check_18.section_id,      @check.section_id
    assert_equal check_18.subsection_id,   @check.subsection_id
    assert_equal check_18.title,           @check.title
    assert_equal check_18.check,           @check.check
    assert_equal check_18.url,             @check.url
    assert_equal check_18.full_review,     @check.full_review
    assert_equal check_18.date_code_check, @check.date_code_check
    assert_equal check_18.dot_rev_check,   @check.dot_rev_check
    assert_equal check_18.sort_order,      @check.sort_order
    assert_equal check_18.check_type,      @check.check_type
  end
  
  
  ######################################################################
  def test_accessors
  
    check_01 = checks(:check_01)
    check_04 = checks(:check_04)
    check_09 = checks(:check_09)
    
    assert(check_04.yes_no?)
    assert(!check_04.designer_auditor?)
    assert(!check_04.designer_only?)
    
    assert(check_01.designer_auditor?)
    assert(!check_01.yes_no?)
    assert(!check_01.designer_only?)
    
    assert(check_09.designer_only?)
    assert(!check_09.yes_no?)
    assert(!check_09.designer_auditor?)
  
  end


  ######################################################################
  def test_update

    assert_equal checks(:check_18).id, @check.id

    @check.title           = "Check One"
    @check.check           = "Check One Information"
    @check.url             = "www.disney.com"
    @check.full_review     = 0
    @check.date_code_check = 0
    @check.dot_rev_check   = 0
    @check.sort_order      = 3
    @check.check_type      = "yes_no"

    assert @check.save
    @check.reload 

    assert_equal "Check One",             @check.title
    assert_equal "Check One Information", @check.check
    assert_equal "www.disney.com",        @check.url
    assert_equal 0,                       @check.full_review
    assert_equal 0,                       @check.date_code_check
    assert_equal 0,                       @check.dot_rev_check
    assert_equal 3,                       @check.sort_order
    assert_equal "yes_no",                @check.check_type

  end


  ######################################################################
  def test_destroy
    @check.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Check.find(checks(:check_18).id) }
  end

end
