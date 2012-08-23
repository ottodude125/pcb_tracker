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

require File.expand_path( "../../test_helper", __FILE__ ) 

class BoardsTest < ActiveSupport::TestCase

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


  ######################################################################
  def test_should_have_no_current_documents
    assert_equal([], boards(:la453).current_document_list)
  end


  ######################################################################
  def test_should_have_current_documents
    assert_equal([design_review_documents(:mx234a_eng_notes_doc),
                  design_review_documents(:mx234a_stackup_doc),
                  design_review_documents(:mx234a_other_1_doc),
                  design_review_documents(:mx234a_other_2_doc)],
                 boards(:mx234).current_document_list)
  end


  ######################################################################
  def test_get_current_other_document
    assert_equal(nil, boards(:mx234).get_current_document(document_types(:other)))
  end


  ######################################################################
  def test_get_current_outline_drawing_document
    assert_equal(nil, boards(:mx234).get_current_document(document_types(:outline_drawing)))
  end


  ######################################################################
  def test_get_current_stackup_document
    assert_equal(design_review_documents(:mx234a_stackup_doc),
                 boards(:mx234).get_current_document(document_types(:stackup)))
  end


  ######################################################################
  def test_should_get_empty_list_of_obsolet_documents
    assert_equal([], boards(:la453).get_obsolete_document_list(document_types(:stackup)))
    assert_equal([], boards(:mx234).get_obsolete_document_list(document_types(:outline_drawing)))
    assert_equal([], boards(:mx234).get_obsolete_document_list(document_types(:eng_inst)))
    assert_equal([], boards(:mx234).get_obsolete_document_list(document_types(:other)))
  end


  ######################################################################
  def test_should_get_loaded_list_of_obsolete_documents
    assert_equal([design_review_documents(:mx234a_obsolete_stackup_doc)],
                 boards(:mx234).get_obsolete_document_list(document_types(:stackup)))
  end


  ######################################################################
  def test_multiple_documents_method
    assert(!boards(:la453).multiple_documents?(document_types(:stackup)))
    assert(!boards(:mx234).multiple_documents?(document_types(:other)))
    assert(!boards(:mx234).multiple_documents?(document_types(:eng_inst)))
    assert( boards(:mx234).multiple_documents?(document_types(:stackup)))
  end


  ######################################################################
  def test_get_documents_other
    assert_equal([], boards(:la453).get_documents_other)
    assert_equal([design_review_documents(:mx234a_other_1_doc),
                  design_review_documents(:mx234a_other_2_doc)],
                 boards(:mx234).get_documents_other)
  end


end
