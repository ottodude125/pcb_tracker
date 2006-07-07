########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: document.rb
#
# This file maintains the state for documents.
#
# $Id$
#
# TODO:  MAX_FILE_SIZE SB 16M
#
########################################################################

class Document < ActiveRecord::Base
  
  has_many :design_review_documents
  
  
  MAX_FILE_SIZE = 16777216
  
  def document=(document_field)

    self.name         = base_part_of(document_field.original_filename)
    self.content_type = document_field.content_type.chomp
    self.data         = document_field.read
  end

  def base_part_of(file_name)
    name = File.basename(file_name)
    name.gsub(/[^\w._-]/, '')
  end

end
