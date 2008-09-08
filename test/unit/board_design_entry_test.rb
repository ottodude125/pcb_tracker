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
           :part_numbers,
           :platforms,
           :prefixes,
           :product_types,
           :projects,
           :revisions,
           :roles,
           :users


  def setup
    
    @av714b             = board_design_entries(:av714b)
    @la021c             = board_design_entries(:la021c)
    @mx008b4            = board_design_entries(:mx008b4)
    @mx008b4_ecoP123456 = board_design_entries(:mx008b4_ecoP123456)
    @mx234a             = board_design_entries(:mx234a)
    @mx234c             = board_design_entries(:mx234c)
    
    @cathy_m = users(:cathy_m)
    
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

    assert_equal('956-714-00',               bde_1.pcba_part_number)
    assert_equal('259-008-00',               board_design_entries(:mx008b4).pcba_part_number)
    assert_equal('259-008-00',               board_design_entries(:mx008b4_ecoP123456).pcba_part_number)
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

    bde = BoardDesignEntry.new
    assert_equal(BoardDesignEntry::NOT_SET, bde.originator)
    
    mx234c_entry = board_design_entries(:mx234c)
    mx234c_entry.state = 'ready_to_post'
    mx234c_entry.save
    
    processor_states = %w(originated ready_to_post submitted)
    processor_list       = BoardDesignEntry.get_entries_for_processor
    board_design_entries = BoardDesignEntry.find(:all)
    
    assert(board_design_entries.size > processor_list.size)
    processor_list.each { |bde| assert(processor_states.include?(bde.state)) }
    not_on_list = board_design_entries - processor_list
    not_on_list.each { |bde| assert(!processor_states.include?(bde.state)) }
    
    
    submitter_states = %w(originated submitted)
    assert_equal(0, BoardDesignEntry.get_user_entries(users(:scott_g)).size)

    johns_list = BoardDesignEntry.get_user_entries(users(:john_j))
    assert_equal(3, johns_list.size)
    johns_list.each { |bde| assert(submitter_states.include?(bde.state)) }
    

    assert_equal(3, BoardDesignEntry.submission_count)
    
  end
  

  ######################################################################
  def test_add_entry
    
    total_entries      = BoardDesignEntry.count
    total_part_numbers = PartNumber.count 
    
    pcb_pn      = '700-400-00'.split('-')
    pcba_pn     = '000-000-00'.split('-')
    part_number = PartNumber.new( :pcb_prefix       => pcb_pn[0],
                                  :pcb_number       => pcb_pn[1],
                                  :pcb_dash_number  => pcb_pn[2],
                                  :pcb_revision     => 'a',
                                  :pcba_prefix      => pcba_pn[0],
                                  :pcba_number      => pcba_pn[1],
                                  :pcba_dash_number => pcba_pn[2],
                                  :pcba_revision    => 'a')
               
    board_design_entry = BoardDesignEntry.add_entry(part_number, @cathy_m)
    assert(board_design_entry)
    total_entries      += 1
    total_part_numbers += 1
    assert_equal(total_entries,      BoardDesignEntry.count)
    assert_equal(total_part_numbers, PartNumber.count)
    
    part_number.reload
    assert_not_nil(part_number.id)
    assert_nil(part_number.error_message)
    
    
    pcb_pn      = '700-400-01'.split('-')
    pcba_pn     = '000-000-00'.split('-')
    part_number = PartNumber.new( :pcb_prefix       => pcb_pn[0],
                                  :pcb_number       => pcb_pn[1],
                                  :pcb_dash_number  => pcb_pn[2],
                                  :pcb_revision     => 'b',
                                  :pcba_prefix      => pcba_pn[0],
                                  :pcba_number      => pcba_pn[1],
                                  :pcba_dash_number => pcba_pn[2],
                                  :pcba_revision    => 'a')
               
    board_design_entry = BoardDesignEntry.add_entry(part_number, @cathy_m)
    assert(board_design_entry)
    total_entries      += 1
    total_part_numbers += 1
    assert_equal(total_entries,      BoardDesignEntry.count)
    assert_equal(total_part_numbers, PartNumber.count)
    
    part_number.reload
    assert_not_nil(part_number.id)
    assert_nil(part_number.error_message)
    
    
    pcb_pn      = '700-401-00'.split('-')
    pcba_pn     = '700-500-00'.split('-')
    part_number = PartNumber.new( :pcb_prefix       => pcb_pn[0],
                                  :pcb_number       => pcb_pn[1],
                                  :pcb_dash_number  => pcb_pn[2],
                                  :pcb_revision     => 'a',
                                  :pcba_prefix      => pcba_pn[0],
                                  :pcba_number      => pcba_pn[1],
                                  :pcba_dash_number => pcba_pn[2],
                                  :pcba_revision    => 'b')
               
    board_design_entry = BoardDesignEntry.add_entry(part_number, @cathy_m)
    assert(board_design_entry)
    total_entries      += 1
    total_part_numbers += 1
    assert_equal(total_entries,      BoardDesignEntry.count)
    assert_equal(total_part_numbers, PartNumber.count)
    
    part_number.reload
    assert_not_nil(part_number.id)
    assert_nil(part_number.error_message)
    

    pcb_pn      = '700-500-01'.split('-')
    pcba_pn     = '700-501-00'.split('-')
    part_number = PartNumber.new( :pcb_prefix       => pcb_pn[0],
                                  :pcb_number       => pcb_pn[1],
                                  :pcb_dash_number  => pcb_pn[2],
                                  :pcb_revision     => 'a',
                                  :pcba_prefix      => pcba_pn[0],
                                  :pcba_number      => pcba_pn[1],
                                  :pcba_dash_number => pcba_pn[2],
                                  :pcba_revision    => 'b')
               
    board_design_entry = BoardDesignEntry.add_entry(part_number, @cathy_m)
    assert(!board_design_entry)
    assert_equal(total_entries,      BoardDesignEntry.count)
    assert_equal(total_part_numbers, PartNumber.count)
    
    assert_nil(part_number.id)
    assert_equal("The supplied PCB Part Number already exists as a PCBA Part " +
                 "Number in the database - YOUR PART NUMBER WAS NOT CREATED",
                 part_number.error_message)
    

    pcb_pn      = '700-400-00'.split('-')
    pcba_pn     = '000-000-00'.split('-')
    part_number = PartNumber.new( :pcb_prefix       => pcb_pn[0],
                                  :pcb_number       => pcb_pn[1],
                                  :pcb_dash_number  => pcb_pn[2],
                                  :pcb_revision     => 'a',
                                  :pcba_prefix      => pcba_pn[0],
                                  :pcba_number      => pcba_pn[1],
                                  :pcba_dash_number => pcba_pn[2],
                                  :pcba_revision    => 'a')
               
    board_design_entry = BoardDesignEntry.add_entry(part_number, @cathy_m)
    assert(!board_design_entry)
    assert_equal(total_entries,      BoardDesignEntry.count)
    assert_equal(total_part_numbers, PartNumber.count)
    
    assert_nil(part_number.id)
    assert_equal("The supplied PCB Part Number already exists as a PCB Part " +
                 "Number in the database - YOUR PART NUMBER WAS NOT CREATED",
                 part_number.error_message)
    
    
    pcb_pn      = '700-600-01'.split('-')
    pcba_pn     = '700-400-00'.split('-')
    part_number = PartNumber.new( :pcb_prefix       => pcb_pn[0],
                                  :pcb_number       => pcb_pn[1],
                                  :pcb_dash_number  => pcb_pn[2],
                                  :pcb_revision     => 'a',
                                  :pcba_prefix      => pcba_pn[0],
                                  :pcba_number      => pcba_pn[1],
                                  :pcba_dash_number => pcba_pn[2],
                                  :pcba_revision    => 'a')
               
    board_design_entry = BoardDesignEntry.add_entry(part_number, @cathy_m)
    assert(!board_design_entry)
    assert_equal(total_entries,      BoardDesignEntry.count)
    assert_equal(total_part_numbers, PartNumber.count)
    
    assert_nil(part_number.id)
    assert_equal("The supplied PCBA Part Number already exists as a PCB Part " +
                 "Number in the database - YOUR PART NUMBER WAS NOT CREATED",
                 part_number.error_message)

    pcb_pn      = '700-600-01'.split('-')
    pcba_pn     = '700-400-40'.split('-')
    part_number = PartNumber.new( :pcb_prefix       => pcb_pn[0],
                                  :pcb_number       => pcb_pn[1],
                                  :pcb_dash_number  => pcb_pn[2],
                                  :pcb_revision     => 'a',
                                  :pcba_prefix      => pcba_pn[0],
                                  :pcba_number      => pcba_pn[1],
                                  :pcba_dash_number => pcba_pn[2],
                                  :pcba_revision    => 'd')
               
    board_design_entry = BoardDesignEntry.add_entry(part_number, @cathy_m)
    assert(!board_design_entry)
    assert_equal(total_entries,      BoardDesignEntry.count)
    assert_equal(total_part_numbers, PartNumber.count)
    
    assert_nil(part_number.id)
    assert_equal("The supplied PCBA Part Number already exists as a PCB Part " +
                 "Number in the database - YOUR PART NUMBER WAS NOT CREATED",
                 part_number.error_message)

  end

  
  ######################################################################
  def test_entry_type_methods
    
    # Test a board design entry that does not exist in the database.
    bde = BoardDesignEntry.new
    
    assert_equal('New',               bde.new_entry_type_name)
    assert_equal('Bare Board Change', bde.dot_rev_entry_type_name)

    assert(!bde.new_design?)
    assert(!bde.dot_rev_design?)
    assert(!bde.entry_type_set?)
    assert_equal('Entry Type Not Set', bde.entry_type_name)
    
    bde.set_entry_type_dot_rev
    assert(!bde.new_design?)
    assert(bde.dot_rev_design?)
    assert(bde.entry_type_set?)
    assert_equal('Bare Board Change', bde.entry_type_name)
    
    bde.set_entry_type_new
    assert(bde.new_design?)
    assert(!bde.dot_rev_design?)
    assert(bde.entry_type_set?)
    assert_equal('New', bde.entry_type_name)
    
    
    # Test a board design entry that already exists in the database.
    bde = BoardDesignEntry.find(board_design_entries(:av714b).id)
    
    assert(bde.new_design?)
    assert(!bde.dot_rev_design?)
    assert(bde.entry_type_set?)
    assert_equal('New', bde.entry_type_name)
    
    bde.set_entry_type_dot_rev
    bde.reload
    assert(!bde.new_design?)
    assert(bde.dot_rev_design?)
    assert(bde.entry_type_set?)
    assert_equal('Bare Board Change', bde.entry_type_name)
    
    bde.set_entry_type_new
    bde.reload
    assert(bde.new_design?)
    assert(!bde.dot_rev_design?)
    assert(bde.entry_type_set?)
    assert_equal('New', bde.entry_type_name)
    
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
  def test_new
   
    assert(@av714b.new?)
    assert(@av714b.part_number.new?)
    
    @av714b.part_number = PartNumber.initial_part_number
    assert(!@av714b.new?)
    assert(!@av714b.part_number.new?)

    @av714b.part_number_id = 0
    assert(@av714b.new?)

  end


  ######################################################################
  def test_design_name
   
    assert_equal('100-714-b0 / 150-714-00', @av714b.design_name)
    assert_equal('252-008-b4 / 259-008-00', @mx008b4.design_name)
    
    @av714b.part_number_id  = 0
    @mx008b4.part_number_id = 0
   
    assert_equal('av714b (959-714-b0)',  @av714b.design_name)
    assert_equal('mx008b4 (252-008-b4)', @mx008b4.design_name)

  end


  ######################################################################
  def test_role_methods
   
    assert(@av714b.all_roles_assigned?([]))

  end


  ######################################################################
  def test_load_design_team

    BoardDesignEntryUser.destroy_all
    
    bde = BoardDesignEntry.find(board_design_entries(:av714b).id)
    assert_equal(0, bde.board_design_entry_users.size)
    assert_equal(0, bde.managers.size)
    assert_equal(0, bde.reviewers.size)

    bde.load_design_team

    assert_equal(1, bde.managers.size)
    assert_equal(8, bde.reviewers.size)
    assert_equal(9, bde.board_design_entry_users.size)
    assert_equal(9, BoardDesignEntryUser.count)
    
    default_user_list = { 'PCB Design'          => 'Light',
                          'Compliance - EMC'    => 'Bechard',
                          'Compliance - Safety' => 'Pallotta',
                          'Library'             => 'Ohara',
                          'PCB Input Gate'      => 'McLaren',
                          'PCB Mechanical'      => 'Tucker',
                          'SLM BOM'             => 'Seip',
                          'SLM-Vendor'          => 'Gough',
                          'Valor'               => 'McLaren'}
    default_users = {}
    
    default_user_list.each { |role_name, user_last_name|  
      role = Role.find_by_name(role_name)
      user = User.find_by_last_name(user_last_name)
      default_users[role.id] = user.id  
    }
    
    bde.board_design_entry_users.each do |bde_user|
      assert_equal(bde.id, bde_user.board_design_entry_id)
      if default_users[bde_user.role_id]
        assert_equal(default_users[bde_user.role_id], bde_user.user_id)
      else
        assert_equal(0, bde_user.user_id)
      end
    end
  

    bde = BoardDesignEntry.find(board_design_entries(:mx234a).id)
    bde.board_design_entry_users.destroy_all
    bde.reload
    assert_equal(0, bde.board_design_entry_users.size)
    assert_equal(9, BoardDesignEntryUser.count)
    assert_equal(0, bde.managers.size)
    assert_equal(0, bde.reviewers.size)

    bde.load_design_team

    assert_equal(1,  bde.managers.size)
    assert_equal(8,  bde.reviewers.size)
    assert_equal(9,  bde.board_design_entry_users.size)
    assert_equal(18, BoardDesignEntryUser.count)
    
    bde.board_design_entry_users.each do |bde_user|
      assert_equal(bde.id, bde_user.board_design_entry_id)
      if default_users[bde_user.role_id]
        assert_equal(default_users[bde_user.role_id], bde_user.user_id)
      else
        assert_equal(0, bde_user.user_id)
      end
    end
  
  end
  
  
end
