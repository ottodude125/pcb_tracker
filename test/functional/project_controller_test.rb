########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: project_controller_test.rb
#
# This file contains the functional tests for project_controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'project_controller'

# Re-raise errors caught by the controller.
class ProjectController; def rescue_action(e) raise e end; end

class ProjectControllerTest < Test::Unit::TestCase
  def setup
    @controller = ProjectController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end


  fixtures(:projects,
	   :users)


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

    assert_equal(15, assigns(:projects).size)
  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the test_edit method
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
  def test_edit
    
    # Try editing from an Admin account
    set_admin
    post(:edit,
         :id     => projects(:miata).id)

    assert_response 200
    assert_equal(projects(:miata).name, assigns(:project).name)

    assert_raise(ActiveRecord::RecordNotFound) {
      post(:edit, :id     => 1000000)
    }
  end


  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update method
  # from the Project Controller class
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

    project = Project.find(projects(:miata).id)
    project.name = 'Mazda'

    set_admin
    get(:update,
        :project => project.attributes)

    assert_equal('Project ' + project.name + ' was successfully updated.',
                 flash['notice'])
    assert_redirected_to(:action => 'edit',
                         :id     => project.id)
    assert_equal('Mazda', project.name)
  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the Project Controller class
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

    assert_equal(15,
		 Project.find_all.size)

    new_project = {
      'active' => '1',
      'name'   => 'Thunderbird'
    }

    set_admin
    post(:create,
	 :new_project => new_project)


    assert_equal(16,
		 Project.find_all.size)
    assert_equal("Project #{new_project['name']} added",
		 flash['notice'])
    assert_redirected_to(:action => 'list')
    
    post(:create,
	 :new_project => new_project)

    assert_equal(16,
		 Project.find_all.size)
    assert_equal("Name has already been taken",
		 flash['notice'])
    assert_redirected_to(:action => 'add')


    post(:create,
	 :new_project => {
	   'active' => '1', 
	   'name' => ''
	 })
    
    assert_equal(16,
		 Project.find_all.size)
    assert_equal("Name can't be blank",
		 flash['notice'])
    assert_redirected_to(:action => 'add')

  end


end
