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
# JPA: TO DO - MAX_FILE_SIZE SB 16M
#
########################################################################

class Document < ActiveRecord::Base
  
  has_many :design_review_documents
  
  
  MAX_FILE_SIZE = 167772
  
  def document=(document_field)
    self.name = base_part_of(document_field.original_filename)
    self.content_type = document_field.content_type
    self.data = document_field.read
    logger.info " #### NAME: #{self.name}  CONTENT TYPE: #{self.content_type}"
    #logger.info " #### DATA: #{self.data}"
  end

  def base_part_of(file_name)
    name = File.basename(file_name)
    name.gsub(/[^\w._-]/, '')
  end

end
