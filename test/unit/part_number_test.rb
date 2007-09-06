require File.dirname(__FILE__) + '/../test_helper'

class PartNumberTest < Test::Unit::TestCase
  
  fixtures :board_design_entries,
           :part_numbers

  def setup
    @msg_format_error = 'The correct format for a part number is "ddd-ddd-aa" '+
                        '<br /> Where: "ddd" is a 3 digit number and "aa"' +
                        ' is 2 alpha-numeric characters.'
    @msg_pcb_pcba_exists  = "The supplied PCB and PCBA Part Number is " +
                            "already in the database"
    @msg_pcba_exists_pcba = "The supplied PCBA Part Number exists as a PCBA " +
                            "Part Number in the database"
    @msg_pcba_exists_pcb  = "The supplied PCBA Part Number exists as a PCB " +
                            "Part Number in the database"
    @msg_pcb_exists_pcba  = "The supplied PCB Part Number exists as a PCBA " +
                            "Part Number in the database"
    @msg_pcb_exists_pcb   = "The supplied PCB Part Number exists as a PCB " +
                            "Part Number in the database"
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
    
    pn = PartNumber.initial_part_number
    pn.pcb_prefix       = '600'
    pn.pcb_number       = '123'
    pn.pcb_dash_number  = 'a0'
    pn.pcba_prefix      = '500'
    pn.pcba_number      = '120'
    pn.pcba_dash_number = '00'
                         
    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcba_number?)
    assert( pn.valid_pcba_prefix?)
    assert( pn.valid_pcba_dash_number?)
    assert( pn.valid_pcb_part_number?)
    assert( pn.valid_pcba_part_number?)
    assert( pn.valid?('new'=='new'))
    assert(!pn.error_message)
    
    pn.pcb_prefix  = '12'
    pn.pcba_prefix = '34'
    assert( pn.valid_pcb_number?)
    assert(!pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcba_number?)
    assert(!pn.valid_pcba_prefix?)
    assert( pn.valid_pcba_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid_pcba_part_number?)
    assert(!pn.valid?('new'=='new'))
    assert_equal(@msg_format_error, pn.error_message)

    pn.pcb_prefix  = '12e'
    pn.pcba_prefix = 'pcb'
    assert( pn.valid_pcb_number?)
    assert(!pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcba_number?)
    assert(!pn.valid_pcba_prefix?)
    assert( pn.valid_pcba_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid_pcba_part_number?)
    assert(!pn.valid?('new'=='new'))
    assert_equal(@msg_format_error, pn.error_message)

    pn.pcb_prefix  = '127'
    pn.pcba_prefix = '128'
    pn.pcb_number  = '3'
    pn.pcba_number = '21'
    assert(!pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert(!pn.valid_pcba_number?)
    assert( pn.valid_pcba_prefix?)
    assert( pn.valid_pcba_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid_pcba_part_number?)
    assert(!pn.valid?('new'=='new'))
    assert_equal(@msg_format_error, pn.error_message)

    pn.pcb_number  = '---'
    pn.pcba_number = 'JPA'
    assert(!pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert(!pn.valid_pcba_number?)
    assert( pn.valid_pcba_prefix?)
    assert( pn.valid_pcba_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid_pcba_part_number?)
    assert(!pn.valid?('new'=='new'))
    assert_equal(@msg_format_error, pn.error_message)

    pn.pcb_number       = '714'
    pn.pcba_number      = '755'
    pn.pcb_dash_number  = '*'
    pn.pcba_dash_number = '!&'
    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert(!pn.valid_pcb_dash_number?)
    assert( pn.valid_pcba_number?)
    assert( pn.valid_pcba_prefix?)
    assert(!pn.valid_pcba_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid_pcba_part_number?)
    assert(!pn.valid?('new'=='new'))
    assert_equal(@msg_format_error, pn.error_message)

    pn.pcb_dash_number  = '01'
    pn.pcba_dash_number = 'a0'
    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcba_number?)
    assert( pn.valid_pcba_prefix?)
    assert( pn.valid_pcba_dash_number?)
    assert( pn.valid_pcb_part_number?)
    assert( pn.valid_pcba_part_number?)
    assert( pn.valid?('new'=='new'))
    assert(!pn.error_message)
  
    pn = PartNumber.initial_part_number
    pn.pcb_prefix       = '600'
    pn.pcb_number       = '123'
    pn.pcb_dash_number  = 'a0'

    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcb_part_number?)
    assert( pn.valid?('not'=='new'))
    assert(!pn.error_message)
    
    
    pn = PartNumber.initial_part_number
    pn.pcb_prefix      = '252'
    pn.pcb_number      = '700'
    pn.pcb_dash_number = 'b0'
    pn.pcb_revision    = 'a'

    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcb_part_number?)
    assert(!pn.valid?('not'=='new'))
    assert_equal(@msg_pcb_exists_pcb, pn.error_message)
    
    
    pn = PartNumber.initial_part_number
    pn.pcb_prefix      = '259'
    pn.pcb_number      = '700'
    pn.pcb_dash_number = '00'
    pn.pcb_revision    = 'b'

    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcb_part_number?)
    assert(!pn.valid?('not'=='new'))
    assert_equal(@msg_pcb_exists_pcba, pn.error_message)
    
    
    pn.pcb_prefix  = '12'
    assert( pn.valid_pcb_number?)
    assert(!pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid?('not'=='new'))
    assert_equal(@msg_format_error, pn.error_message)


    pn.pcb_prefix  = '12e'
    assert( pn.valid_pcb_number?)
    assert(!pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid?('not'=='new'))
    assert_equal(@msg_format_error, pn.error_message)


    pn.pcb_prefix  = '127'
    pn.pcb_number  = '3'
    assert(!pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid?('not'=='new'))
    assert_equal(@msg_format_error, pn.error_message)


    pn.pcb_number  = '---'
    assert(!pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid?('not'=='new'))
    assert_equal(@msg_format_error, pn.error_message)


    pn.pcb_number       = '714'
    pn.pcb_dash_number  = '*'
    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert(!pn.valid_pcb_dash_number?)
    assert(!pn.valid_pcb_part_number?)
    assert(!pn.valid?('not'=='new'))
    assert_equal(@msg_format_error, pn.error_message)


    pn.pcb_dash_number  = '01'
    assert( pn.valid_pcb_number?)
    assert( pn.valid_pcb_prefix?)
    assert( pn.valid_pcb_dash_number?)
    assert( pn.valid_pcb_part_number?)
    assert( pn.valid?('not'=='new'))
    assert(!pn.error_message)

    
    assert(!pn.exists?)
    assert_nil(pn.error_message)
    pn.create
    assert(pn.exists?)
    assert_equal(@msg_pcb_exists_pcb, pn.error_message)

    pn = PartNumber.initial_part_number
    pn.pcb_prefix       = '100'
    pn.pcb_number       = '101'
    pn.pcb_dash_number  = '01'
    pn.pcb_revision     = 'a'
    pn.pcba_prefix      = '100'
    pn.pcba_number      = '101'
    pn.pcba_dash_number = '01'
    pn.pcba_revision    = 'a'
    
    assert(!pn.valid?('not'=='new'))
    assert_equal('The PCB part number (' + pn.pcb_display_name +
                 ') and the PCBA part number (' + pn.pcba_display_name +
                 ') must be different', 
                 pn.error_message)
    
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
    pn.create
    
    assert(pn.exists?)
    assert_not_nil(PartNumber.get_part_number(pn))
    assert_equal(@msg_pcb_pcba_exists, pn.error_message)
    assert_equal(pn.id,                PartNumber.get_part_number(pn).id)
    
    assert(!pn.entry_exists?)
    board_design_entry = BoardDesignEntry.new(:part_number_id => pn.id)
    board_design_entry.create
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
    assert_equal('0',   pn.pcb_revision)
    assert_equal('000', pn.pcba_prefix)
    assert_equal('000', pn.pcba_number)
    assert_equal('00',  pn.pcba_dash_number)
    assert_equal('0',   pn.pcba_revision)
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
    assert_equal('600-123-a0 0',            pn.pcb_display_name)
    assert_equal('600-233-a0',              pn.pcba_name)
    assert_equal('600-233-a0 0',            pn.pcba_display_name)
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


end
