########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: board_design_entry_test.rb
#
# This file contains the unit tests for the board design entry model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class BoardDesignEntryTest < Test::Unit::TestCase
  fixtures :board_design_entries,
           :board_design_entry_users,
           :design_directories,
           :divisions,
           :incoming_directories,
           :locations,
           :platforms,
           :prefixes,
           :product_types,
           :projects,
           :revisions,
           :roles,
           :users


  ######################################################################
  def test_design_name_methods

    bde = board_design_entries(:av714b)
    assert_equal('av714b', bde.design_name)
    assert_equal('av714',  bde.design)
    
    bde = board_design_entries(:mx008b4)
    assert_equal('mx008b4', bde.design_name)
    assert_equal('mx008',   bde.design)
    
    bde = board_design_entries(:mx008b4_ecoP123456)
    assert_equal('mx008b4_ecoP123456', bde.design_name)
    assert_equal('mx008'             , bde.design)
    
  end

  ######################################################################
  def test_accessors

    bde_1 = BoardDesignEntry.find(board_design_entries(:av714b).id)
    bde_2 = BoardDesignEntry.new

    assert_equal('North Reading',            bde_1.location)
    assert_equal(BoardDesignEntry::NOT_SET,  bde_2.location)

    assert_equal('STD',                      bde_1.division)
    assert_equal(BoardDesignEntry::NOT_SET,  bde_2.division)

    assert_equal('Catalyst',                 bde_1.platform_name)
    assert_equal(BoardDesignEntry::NOT_SET,  bde_2.platform_name)

    assert_equal('DC90',                     bde_1.project_name)
    assert_equal(BoardDesignEntry::NOT_SET,  bde_2.project_name)
    
    assert_equal('b',                        bde_1.revision_name)
    assert_equal(BoardDesignEntry::NOT_SET,  bde_2.revision_name)
    
    assert_equal('P1 Eng Board (Part to be used on Production Board)',
                 bde_1.product_type_name)
    assert_equal(BoardDesignEntry::NOT_SET,  bde_2.product_type_name)

    assert_equal('/hwnet/hw_design_bos',     bde_1.design_directory_name)
    assert_equal(BoardDesignEntry::NOT_SET,  bde_2.design_directory_name)

    assert_equal('/hwnet/board_ah/incoming', bde_1.incoming_directory_name)
    assert_equal(BoardDesignEntry::NOT_SET,  bde_2.incoming_directory_name)

    assert_equal('959-714-b0',               bde_1.pcb_number)
    assert_equal('252-008-b4',               board_design_entries(:mx008b4).pcb_number)
    assert_equal('252-008-b4',               board_design_entries(:mx008b4_ecoP123456).pcb_number)
    assert_equal(BoardDesignEntry::NOT_SET,  bde_2.pcb_number)

    assert_equal('956-714-10',               bde_1.pcba_part_number)
    assert_equal('259-008-10',               board_design_entries(:mx008b4).pcba_part_number)
    assert_equal('259-008-10',               board_design_entries(:mx008b4_ecoP123456).pcba_part_number)
    assert_equal(BoardDesignEntry::NOT_SET,  bde_2.pcba_part_number)
    
    av714b = board_design_entries(:av714b)
    av714b.originated
    av714b.reload
    
    assert_equal(true,  av714b.originated?)
    assert_equal(false, av714b.submitted?)
    assert_equal(false, av714b.ready_to_post?)
    assert_equal(false, av714b.complete?)
    assert_equal(true,  av714b.modifiable?)

    av714b.submitted
    av714b.reload
    assert_equal(false, av714b.originated?)
    assert_equal(true,  av714b.submitted?)
    assert_equal(false, av714b.ready_to_post?)
    assert_equal(false, av714b.complete?)
    assert_equal(true,  av714b.modifiable?)

    av714b.ready_to_post
    av714b.reload
    assert_equal(false, av714b.originated?)
    assert_equal(false, av714b.submitted?)
    assert_equal(true,  av714b.ready_to_post?)
    assert_equal(false, av714b.complete?)
    assert_equal(false, av714b.modifiable?)

    av714b.complete
    av714b.reload
    assert_equal(false, av714b.originated?)
    assert_equal(false, av714b.submitted?)
    assert_equal(false, av714b.ready_to_post?)
    assert_equal(true,  av714b.complete?)
    assert_equal(false, av714b.modifiable?)
    
    assert_equal('Ben Bina', av714b.originator)
    av714b.originator_id = 0
    assert_equal(BoardDesignEntry::NOT_SET, av714b.originator)
    
  end
  
  
  ######################################################################
  def test_validation
  
    bde = BoardDesignEntry.new(:number => 'OOO')
    assert_equal(false, bde.valid_number?)
    
    bde.number = '123'
    assert_equal(true, bde.valid_number?)
    
    bde.number = '23'
    assert_equal(false, bde.valid_number?)
    
    bde.number = ''
    assert_equal(false, bde.valid_number?)
  
  end
  

  ######################################################################
  def test_load_design_team

    bde = BoardDesignEntry.find(board_design_entries(:av714b).id)
    assert_equal(0, bde.board_design_entry_users.size)
    assert_equal(2, BoardDesignEntryUser.count)
    assert_equal(0, bde.managers.size)
    assert_equal(0, bde.reviewers.size)

    bde.load_design_team

    assert_equal(1,  bde.managers.size)
    assert_equal(7,  bde.reviewers.size)
    assert_equal(8,  bde.board_design_entry_users.size)
    assert_equal(10, BoardDesignEntryUser.count)
    
    default_user_list = { 'PCB Design'          => 'Light',
                          'Compliance - EMC'    => 'Bechard',
                          'Compliance - Safety' => 'Pallotta',
                          'Library'             => 'Ohara',
                          'PCB Input Gate'      => 'Kasting',
                          'PCB Mechanical'      => 'Khoras',
                          'SLM BOM'             => 'Seip',
                          'SLM-Vendor'          => 'Gough' }
    default_users = {}
    
    default_user_list.each { |role_name, user_last_name|  
      role = Role.find_by_name(role_name)
      user = User.find_by_last_name(user_last_name)
      default_users[role.id] = user.id  
    }
    
    for bde_user in bde.board_design_entry_users
      assert_equal(bde.id, bde_user.board_design_entry_id)
      if default_users[bde_user.role_id]
        assert_equal(default_users[bde_user.role_id], bde_user.user_id)
      else
        assert_equal(0, bde_user.user_id)
      end
    end
  
    bde = BoardDesignEntry.find(board_design_entries(:mx234a).id)
    assert_equal(0,  bde.board_design_entry_users.size)
    assert_equal(10, BoardDesignEntryUser.count)
    assert_equal(0, bde.managers.size)
    assert_equal(0, bde.reviewers.size)

    bde.load_design_team

    assert_equal(1, bde.managers.size)
    assert_equal(7, bde.reviewers.size)
    assert_equal( 8, bde.board_design_entry_users.size)
    assert_equal(18, BoardDesignEntryUser.count)
    
    default_user_list = { 'PCB Design'          => 'Light',
                          'Compliance - EMC'    => 'Bechard',
                          'Compliance - Safety' => 'Pallotta',
                          'Library'             => 'Ohara',
                          'PCB Input Gate'      => 'Kasting',
                          'PCB Mechanical'      => 'Khoras',
                          'SLM BOM'             => 'Seip',
                          'SLM-Vendor'          => 'Gough' }
    default_users = {}
    
    default_user_list.each { |role_name, user_last_name|  
      role = Role.find_by_name(role_name)
      user = User.find_by_last_name(user_last_name)
      default_users[role.id] = user.id  
    }
    
    for bde_user in bde.board_design_entry_users
      assert_equal(bde.id, bde_user.board_design_entry_id)
      if default_users[bde_user.role_id]
        assert_equal(default_users[bde_user.role_id], bde_user.user_id)
      else
        assert_equal(0, bde_user.user_id)
      end
    end
  
  end
  
  
end
