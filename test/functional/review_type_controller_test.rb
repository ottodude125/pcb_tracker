########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: fab_house_controller_test.rb
#
# This file contains the functional tests for the fab house controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'review_type_controller'

# Re-raise errors caught by the controller.
class ReviewTypeController; def rescue_action(e) raise e end; end

class ReviewTypeControllerTest < Test::Unit::TestCase
  def setup
    @controller = ReviewTypeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end


  fixtures(:review_types,
           :users)


  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the ReviewType class
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

    # Try listing from a non-Admin account.
    # VERIFY: The user is redirected.
    set_non_admin
    post :list

    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal('Administrators only!  Check your role.',
                 flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    set_admin
    post(:list,
         :page => 1)

    assert_equal(6, assigns(:review_types).size)
  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the edit method
  # from the ReviewType class
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

    set_admin
    final = review_types(:final)
    get(:edit,
        :id => final.id)

    assert_equal(final.name, assigns(:review_type).name)
    
  end

  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update method
  # from the ReviewType Controller class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_update

    set_admin
    review_type      = ReviewType.find(review_types(:routing).id)
    review_type.name = 'Bogus'

    get(:update,
        :review_type => review_type.attributes)

    assert_equal('Update recorded',  flash['notice'])
    assert_redirected_to(:action => 'edit',
                         :id     => review_type.id)
    assert_equal('Bogus', review_type.name)
  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the ReviewType Controller class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_create

    set_admin
    assert_equal(6, ReviewType.find_all.size)

    new_review_type = {
      'active'     => '1',
      'required'   => '1',
      'sort_order' => '20',
      'name'       => 'Yankee',
    }

    post(:create,
         :new_review_type => new_review_type)

    assert_equal(7,              ReviewType.find_all.size)
    assert_equal("Yankee added", flash['notice'])
    assert_redirected_to :action => 'list'

    post(:create,
         :new_review_type => new_review_type)
    assert_equal(7,                           ReviewType.find_all.size)
    assert_equal("Sort order must be unique", flash['notice'])
    assert_redirected_to :action => 'add'

    new_review_type['sort_order'] = 4555
    post(:create,
         :new_review_type => new_review_type)
    assert_equal(7,
                 ReviewType.find_all.size)
    assert_equal("Name already exists in the database", flash['notice'])
    assert_redirected_to :action => 'add'

    new_review_type['sort_order'] = 45.55
    post(:create,
         :new_review_type => new_review_type)
    assert_equal(7,  ReviewType.find_all.size)
    assert_equal("Sort order - must be an integer greater than 0",  
                 flash['notice'])
    assert_redirected_to :action => 'add'

  end

end
