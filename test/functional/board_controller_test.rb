########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: board_controller_test.rb
#
# This file contains the functional tests for the board controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'board_controller'

# Re-raise errors caught by the controller.
class BoardController; def rescue_action(e) raise e end; end

class BoardControllerTest < Test::Unit::TestCase
  def setup
    @controller = BoardController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:board_reviewers,
           :boards,
           :platforms,
           :prefixes,
           :projects,
           :users)


  def test_1_id
    print ("\n*** Board Controller Test\n")
    print ("*** $Id$\n")
  end


  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the Project class
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

    # Try editing from a non-Admin account.
    # VERIFY: The user is redirected.
    set_non_admin
    post :list

    assert_redirected_to(:controller => 'tracker',
		                  	 :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    set_admin
    post(:list,
	       :page => 1)

    assert_equal(Board.find_all.size, assigns(:boards).size)
  end


  ######################################################################
  #
  # test_add
  #
  # Description:
  # This method does the functional testing of the add method
  # from the Board class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_add

    set_admin
    post :add

    assert_equal(5,  assigns(:platforms).size)
    assert_equal(14, assigns(:projects).size)
  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the edit method
  # from the Board class
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
    post(:edit, :id => boards(:la453).id)
	 
    assert_equal(5,  assigns(:platforms).size)
    assert_equal(14, assigns(:projects).size)
#    assert_equal(@la453.id, @board.id)

  end

  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update method
  # from the Board Controller class
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

    board = Board.find(boards(:la454).id)
    board.prefix_id = prefixes(:la).id

    fab_house_selections = {
      '1' => '0',
      '2' => '1',
      '3' => '0',
      '4' => '1',
      '5' => '0',
      '6' => '1',
      '7' => '0',
      '8' => '1'}

    set_admin
    get(:update,
        :board => board.attributes,
        :board_reviewers => {'8' => '6001', '5' => '6000'},
        :fab_house => fab_house_selections)

    assert_equal('Board was successfully updated.', flash['notice'])
    assert_redirected_to(:action => 'edit',
                         :id     => board.id)
    assert_equal(prefixes(:la).id, board.prefix_id)
  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the Board class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # To Do: Test for duplicate board entry.
  #
  ######################################################################
  #
  def test_create

    assert_equal(4, Board.find_all.size)

    new_board = { 'active'      => '1',
                  'prefix_id'   => prefixes(:xx).id,
                  'number'      => '666',
                  'platform_id' => platforms(:j750).id,
                  'project_id'  => ''
    }

    set_admin
    post(:create,
         :board => new_board,
         :board_reviewers => {'8' => '116', '5' => '1331'})

    assert_equal(4, Board.find_all.size)
    assert_equal("Project can't be blank", flash['notice'])
    assert_redirected_to :action => 'add'

    new_board = {
      'active'      => '1',
      'prefix_id'   => prefixes(:xx).id,
      'number'      => '666',
      'platform_id' => '',
      'project_id'  => projects(:viking).id
    }

    post(:create,
         :board => new_board,
         :board_reviewers => {'8' => '116', '5' => '1331'})

    assert_equal(4, Board.find_all.size)
    assert_equal("Platform can't be blank", flash['notice'])
    assert_redirected_to :action => 'add'

    new_board = {
      'active'      => '1',
      'prefix_id'   => prefixes(:xx).id,
      'number'      => '',
      'platform_id' => platforms(:j750).id,
      'project_id'  => projects(:viking).id
    }

    post(:create,
         :board => new_board,
         :board_reviewers => {'8' => '116', '5' => '1331'})

    assert_equal(4, Board.find_all.size)
    assert_equal("Number can't be blank", flash['notice'])
    assert_redirected_to :action => 'add'

    new_board = {
      'active'      => '1',
      'prefix_id'   => '',
      'number'      => '666',
      'platform_id' => platforms(:j750).id,
      'project_id'  => projects(:viking).id
    }

    post(:create,
         :board => new_board,
         :board_reviewers => {'8' => '116', '5' => '1331'})

    assert_equal(4, Board.find_all.size)
    assert_equal('Prefix can not be blank', flash['notice'])
    assert_redirected_to :action => 'add'

    new_board = {
      'active'      => '1',
      'prefix_id'   => prefixes(:xx).id,
      'number'      => '666',
      'platform_id' => platforms(:j750).id,
      'project_id'  => projects(:viking).id
    }

    fab_house_selections = {
      '1' => '0',
      '2' => '1',
      '3' => '0',
      '4' => '1',
      '5' => '0',
      '6' => '1',
      '7' => '0',
      '8' => '1'}

    set_admin
    post(:create,
         :board => new_board,
         :board_reviewers => {'8' => '116', '5' => '1331'},
         :fab_house => fab_house_selections)

    assert_equal(5, Board.find_all.size)
    assert_equal('Board was successfully created', flash['notice'])
    assert_redirected_to :action => 'list'

    post(:create,
         :board => new_board,
         :board_reviewers => {'8' => '116', '5' => '1331'})
    assert_equal(5, Board.find_all.size)
    assert_equal("Name for board already exists", flash['notice'])
    assert_redirected_to :action => 'add'

    board_bad_number = new_board.dup
    board_bad_number['number'] = 'dog'
    post(:create,
         :board => board_bad_number,
         :board_reviewers => {'8' => '116', '5' => '1331'})

    assert_equal(5, Board.find_all.size)
    assert_equal("Number is not a number", flash['notice'])
    assert_redirected_to :action => 'add'

  end


  ######################################################################
  #
  # test_filtered_list
  #
  # Description:
  # This method does the functional testing of the filtered_list method
  #
  ######################################################################
  #
  def test_filtered_list
    print '?'
  end
  
  
  ######################################################################
  #
  # test_show_boards
  #
  # Description:
  # This method does the functional testing of the show_boards method
  #
  ######################################################################
  #
  def test_show_boards
    print '?'
  end
  
  
  ######################################################################
  #
  # test_design_information
  #
  # Description:
  # This method does the functional testing of the design_information
  # method
  #
  ######################################################################
  #
  def test_design_information
    print '?'
  end
  
  
end
