########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_test.rb
#
# This file contains the unit tests for the design model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class DesignTest < Test::Unit::TestCase
  fixtures(:designs,
           :users)

  def setup
    @design = Design.find(1)
  end

  ######################################################################
  #
  # test_people
  #
  # Description:
  # Validates the behaviour of the following methods.
  #
  #   designer()
  #   peer()
  #   input_gate()
  #
  ######################################################################
  #
  def test_people
  
    # Verify the behavior when the IDs are not set.
    new_design = Design.new
    assert_equal('Not Assigned', new_design.designer.name)
    assert_equal('Not Assigned', new_design.peer.name)
    assert_equal('Not Assigned', new_design.input_gate.name)
    
    # Verify the correct name when the designer_id is set.
    assert_equal('Robert Goldin', designs(:mx600a).designer.name)
    assert_equal('Scott Glover',  designs(:mx600a).peer.name)
    assert_equal('Cathy McLaren', designs(:mx600a).input_gate.name)
    
  end
  
  
  ######################################################################
  #
  # test_all_reviewers
  #
  # Description:
  # Validates the behaviour of the following methods.
  #
  #   all_reviewers()
  #
  ######################################################################
  #
  def test_all_reviewers
  
    expected_reviewers =
      [ users(:espo),      users(:heng_k),    users(:lee_s),
        users(:dave_m),    users(:tom_f),     users(:anthony_g),
        users(:cathy_m),   users(:john_g),    users(:matt_d),
        users(:art_d),     users(:dan_g),     users(:rich_a),
        users(:lisa_a),    users(:jim_l),     users(:eileen_c) ]

    assert_equal(expected_reviewers, designs(:mx234a).all_reviewers)
    
    sorted = true
    expected_reviewers =
      expected_reviewers.sort_by { |u| u.last_name }
    assert_equal(expected_reviewers, designs(:mx234a).all_reviewers(sorted))
    
  end
  
  
  ######################################################################
  #
  # test_get_associated_users
  #
  # Description:
  # Validates the behaviour of the following methods.
  #
  #   get_associated_users()
  #
  ######################################################################
  #
  def test_get_associated_users
  
    mx234a_users = designs(:mx234a).get_associated_users
    
    assert_equal(users(:bob_g),   mx234a_users[:designer])
    assert_equal(users(:scott_g), mx234a_users[:peer])
    assert_equal(users(:cathy_m), mx234a_users[:pcb_input])
    
    reviewers = mx234a_users[:reviewers].sort_by{ |u| u.last_name }
    expected_reviewers = [
      users(:rich_a),     users(:lisa_a),     users(:eileen_c),
      users(:art_d),      users(:matt_d),     users(:espo),
      users(:tom_f),      users(:anthony_g),  users(:john_g),
      users(:dan_g),      users(:jim_l),      users(:dave_m),
      users(:cathy_m),    users(:lee_s),      users(:heng_k)
    ]
    assert_equal(expected_reviewers, reviewers)

  end
  

  ######################################################################
  #
  # test_get_associated_users_by_role
  #
  # Description:
  # Validates the behaviour of the following methods.
  #
  #   get_associated_users_by_role()
  #
  ######################################################################
  #
  def test_get_associated_users_by_role
  
    mx234a_users = designs(:mx234a).get_associated_users_by_role
    expected_users = {
      :designer                      => users(:bob_g),
      :peer                          => users(:scott_g),
      :pcb_input                     => users(:cathy_m),
      'PCB_Mechanical'               => users(:john_g),
      'PCB Input Gate'               => users(:cathy_m),
      'DFM'                          => users(:heng_k),
      'SLM-Vendor'                   => users(:dan_g),
      'Operations Manager'           => users(:eileen_c),
      'PCB Design'                   => users(:jim_l),
      'HWENG'                        => users(:lee_s),
      'Planning'                     => users(:matt_d),
      'CE-DFT'                       => users(:espo),
      'Valor'                        => users(:lisa_a),
      'Mechanical'                   => users(:tom_f),
      'SLM BOM'                      => users(:art_d),
      'Mechanical-MFG'               => users(:anthony_g),
      'Library'                      => users(:dave_m),
      'TDE'                          => users(:rich_a),
      'Hardware Engineering Manager' => User.new(:first_name => 'Not', 
                                                 :last_name => 'Set'),
      'Program Manager'              => User.new(:first_name => 'Not', 
                                                 :last_name => 'Set')
    }
    
    assert_equal(expected_users.size,
                 mx234a_users.size)
    mx234a_users.each { |key, value|
      if expected_users[key]
        assert_equal(expected_users[key].name, value.name)
      end
    }
    
  end
  
  
  ######################################################################
  #
  # test_types
  #
  # Description:
  # Validates the behaviour of the following methods.
  #
  #   new?()
  #   date_code?()
  #   dot_rev?()
  #
  ######################################################################
  #
  def test_types 
  
    assert_equal(true,  designs(:mx234a).new?)
    assert_equal(false, designs(:mx234a).date_code?)
    assert_equal(false, designs(:mx234a).dot_rev?)
    
    assert_equal(false, designs(:la453a_eco1).new?)
    assert_equal(true,  designs(:la453a_eco1).date_code?)
    assert_equal(false, designs(:la453a_eco1).dot_rev?)
  
    assert_equal(false, designs(:la453a1).new?)
    assert_equal(false, designs(:la453a1).date_code?)
    assert_equal(true,  designs(:la453a1).dot_rev?)
  
  end
  

end
