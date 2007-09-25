########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_director_test.rb
#
# This file contains the unit tests for the audit model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class DesignDirectoryTest < Test::Unit::TestCase
  fixtures :design_directories

  def setup
    @design_directory = DesignDirectory.find(design_directories(:hw_design_bos).id)
  end

  def test_create

    assert_kind_of DesignDirectory, @design_directory

    hw_design_bos = design_directories(:hw_design_bos)
    assert_equal(hw_design_bos.id,     @design_directory.id)
    assert_equal(hw_design_bos.name,   @design_directory.name) 
    assert_equal(hw_design_bos.active, @design_directory.active)

  end

  def test_update

    @design_directory.name   = "Central Park"
    @design_directory.active = 0

    assert @design_directory.save
    @design_directory.reload

    assert_equal("Central Park", @design_directory.name)
    assert_equal(0,              @design_directory.active)

  end

  def test_destroy
    @design_directory.destroy
    assert_raise(ActiveRecord::RecordNotFound) { DesignDirectory.find(@design_directory.id) }
  end
  
  
  def test_get_active
    
    active_design_directories = DesignDirectory.get_active_design_directories
    
    assert(active_design_directories.size > 1)
    assert(active_design_directories.size < DesignDirectory.count)
    
    name = ''
    active_design_directories.each do |design_directory|
      assert(name < design_directory.name)
      name = design_directory.name
    end
    
  end

end
