########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_review_document.rb
#
# This file maintains the state for Design Review Documents.
#
# $Id$
#
########################################################################
class DesignReviewDocument < ActiveRecord::Base

  belongs_to :board
  belongs_to :design
  belongs_to :document
  belongs_to :document_type
  
  has_many :document_types
  
  # Remove this instance of the design review document from the database and its
  # related document record.
  #
  # :call-seq:
  #   drd.remove -> nil
  #
  # The design review document is removed from the database, as well as its document
  
  def remove
    
    
    Document.destroy(self.document_id)
    self.destroy
 
  end
  
end