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

require File.dirname(__FILE__) + '/../test_helper'

class ProjectTest < Test::Unit::TestCase
  fixtures :projects


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
  
    project_list = Project.find_all
    
    inactive_list = []
    project_list.each do |expected_project|
      inactive_list << expected_project if !expected_project.active?  
    end
    
    # Verify the list sizes.
    active_list = Project.get_all_active
    assert_equal(project_list.size, (inactive_list.size + active_list.size))
    assert_equal(nil,               active_list.detect { |p| !p.active })
    
    # Verify the list is sorted by the name
    name = ''
    active_list.each do |project|
      assert(project.name > name)
      name = project.name
    end

    name = 'zzz'
    Project.get_all_active('name DESC').each do |project|
      assert(project.name < name)
      name = project.name
    end
  
  end


end
