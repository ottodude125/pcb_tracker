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
require File.expand_path( "../../test_helper", __FILE__ )
require 'project_controller'

# Re-raise errors caught by the controller.
class ProjectController; def rescue_action(e) raise e end; end

class ProjectControllerTest < ActionController::TestCase


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
    get :list, {}, rich_designer_session
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    get(:list, { :page => 1 }, cathy_admin_session)
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
    
    admin_session = cathy_admin_session
    
    # Try editing from an Admin account
    get(:edit, { :id => projects(:miata).id }, admin_session)
    assert_response 200
    assert_equal(projects(:miata).name, assigns(:project).name)

    assert_raise(ActiveRecord::RecordNotFound) do
      get(:edit, { :id => 1000000 }, admin_session)
    end
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

    project      = Project.find(projects(:miata).id)
    project.name = 'Mazda'

    post(:update, { :project => project.attributes }, cathy_admin_session)
    assert_equal('Project ' + project.name + ' was successfully updated.',
                 flash['notice'])
    assert_redirected_to(:action => 'edit', :id => project.id)
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

    admin_session = cathy_admin_session
    project_count = Project.count

    new_project = { 'active' => '1', 'name' => 'Thunderbird' }

    post(:create, {:new_project => new_project}, admin_session)
    project_count += 1
    assert_equal(project_count,	                         Project.count)
    assert_equal("Project #{new_project['name']} added", flash['notice'])
    assert_redirected_to(:action => 'list')
    
    post(:create, {:new_project => new_project}, admin_session)
    assert_equal(project_count,                 Project.count)
    #assert_equal("Name has already been taken", flash['notice'])
    assert_redirected_to(:action => 'add')


    post(:create,
         { :new_project => { 'active' => '1', 'name'   => '' } },
         admin_session)
    assert_equal(project_count,         Project.count)
    #assert_equal("Name can't be blank", flash['notice'])
    assert_redirected_to(:action => 'add')

  end


end
