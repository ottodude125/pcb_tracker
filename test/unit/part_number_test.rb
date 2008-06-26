########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: part_number_test.rb
#
# This file contains the unit tests for the part number model
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'

class PartNumberTest < Test::Unit::TestCase
  
  fixtures :board_design_entries,
           :designs,
           :part_numbers

  def setup
    @msg_format_error = 'The correct format for a part number is "ddd-ddd-aa" '+
                        '<br /> Where: "ddd" is a 3 digit number and "aa"' +
                        ' is 2 alpha-numeric characters.'
    @msg_pcb_pcba_exists  = "The supplied PCB and PCBA Part Number is " +
                            "already in the database"
    @msg_pcba_exists_pcba = "The supplied PCBA Part Number already exists as a" +
                            " PCBA Part Number in the database " +
                            "- YOUR PART NUMBER WAS NOT CREATED"
    @msg_pcba_exists_pcb  = "The supplied PCBA Part Number already exists as a" +
                            " PCB Part Number in the database " +
                            "- YOUR PART NUMBER WAS NOT CREATED"
    @msg_pcb_exists_pcba  = "The supplied PCB Part Number already exists as a" +
                            " PCBA Part Number in the database " +
                            "- YOUR PART NUMBER WAS NOT CREATED"
    @msg_pcb_exists_pcb   = "The supplied PCB Part Number already exists as a " +
                            "PCB Part Number in the database - YOUR PART NUMBER" +
                            " WAS NOT CREATED"
  end
  
  
  ######################################################################
  #
  # Validates the following:  exists?
  #                           valid_pcb_dash_number?
  #                           valid_pcb_number?
  #                           valid_pcb_part_number?
  #                           valid_pcb_prefix?
  #                           valid_pcba_dash_number?
  #                           valid_pcba_number?
  #                           valid_pcba_part_number?
  #                           valid_pcba_prefix?
  #
  ######################################################################
  def test_validation
    
    # Valid? - Yes
    pn = PartNumber.initial_part_number
    pcb_pn  = '600-123-a0'.split('-')
    pcba_pn = '500-120-00'.split('-')
    pn.pcb_prefix       = pcb_pn[0]
    pn.pcb_number       = pcb_pn[1]
    pn.pcb_dash_number  = pcb_pn[2]
    pn.pcb_revision     = 'a'
    pn.pcba_prefix      = pcba_pn[0]
    pn.pcba_number      = pcba_pn[1]
    pn.pcba_dash_number = pcba_pn[2]
    pn.pcba_revision    = 'a'
                         
    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcba_number?)
    assert( pn.valid_pcba_prefix?)
    assert( pn.valid_pcba_dash_number?)
    assert( pn.valid_pcb_part_number?)
    assert( pn.valid_pcba_part_number?)
    assert( pn.valid_components?('new'=='new'))
    assert(!pn.error_message)
    
    # Valid? - No - PCB, PCBA part numbers are not unique.
    pcba_pn = '600-123-00'.split('-')
    pn.pcba_prefix      = pcba_pn[0]
    pn.pcba_number      = pcba_pn[1]
    pn.pcba_dash_number = pcba_pn[2]
    pn.pcba_revision    = 'b'
                         
    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcba_number?)
    assert( pn.valid_pcba_prefix?)
    assert( pn.valid_pcba_dash_number?)
    assert( pn.valid_pcb_part_number?)
    assert( pn.valid_pcba_part_number?)
    assert(!pn.valid_components?('new'=='new'))
    assert( pn.error_message)
    assert_equal('The PCB part number (600-123-a0 a) and the PCBA part number ' +
                 "(600-123-00 b) must be unique - YOUR PART NUMBER WAS NOT CREATED",
                 pn.error_message)
    

    # Valid? - No - Format bad, short prefix
    pcb_pn  = '12-123-a0'.split('-')
    pcba_pn = '34-120-00'.split('-')
    pn.pcb_prefix  = pcb_pn[0]
    pn.pcba_prefix = pcba_pn[0]
    assert( pn.valid_pcb_number?)
    assert(!pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcba_number?)
    assert(!pn.valid_pcba_prefix?)
    assert( pn.valid_pcba_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid_pcba_part_number?)
    assert(!pn.valid_components?('new'=='new'))
    assert_equal(@msg_format_error, pn.error_message)


    # Valid? - No - Format bad, illegal characters in the prefix
    pcb_pn  = '12e-123-a0'.split('-')
    pcba_pn = 'pcb-120-00'.split('-')
    pn.pcb_prefix  = pcb_pn[0]
    pn.pcba_prefix = pcba_pn[0]
    assert( pn.valid_pcb_number?)
    assert(!pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcba_number?)
    assert(!pn.valid_pcba_prefix?)
    assert( pn.valid_pcba_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid_pcba_part_number?)
    assert(!pn.valid_components?('new'=='new'))
    assert_equal(@msg_format_error, pn.error_message)

    # Valid? - No - Format bad, wrong number of characters in the number
    pcb_pn  = '127-3-a0'.split('-')
    pcba_pn = '128-21-00'.split('-')
    pn.pcb_prefix  = pcb_pn[0]
    pn.pcba_prefix = pcba_pn[0]
    pn.pcb_number  = pcb_pn[1]
    pn.pcba_number = pcba_pn[1]
    assert(!pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert(!pn.valid_pcba_number?)
    assert( pn.valid_pcba_prefix?)
    assert( pn.valid_pcba_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid_pcba_part_number?)
    assert(!pn.valid_components?('new'=='new'))
    assert_equal(@msg_format_error, pn.error_message)

    # Valid? - No - Format bad, illegal characters in the number
    pcb_pn  = '127-###-a0'.split('-')
    pcba_pn = '128-JPA-00'.split('-')
    pn.pcb_number  = pcb_pn[1]
    pn.pcba_number = pcba_pn[1]
    assert(!pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert(!pn.valid_pcba_number?)
    assert( pn.valid_pcba_prefix?)
    assert( pn.valid_pcba_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid_pcba_part_number?)
    assert(!pn.valid_components?('new'=='new'))
    assert_equal(@msg_format_error, pn.error_message)

    # Valid? - No - Format bad, illegal characters in the dash number
    pcb_pn  = '127-714-*'.split('-')
    pcba_pn = '128-755-!&'.split('-')
    pn.pcb_number       = pcb_pn[1]
    pn.pcba_number      = pcba_pn[1]
    pn.pcb_dash_number  = pcb_pn[2]
    pn.pcba_dash_number = pcba_pn[2]
    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert(!pn.valid_pcb_dash_number?)
    assert( pn.valid_pcba_number?)
    assert( pn.valid_pcba_prefix?)
    assert(!pn.valid_pcba_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid_pcba_part_number?)
    assert(!pn.valid_components?('new'=='new'))
    assert_equal(@msg_format_error, pn.error_message)

    # Valid? - Yes
    pcb_pn  = '127-714-01'.split('-')
    pcba_pn = '128-755-a0'.split('-')
    pn.pcb_dash_number  = pcb_pn[2]
    pn.pcba_dash_number = pcba_pn[2]
    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcba_number?)
    assert( pn.valid_pcba_prefix?)
    assert( pn.valid_pcba_dash_number?)
    assert( pn.valid_pcb_part_number?)
    assert( pn.valid_pcba_part_number?)
    assert( pn.valid_components?('new'=='new'))
    assert(!pn.error_message)

    # Valid? - Yes
    pn     = PartNumber.initial_part_number
    pcb_pn = '600-123-a0'.split('-') 
    pn.pcb_prefix      = pcb_pn[0]
    pn.pcb_number      = pcb_pn[1]
    pn.pcb_dash_number = pcb_pn[2]

    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcb_part_number?)
    assert( pn.valid_components?('not'=='new'))
    assert(!pn.error_message)
    
    # Valid? - No, pcb pn exists.
    pcb_pn = '252-700-b0'.split('-') 
    pn.pcb_prefix      = pcb_pn[0]
    pn.pcb_number      = pcb_pn[1]
    pn.pcb_dash_number = pcb_pn[2]
    pn.pcb_revision    = 'a'

    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcb_part_number?)
    assert(!pn.valid_components?('not'=='new'))
    assert_equal(@msg_pcb_exists_pcb, pn.error_message)
    
    # Valid? - No, pcb pn duplicates pcba pn    
    pcb_pn = '259-700-00'.split('-')
    pn.pcb_prefix      = pcb_pn[0]
    pn.pcb_number      = pcb_pn[1]
    pn.pcb_dash_number = pcb_pn[2]
    pn.pcb_revision    = 'b'

    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcb_part_number?)
    assert(!pn.valid_components?('not'=='new'))
    assert_equal(@msg_pcb_exists_pcba, pn.error_message)
    
    # Valid? - No, pcb pn prefix contains the wrong number of characters    
    pcb_pn = '12-700-00'.split('-')
    pn.pcb_prefix      = pcb_pn[0]
    assert( pn.valid_pcb_number?)
    assert(!pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid_components?('not'=='new'))
    assert_equal(@msg_format_error, pn.error_message)

    # Valid? - No, pcb pn prefix contains illegal characters    
    pcb_pn = '12e-700-00'.split('-')
    pn.pcb_prefix      = pcb_pn[0]
    assert( pn.valid_pcb_number?)
    assert(!pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid_components?('not'=='new'))
    assert_equal(@msg_format_error, pn.error_message)


    # Valid? - No, pcb pn number contains wrong number of characters    
    pcb_pn = '127-3-00'.split('-')
    pn.pcb_prefix  = pcb_pn[0]
    pn.pcb_number  = pcb_pn[1]
    assert(!pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid_components?('not'=='new'))
    assert_equal(@msg_format_error, pn.error_message)


    # Valid? - No, pcb pn number contains illegal characters    
    pcb_pn = '127-#*@-00'.split('-')
    pn.pcb_number  = pcb_pn[1]
    assert(!pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid_components?('not'=='new'))
    assert_equal(@msg_format_error, pn.error_message)


    # Valid? - No, pcb pn dash number contains wrong number of, and illegal, characters    
    pcb_pn = '127-714-@'.split('-')
    pn.pcb_number      = pcb_pn[1]
    pn.pcb_dash_number = pcb_pn[2]
    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert(!pn.valid_pcb_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid_components?('not'=='new'))
    assert_equal(@msg_format_error, pn.error_message)

    # Valid? - Yes  
    pcb_pn = '127-714-01'.split('-')
    pn.pcb_dash_number = pcb_pn[2]
    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcb_part_number?)
    assert( pn.valid_components?('not'=='new'))
    assert(!pn.error_message)
    
    
    assert(!pn.exists?)
    assert_nil(pn.error_message)
    pn.save
    assert(pn.exists?)
    assert_equal(@msg_pcb_exists_pcb, pn.error_message)

    assert(PartNumber.valid_prefix?('100'))
    assert(!PartNumber.valid_prefix?('1'))
    assert(!PartNumber.valid_prefix?('a'))
    assert(!PartNumber.valid_prefix?('10'))
    assert(!PartNumber.valid_prefix?('a7'))
    assert(!PartNumber.valid_prefix?('1aa'))
    assert(!PartNumber.valid_prefix?('a00'))
    assert(!PartNumber.valid_prefix?('1776'))
    assert(!PartNumber.valid_prefix?('a345'))
    
    assert(PartNumber.valid_number?('100'))
    assert(!PartNumber.valid_number?('1'))
    assert(!PartNumber.valid_number?('a'))
    assert(!PartNumber.valid_number?('10'))
    assert(!PartNumber.valid_number?('a7'))
    assert(!PartNumber.valid_number?('1aa'))
    assert(!PartNumber.valid_number?('a00'))
    assert(!PartNumber.valid_number?('1776'))
    assert(!PartNumber.valid_number?('a345'))
    
    assert(PartNumber.valid_dash_number?('a0'))
    assert(PartNumber.valid_dash_number?('0a'))
    assert(!PartNumber.valid_dash_number?('a'))
    assert(!PartNumber.valid_dash_number?('4'))
    assert(!PartNumber.valid_dash_number?('aa33'))
    assert(!PartNumber.valid_dash_number?('333'))
    
    # Create known part numbers for testing.
    pn = PartNumber.initial_part_number
    pcb_pn = '700-801-00'.split('-')
    pn.pcb_prefix      = pcb_pn[0]
    pn.pcb_number      = pcb_pn[1]
    pn.pcb_dash_number = pcb_pn[2]
    pn.save
    
    pn = PartNumber.initial_part_number
    pcb_pn  = '700-802-00'.split('-')
    pcba_pn = '700-804-00'.split('-')
    pn.pcb_prefix       = pcb_pn[0]
    pn.pcb_number       = pcb_pn[1]
    pn.pcb_dash_number  = pcb_pn[2]
    pn.pcba_prefix      = pcba_pn[0]
    pn.pcba_number      = pcba_pn[1]
    pn.pcba_dash_number = pcba_pn[2]
    pn.save
    
    pn = PartNumber.initial_part_number
    pcb_pn = '700-801-01'.split('-')
    pn.pcb_prefix       = pcb_pn[0]
    pn.pcb_number       = pcb_pn[1]
    pn.pcb_dash_number  = pcb_pn[2]
    assert( pn.valid_components?('not'=='new'))
    assert(!pn.error_message)

    pn = PartNumber.initial_part_number
    pcb_pn = '700-804-00'.split('-')
    pn.pcb_prefix       = pcb_pn[0]
    pn.pcb_number       = pcb_pn[1]
    pn.pcb_dash_number  = pcb_pn[2]
    assert(!pn.valid_components?('not'=='new'))
    assert( pn.error_message)
    assert_equal(@msg_pcb_exists_pcba, pn.error_message)
    
    pcba_pn = '700-900-90'.split('-')
    pn.pcba_prefix      = pcba_pn[0]
    pn.pcba_number      = pcba_pn[1]
    pn.pcba_dash_number = pcba_pn[2]
    pn.pcba_revision    = 'b'
    assert(!pn.valid_components?('new'))
    assert( pn.error_message)
    assert_equal(@msg_pcb_exists_pcba, pn.error_message)
    
    pn = PartNumber.initial_part_number
    pcb_pn = '700-804-99'.split('-')
    pn.pcb_prefix       = pcb_pn[0]
    pn.pcb_number       = pcb_pn[1]
    pn.pcb_dash_number  = pcb_pn[2]
    assert(!pn.valid_components?('not'=='new'))
    assert( pn.error_message)
    assert_equal(@msg_pcb_exists_pcba, pn.error_message)

    pcba_pn = '000-000-00'.split('-')
    pn.pcba_prefix      = pcba_pn[0]
    pn.pcba_number      = pcba_pn[1]
    pn.pcba_dash_number = pcba_pn[2]
    pn.pcba_revision    = 'a'
    assert(!pn.valid_components?('new'))
    assert( pn.error_message)
    assert_equal(@msg_pcb_exists_pcba, pn.error_message)
    
    pcb_pn = '700-805-13'.split('-')
    pn.pcb_prefix       = pcb_pn[0]
    pn.pcb_number       = pcb_pn[1]
    pn.pcb_dash_number  = pcb_pn[2]
    pcba_pn = '700-801-99'.split('-')
    pn.pcba_prefix      = pcba_pn[0]
    pn.pcba_number      = pcba_pn[1]
    pn.pcba_dash_number = pcba_pn[2]
    pn.pcba_revision    = 'b'
    assert(!pn.valid_components?('new'))
    assert( pn.error_message)
    assert_equal(@msg_pcba_exists_pcb, pn.error_message)
    
  end


  ######################################################################
  #
  # Validates the following:  entry_exists?
  #                           exists?
  #                           get_id
  #                           get_part_number
  #                           pcb_pn_exists?
  #                           pcba_pn_exists?
  #
  ######################################################################
  def test_existence

    # Define and store a new part number.
    pn = PartNumber.initial_part_number
    pn.pcb_prefix       = '600'
    pn.pcb_number       = '123'
    pn.pcb_dash_number  = 'a0'
    pn.pcba_prefix      = '600'
    pn.pcba_number      = '233'
    pn.pcba_dash_number = 'a0'
                         
    assert(!pn.exists?)
    assert(!pn.entry_exists?)
    assert_nil(pn.error_message)
    pn.get_id
    assert(0, pn.id)
    assert_nil(PartNumber.get_part_number(pn))
    pn.save
    
    assert(pn.exists?)
    assert_not_nil(PartNumber.get_part_number(pn))
    assert_equal(@msg_pcb_pcba_exists, pn.error_message)
    assert_equal(pn.id,                PartNumber.get_part_number(pn).id)
    
    assert(!pn.entry_exists?)
    board_design_entry = BoardDesignEntry.new(:part_number_id => pn.id,
                                              :lead_free_device_names => '',
                                              :originator_comments    => '',
                                              :input_gate_commnets    => '')
    board_design_entry.save
    assert(pn.entry_exists?)
    assert_equal('The entry already exists', pn.error_message)
   
    
    # Try the same part number that was just created.
    new_pn = PartNumber.initial_part_number
    new_pn.pcb_prefix       = '600'
    new_pn.pcb_number       = '123'
    new_pn.pcb_dash_number  = 'a0'
    new_pn.pcba_prefix      = '600'
    new_pn.pcba_number      = '233'
    new_pn.pcba_dash_number = 'a0'

    assert_equal(pn.id, new_pn.get_id)
    assert(new_pn.exists?)
    assert_equal(@msg_pcb_pcba_exists,  new_pn.error_message)
    assert(new_pn.pcb_pn_exists?)
    assert_equal(@msg_pcb_exists_pcb,   new_pn.error_message)
    assert(new_pn.pcba_pn_exists?)
    assert_equal(@msg_pcba_exists_pcba, new_pn.error_message)
    
    
    # Try a new part number with a PCBA that is the same as an existing
    # part number PCBA component
    new_pn = PartNumber.initial_part_number
    new_pn.pcb_prefix       = '700'
    new_pn.pcb_number       = '123'
    new_pn.pcb_dash_number  = 'b0'
    new_pn.pcba_prefix      = '600'
    new_pn.pcba_number      = '233'
    new_pn.pcba_dash_number = 'a0'

    assert(new_pn.exists?)
    assert_equal(@msg_pcba_exists_pcba, new_pn.error_message)
    assert(!new_pn.pcb_pn_exists?)
    assert_equal(nil,                   new_pn.error_message)
    assert(new_pn.pcba_pn_exists?)
    assert_equal(@msg_pcba_exists_pcba, new_pn.error_message)


    # Try a new part number with a PCBA that is the same as an existing
    # part number PCB component
    new_pn = PartNumber.initial_part_number
    new_pn.pcb_prefix       = '600'
    new_pn.pcb_number       = '888'
    new_pn.pcb_dash_number  = 'a0'
    new_pn.pcba_prefix      = '600'
    new_pn.pcba_number      = '123'
    new_pn.pcba_dash_number = 'a0'

    assert(new_pn.exists?)
    assert_equal(@msg_pcba_exists_pcb, new_pn.error_message)
    assert(!new_pn.pcb_pn_exists?)
    assert_equal(nil,                  new_pn.error_message)
    assert(new_pn.pcba_pn_exists?)
    assert_equal(@msg_pcba_exists_pcb, new_pn.error_message)


    # Try a new part number with a PCB that is the same as an existing
    # part number PCBA component
    new_pn = PartNumber.initial_part_number
    new_pn.pcb_prefix       = '600'
    new_pn.pcb_number       = '233'
    new_pn.pcb_dash_number  = 'a0'
    new_pn.pcba_prefix      = '600'
    new_pn.pcba_number      = '923'
    new_pn.pcba_dash_number = 'a0'

    assert(new_pn.exists?)
    assert_equal(@msg_pcb_exists_pcba, new_pn.error_message)
    assert(new_pn.pcb_pn_exists?)
    assert_equal(@msg_pcb_exists_pcba, new_pn.error_message)
    assert(!new_pn.pcba_pn_exists?)
    assert_equal(nil,                  new_pn.error_message)

    
    # Try a new part number with a PCB that is the same as an existing
    # part number PCB component
    new_pn = PartNumber.initial_part_number
    new_pn.pcb_prefix       = '600'
    new_pn.pcb_number       = '123'
    new_pn.pcb_dash_number  = 'a0'
    new_pn.pcba_prefix      = '666'
    new_pn.pcba_number      = '999'
    new_pn.pcba_dash_number = 'f8'

    assert(new_pn.exists?)
    assert_equal(@msg_pcb_exists_pcb, new_pn.error_message)
    assert(new_pn.pcb_pn_exists?)
    assert_equal(@msg_pcb_exists_pcb, new_pn.error_message)
    assert(!new_pn.pcba_pn_exists?)
    assert_equal(nil,                 new_pn.error_message)
    
    eco_pn = part_numbers(:eco_number)
    retrieved_eco_pn = PartNumber.get_part_number(eco_pn)

  end
  

  ######################################################################
  #
  # Validates the following:  clear_error_message
  #                           error_message
  #                           get_unique_pcb_numbers
  #                           initial_part_number
  #                           name
  #                           new?
  #                           pcb_display_name
  #                           pcb_name
  #                           pcb_pn_equal?
  #                           pcba_pn_equal?
  #                           pcba_display_name
  #                           pcba_name
  #                           set_error_message
  #
  ######################################################################
  def test_other

    initial_pn = PartNumber.initial_part_number
    
    pn = PartNumber.initial_part_number
    assert_equal('000', pn.pcb_prefix)
    assert_equal('000', pn.pcb_number)
    assert_equal('00',  pn.pcb_dash_number)
    assert_equal('a',   pn.pcb_revision)
    assert_equal('000', pn.pcba_prefix)
    assert_equal('000', pn.pcba_number)
    assert_equal('00',  pn.pcba_dash_number)
    assert_equal('a',   pn.pcba_revision)
    assert(!pn.new?)
    assert(initial_pn.pcb_pn_equal?(pn))
    assert(initial_pn.pcba_pn_equal?(pn))
    
    pn.pcb_prefix       = '200'
    pn.pcb_number       = '200'
    pn.pcb_dash_number  = '01'
    pn.pcb_revision     = 'a'
    pn.pcba_prefix      = '100'
    pn.pcba_number      = '100'
    pn.pcba_dash_number = '01'
    pn.pcba_revision    = 'a'
    assert(pn.new?)
    assert(!initial_pn.pcb_pn_equal?(pn))
    assert(!initial_pn.pcba_pn_equal?(pn))

    pn = PartNumber.initial_part_number
    pn.pcb_prefix       = '600'
    pn.pcb_number       = '123'
    pn.pcb_dash_number  = 'a0'
    pn.pcba_prefix      = '600'
    pn.pcba_number      = '233'
    pn.pcba_dash_number = 'a0'

    assert_equal('600-123-a0',              pn.pcb_name)
    assert_equal('600-123-a0 a',            pn.pcb_display_name)
    assert_equal('600-233-a0',              pn.pcba_name)
    assert_equal('600-233-a0 a',            pn.pcba_display_name)
    assert_equal('600-123-a0 / 600-233-a0', pn.name)
    
    
    pn = PartNumber.initial_part_number
    pn.pcb_prefix       = '600'
    pn.pcb_number       = '123'
    pn.pcb_dash_number  = 'b0'
    pn.pcb_revision     = 'z'
    pn.pcba_prefix      = '600'
    pn.pcba_number      = '233'
    pn.pcba_dash_number = 'a0'
    pn.pcba_revision    = 't'

    assert_equal('600-123-b0',              pn.pcb_name)
    assert_equal('600-123-b0 z',            pn.pcb_display_name)
    assert_equal('600-233-a0',              pn.pcba_name)
    assert_equal('600-233-a0 t',            pn.pcba_display_name)
    assert_equal('600-123-b0 / 600-233-a0', pn.name)
    
    
    assert_equal(nil, pn.error_message)
    pn.set_error_message('This is a test')
    assert_equal('This is a test', pn.error_message)
    pn.clear_error_message
    assert_equal(nil, pn.error_message)  
    
  end 
  
  
  def test_get_unique_pcb_numbers
    
    expected_pcb_numbers = %w(252-232   252-234   252-600   252-700   252-999 
                              942-453   942-454   942-455)
    assert_equal(expected_pcb_numbers, PartNumber.get_unique_pcb_numbers)
    
    PartNumber.destroy_all
    assert_equal([], PartNumber.get_unique_pcb_numbers)

  end


  def test_get_designs
    
    expected_designs = [designs(:mx999c), designs(:mx999b), designs(:mx999a)]
    
    design_list = PartNumber.get_designs('252-999')
    assert_equal(3, design_list.size)
    assert_equal(expected_designs, design_list)
    
    design_list = PartNumber.get_designs('100-714')
    assert_equal(0, design_list.size)
    
    design_list = PartNumber.get_designs('000-000')
    assert_equal(0, design_list.size)
    
  end


  def test_unique_methods
    
    pn = part_numbers(:mx008b4_eco)
    assert_equal('252-008', pn.pcb_unique_number)
    assert_equal('259-008', pn.pcba_unique_number)
    
    assert(!pn.unique_part_numbers_equal?)
    pn.pcba_prefix = '252'
    assert(pn.unique_part_numbers_equal?)
    
  end
  
  
  def test_directory_name
    
    pcb100_714_b0_l = part_numbers(:av714b)
    assert_equal('pcb100_714_b0_l', pcb100_714_b0_l.directory_name)
    
    pcb100_714_b0 = PartNumber.new( :pcb_prefix      => '100',
                                    :pcb_number      => '714',
                                    :pcb_dash_number => 'b0' )
    assert_equal('', pcb100_714_b0.directory_name)
  end


end
