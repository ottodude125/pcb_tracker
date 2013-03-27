########################################################################
#
# Copyright 2011, by Teradyne, Inc., Boston MA
#
# File: part_num_test.rb
#
# This file contains the unit tests for the design model
#
# Revision History:
#   $Id$
#
########################################################################require File.expand_path( "../../test_helper", __FILE__ ) 

require File.expand_path( "../../test_helper", __FILE__ ) 

class PartNumsTest < ActiveSupport::TestCase

  def setup

    @pn_exists = part_nums(:id3)
    @pn_new         = PartNum.new
    @pn_new.prefix  = "987"
    @pn_new.number  = "xxx"
    @pn_new.dash    = "00"

  end


  def test_part_num_exists
    assert( @pn_exists.part_num_exists?)
    assert(! @pn_new.part_num_exists? )

  end

  def test_get_designs
    unique_pn="259-999"
    designs = PartNum.get_designs(unique_pn, "pcba").sort_by { |d| d.id }
    expect_designs = [ designs(:mx999a), designs(:mx999b), designs(:mx999c)].sort_by { |d| d.id }
    assert_equal(expect_designs, designs)
  end

  def test_get_uniq_part_numbers
    type = 'pcb'
    part_nums = PartNum.get_unique_part_numbers(type)
    # the following is the original code from the model
    # if the model is changed, we expect the same result or we have
    # to revise the test
    part_nums_expected = PartNum.find(:all,
      :conditions => "`use` = '#{type}' AND `design_id` IS NOT NULL ",
      :select => "DISTINCT CONCAT(prefix,'-',number) AS number",
      :order => 'number')
    assert_equal(part_nums_expected.to_s, part_nums.to_s)
  end

  def test_get_part_number
    pn_expect        = @pn_exists
    
    pn_test          = PartNum.new
    pn_test.prefix   = pn_expect.prefix
    pn_test.number   = pn_expect.number
    pn_test.dash     = pn_expect.dash
    pn_test.revision = pn_expect.revision

    #Test Class method

    found = PartNum.get_part_number(pn_test)
    assert_equal(pn_expect, found)

    assert(! PartNum.get_part_number(@pn_new))

    #Test instance method
    found = pn_test.get_part_number
    assert_equal(pn_expect, found)

    assert(! @pn_new.get_part_number )
  end

end
