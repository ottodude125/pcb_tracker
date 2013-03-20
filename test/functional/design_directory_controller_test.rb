########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_directory_controller_test.rb
#
# This file contains the functional tests for the design directory
# controller
#
# $Id$
#
########################################################################
#
require File.expand_path( "../../test_helper", __FILE__ )
require 'design_directory_controller'

# Re-raise errors caught by the controller.
class DesignDirectoryController; def rescue_action(e) raise e end; end

class DesignDirectoryControllerTest < ActionController::TestCase
  
  def setup
    @controller = DesignDirectoryController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end


  fixtures(:board_design_entries,
           :design_directories,
           :roles,
           :roles_users,
           :users)


  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the design_directory class
  #
  ######################################################################
  #
  def test_list

    # Try editing from a non-Admin account.
    # VERIFY: The user is redirected.
    get :list, {}, rich_designer_session
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The platform list data is retrieved
    post(:list, { :page => 1 }, cathy_admin_session)
    assert_equal(3, assigns(:design_directories).size)

  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the edit method
  # from the Platform class
  #
  ######################################################################
  #
  def test_edit
    
    # Try editing from an Admin account
    admin_session = cathy_admin_session
    
    post(:edit,
         { :id => design_directories(:hw_design_ah).id },
         admin_session)
    assert_response 200
    assert_equal(design_directories(:hw_design_ah).name, 
                 assigns(:design_directory).name)

    assert_raise(ActiveRecord::RecordNotFound) {
      post( :edit, {:id => 1000000 }, admin_session)
    }

  end


  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update method
  # from the Platform Controller class
  #
  ######################################################################
  #
  def test_update

    design_directory = DesignDirectory.find(design_directories(:hw_design_bos).id)
    design_directory.name = 'Yugo'

    get(:update,
        { :design_directory => design_directory.attributes }, 
        cathy_admin_session)
    assert_equal('Design Directory was successfully updated.', flash['notice'])
    assert_redirected_to(:action => 'edit', :id => design_directory.id)
    
    design_directory.reload
    assert_equal('Yugo', design_directory.name)
  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the Platform Controller class
  #
  ######################################################################
  #
  def test_create

    # Verify that a design directory can be added.  The number of 
    # design directories will increase by one.
    design_directory_count = DesignDirectory.count
    assert_equal(2, DesignDirectory.find_all_by_active(1).size)

    new_design_directory = { 'active' => '1', 'name'   => 'Thunderbird' }

    admin_session = cathy_admin_session
    
    post(:create, { :new_design_directory => new_design_directory }, admin_session)
    design_directory_count += 1
    assert_equal(design_directory_count, DesignDirectory.count)
    assert_equal(3,                      DesignDirectory.find_all_by_active(1).size)
    assert_equal("Design Directory #{new_design_directory['name']} added", 
                 flash['notice'])
    assert_redirected_to(:action => 'list')
    
    # Try to add a second design directory with the same name.
    # It should not get added.
    post(:create, { :new_design_directory => new_design_directory }, admin_session)
    assert_equal(design_directory_count, DesignDirectory.count)
    assert_equal(3,                      DesignDirectory.find_all_by_active(1).size)
    #assert_equal("Name has already been taken", flash['notice'])
    assert_redirected_to(:action => 'add')


    # Try to add a design directroy withhout a name.
    # It should not get added.
    post(:create,
         { :new_design_directory => { 'active' => '1', 'name' => '' } },
         admin_session)
    assert_equal(design_directory_count, DesignDirectory.count)
    assert_equal(3,                      DesignDirectory.find_all_by_active(1).size)
    #assert_equal("Name can't be blank", flash['notice'])
    assert_redirected_to(:action => 'add')

  end


end
