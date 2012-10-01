########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: project_test.rb
#
# This file contains the unit tests for the project model
#
# Revision History:
#   $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ ) 

class ProjectsTest < ActiveSupport::TestCase


  ######################################################################
  #
  # setup
  #
  ######################################################################
  #
  def setup
    @project = Project.find(projects(:bbac).id)
  end


  ######################################################################
  #
  # test_create
  #
  ######################################################################
  #
  def test_create

    assert_kind_of Project,  @project

    bbac = projects(:bbac)
    assert_equal(bbac.id,     @project.id)
    assert_equal(bbac.name,   @project.name)
    assert_equal(bbac.active, @project.active)
 
  end


  ######################################################################
  #
  # test_update
  #
  ######################################################################
  #
  def test_update
    
    @project.name   = "Zinc"
    @project.active = 0

    assert @project.save
    @project.reload

    assert_equal("Zinc", @project.name)
    assert_equal(0,      @project.active)

  end


  ######################################################################
  #
  # test_destroy
  #
  ######################################################################
  #
  def test_destroy
    @project.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Project.find(@project.id) }
  end


  ######################################################################
  #
  # test_access
  #
  ######################################################################
  #
  def test_access
  
    project_list = Project.get_projects
    
    inactive_list = []
    project_list.each do |expected_project|
      inactive_list << expected_project if !expected_project.active?  
    end
    
    # Verify the list sizes.
    active_list = Project.get_active_projects
    assert_equal(project_list.size, (inactive_list.size + active_list.size))
    assert_equal(nil,               active_list.detect { |p| !p.active })
    
    # Verify the list is sorted by the name
    name = ''
    active_list.each do |project|
      assert(project.name > name)
      name = project.name
    end

  end


  ######################################################################
  #
  # test_access
  #
  ######################################################################
  #
  def test_get_active
    
    active_projects = Project.get_active_projects
    
    assert(active_projects.size > 1)
    assert(active_projects.size < Project.count)
    
    name = ''
    active_projects.each do |project|
      assert(name < project.name)
      name = project.name
    end
    
  end


end
