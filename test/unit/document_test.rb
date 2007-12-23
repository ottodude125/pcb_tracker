########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: document_test.rb
#
# This file contains the unit tests for the document model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class DocumentTest < Test::Unit::TestCase

  
  fixtures :documents


  def setup
    @document = documents(:mx234a_stackup_document)  
  end


  ######################################################################
  def test_truth
    assert_kind_of Document,  @document
  end
end
