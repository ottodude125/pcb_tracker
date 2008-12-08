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
  def notest_should_remove_blank_char_from_filename

    document_field = document.new( :content_type => 'text/plain',
                                   :original_filename => 'ECO Data.txt')
                     
    document = Document.new
    puts document.inspect
    document.document = document_field
    
    puts document.inspect
    
    
  end
end
