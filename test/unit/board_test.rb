########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: board_test.rb
#
# This file contains the unit tests for the board model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class BoardTest < Test::Unit::TestCase


  fixtures(:boards,
           :platforms,
           :prefixes,
           :projects,
           :roles,
           :users)


  def setup
    @board = Board.find(boards(:mx234).id)
  end
  

  ######################################################################
  def test_create

    assert_kind_of Board,  @board

    mx234 = boards(:mx234)
    assert_equal(mx234.id,          @board.id)
    assert_equal(mx234.prefix_id,   @board.prefix_id)
    assert_equal(mx234.number,      @board.number)
    assert_equal(mx234.platform_id, @board.platform_id)
    assert_equal(mx234.project_id,  @board.project_id)
    assert_equal(mx234.active,      @board.active)
    
  end


  ######################################################################
  def test_update

    @board.prefix_id   = prefixes(:mx).id
    @board.number      = '666'
    @board.name        = 'mx666'
    @board.platform_id = platforms(:flex).id
    @board.project_id  = projects(:bbac).id
    @board.active      = 0

    assert @board.save
    @board.reload

    assert_equal('mx',                @board.prefix.pcb_mnemonic)
    assert_equal('666',               @board.number)
    assert_equal('mx666',             @board.name)
    assert_equal(platforms(:flex).id, @board.platform_id)
    assert_equal(projects(:bbac).id,  @board.project_id)
    assert_equal(0,                   @board.active)
  end


  ######################################################################
  def test_destroy
    @board.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Board.find(@board.id) }
  end
  

  ######################################################################
  def test_name
  
    assert_equal('mx234', @board.name)
    assert_equal('mx999', boards(:mx999).name)
  
  end
  

  ######################################################################
  def test_reviewer_functions
  
    la753  = boards(:la453)
    valor  = roles(:valor)
    lisa_a = users(:lisa_a)
    
    assert_nil(la753.role_reviewer(roles(:admin).id))
    
    board_reviewer = la753.role_reviewer(valor.id)
    assert_equal(valor.id,  board_reviewer.role_id)
    assert_equal(lisa_a.id, board_reviewer.reviewer_id)
    assert_equal(la753.id,  board_reviewer.board_id)
    
  end


end
