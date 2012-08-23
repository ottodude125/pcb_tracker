########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: prefix_test.rb
#
# This file contains the unit tests for the prefix model
#
# Revision History:
#   $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ ) 

class PrefixsTest < ActiveSupport::TestCase



  ######################################################################
  #
  # setup
  #
  ######################################################################
  #
  def setup
    @prefix = Prefix.find(1)
  end

  ######################################################################
  #
  # test_access
  #
  ######################################################################
  #
  def test_access
  
    prefix_list = Prefix.find(:all)
    
    inactive_list = []
    prefix_list.each do |expected_prefix|
      inactive_list << expected_prefix if !expected_prefix.active?  
    end
    
    # Verify the list sizes.
    active_list = Prefix.get_active_prefixes
    assert_equal(prefix_list.size, (inactive_list.size + active_list.size))
    assert_equal(nil,              active_list.detect { |p| !p.active })
    
    # Verify the list is sorted by the pcb_mnemonic
    pcb_mnemonic = ''
    active_list.each do |prefix|
      assert(prefix.pcb_mnemonic > pcb_mnemonic)
      pcb_mnemonic = prefix.pcb_mnemonic
    end
    
    all_prefixes = Prefix.get_prefixes
    expected_prefixes = Prefix.find(:all, :order => 'pcb_mnemonic')
    assert_equal(expected_prefixes, all_prefixes)
          
    pcb_mnemonic = ''
    all_prefixes.each do |prefix|
      assert(prefix.pcb_mnemonic > pcb_mnemonic)
      pcb_mnemonic = prefix.pcb_mnemonic
    end
  
  end


  ######################################################################
  #
  # test_number_functions
  #
  ######################################################################
  #
  def test_number_functions
  
    av = prefixes(:av)
    
    assert_equal('959-021-b2', av.pcb_number('021', 'b', '2'))
    assert_equal('956-021-00', av.pcb_a_part_number('021', 'b', '2'))
  
  end
  
  
end
