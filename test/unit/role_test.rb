########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: role_test.rb
#
# This file contains the unit tests for the role model
#
# Revision History:
#   $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ ) 


class RolesTest < ActiveSupport::TestCase

  def setup
    @role          = roles(:admin)
    @designer_role = roles(:designer)
  end


  ######################################################################
  def test_create

    assert_kind_of Role,  @role

    admin = roles(:admin)
    assert_equal(admin.id,     @role.id)
    assert_equal(admin.name,   @role.name)
    assert_equal(admin.active, @role.active)

  end


  ######################################################################
  def test_update
    
    @role.name   = "Administrator"
    @role.active = 0

    assert @role.save
    @role.reload

    assert_equal("Administrator", @role.name)
    assert_equal(0,               @role.active)

  end


  ######################################################################
  def test_destroy
    @role.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Role.find(@role.id) }
  end
  
  
  ######################################################################
  def test_users

    all_designers = Role.find_by_name('Designer').users
    assert_equal(6, all_designers.size)
    all_designers.delete_if  { |u| !u.active? }
    assert_equal(5, all_designers.size)
    all_designers = all_designers.sort_by { |u| u.last_name }
    
    active_designers = Role.find_by_name('Designer').active_users
    assert_equal(all_designers, active_designers)
    
  end
  
  
  ######################################################################
  def test_include
  
    role = Role.new
    
    assert(!role.include?('Date Code'))
    assert(!role.include?('date_code'))
    assert(!role.include?('Dot Rev'))
    assert(!role.include?('dot_rev'))
    assert(!role.include?('New'))
    assert(!role.include?('new'))
    
    role.new_design_type       = 1
    role.date_code_design_type = 1
    role.dot_rev_design_type   = 1
  
    assert(role.include?('Date Code'))
    assert(role.include?('date_code'))
    assert(role.include?('Dot Rev'))
    assert(role.include?('dot_rev'))
    assert(role.include?('New'))
    assert(role.include?('new'))
    
  end


  ######################################################################
  def test_find_all_active
  
    all_roles = Role.find(:all, :order => 'display_name')
    
    # Set the first 5 roles to inactive
    0.upto(4) do |i|
      all_roles[i].active = 0
      all_roles[i].save
    end
    
    active_roles = Role.find_all_active
    
    assert(all_roles.size > active_roles.size)
    active_roles_list = all_roles
    active_roles_list.delete_if { |r| !r.active? }
    assert_equal(active_roles_list.size, active_roles.size)
    
    expected_role_name = ['EE Manager',               'Hardware Engineer (EE)',
                          'HCL Manager',              'Mechanical Engineer',
                          'Mechanical Mfg Engineer',  'New Product Planner',
                          'Operations Manager',       'PCB Admin',
                          'PCB Design Input Gate',    'PCB Design Management',
                          'PCB Designer',             'PCB Mechanical Engineer',
                          'Program Manager',          'SLM BOM',
                          'SLM Vendor',               'TDE Engineer',
                          'Tracker Admin',            'Tracker PCB Management',
                          'Valor']

    active_roles.each_with_index do |role, i| 
      assert(role.active?)
      assert_equal(active_roles_list[i].display_name, role.display_name)
    end
    
    all_roles.delete_if { |r| !r.active? }
    
    assert_equal(all_roles.size, active_roles.size)
    assert_equal(all_roles, active_roles)
    
  end


  ######################################################################
  def test_roles

    expected_review_roles = [ roles(:hweng),    roles(:compliance_emc),
                              roles(:ce_dft),   roles(:dfm),
                              roles(:tde),      roles(:mechanical),
                              roles(:valor),    roles(:mechanical_manufacturing),
                              roles(:planning), roles(:pcb_input_gate),
                              roles(:library),  roles(:pcb_mechanical),
                              roles(:slm_bom),  roles(:slm_vendor),
                              roles(:compliance_safety), roles(:ecn_manager)].sort_by { |r| r.display_name }

    review_roles = Role.get_review_roles.sort_by { |r| r.display_name }
    assert_equal(expected_review_roles.size, review_roles.size)
    review_roles.each_with_index do |role, i|
      assert_equal(expected_review_roles[i], role)
    end

    expected_defaulted_review_roles = [ roles(:compliance_emc),
                                        roles(:valor),
                                        roles(:pcb_input_gate),
                                        roles(:library),  
                                        roles(:pcb_mechanical),
                                        roles(:compliance_safety),  
                                        roles(:slm_vendor),
                                        roles(:slm_bom),
                                        roles(:ecn_manager)].sort_by { |r| r.display_name }

    defaulted_review_roles = Role.get_defaulted_reviewer_roles
    assert_equal(expected_defaulted_review_roles.size,
                 defaulted_review_roles.size)
    defaulted_review_roles.each_with_index do |role, i|
      assert_equal(expected_defaulted_review_roles[i], role)
    end
    
    expected_open_review_roles = [ roles(:dfm),       roles(:ce_dft),
                                   roles(:hweng),     roles(:mechanical), 
                                   roles(:mechanical_manufacturing),
                                   roles(:tde),
                                   roles(:planning) ].sort_by { |r| r.display_name }

    # get_open_reviewer_roles was modified to be the same as get_review_roles
    # the original test is comment out with "## "
    # the test from get_review_roles is repeated here but on the results of 
    #     get_open_reviewer_roles
    open_review_roles = Role.get_open_reviewer_roles.sort_by { |r| r.display_name }

    ## assert_equal(expected_open_review_roles.size, open_review_roles.size)
    ## open_review_roles.each_with_index do |role, i|
    ##   assert_equal(expected_open_review_roles[i], role)
    ## end
    assert_equal(expected_review_roles.size,
                 open_review_roles.size)
    expected_review_roles.each_with_index do |role, i|
      assert_equal(expected_review_roles[i], role)
    end
    
    expected_manager_review_roles = [ roles(:hweng_manager),
                                      roles(:pcb_design),
                                      roles(:operations_manager),
                                      roles(:program_manager) ].sort_by { |r| r.display_name }

    manager_review_roles = Role.get_manager_review_roles
    assert_equal(expected_manager_review_roles.size, manager_review_roles.size)
    manager_review_roles.each_with_index do |role, i|
      assert_equal(expected_manager_review_roles[i], role)
    end
    
    expected_defaulted_manager_review_roles = [ roles(:pcb_design) ].sort_by { |r| r.display_name }

    defaulted_manager_review_roles = Role.get_defaulted_manager_reviewer_roles
    assert_equal(expected_defaulted_manager_review_roles.size,
                 defaulted_manager_review_roles.size)
    defaulted_manager_review_roles.each_with_index do |role, i|
      assert_equal(expected_defaulted_manager_review_roles[i], role)
    end

    
    expected_open_manager_review_roles = [ roles(:hweng_manager),
                                           roles(:operations_manager),
                                           roles(:program_manager) ].sort_by { |r| r.display_name }

    open_manager_review_roles = Role.get_open_manager_reviewer_roles
    assert_equal(expected_open_manager_review_roles.size,
                 open_manager_review_roles.size)
    open_manager_review_roles.each_with_index do |role, i|
      assert_equal(expected_open_manager_review_roles[i], role)
    end
    
  end


  ######################################################################
  def test_designer_accessors
  
    all_designers    = Role.find(:first, :conditions => "name='Designer'").users
    active_designers = Role.active_designers
    lcr_designers    = Role.lcr_designers
    
    assert(active_designers.size > lcr_designers.size)
    
    # Remove all of the non-employee designers from the original list, 
    # all _designers, and verify that the remaining list matches the one
    # returned by lcr_designers()
    active_designers.delete_if { |r| r.employee? }
    assert_equal(active_designers, lcr_designers)
    
    active_designers   = Role.active_designers
    inactive_designers = all_designers - active_designers

    inactive_designers.each do |designer|
      assert(!designer.active?)
      assert(designer.roles.include?(@designer_role))
    end

    active_designers.each do |designer|
      assert(designer.active?)
      assert(designer.roles.include?(@designer_role))
    end

  end


end
