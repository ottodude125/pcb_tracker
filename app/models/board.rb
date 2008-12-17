########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: board.rb
#
# This file maintains the state for boards.
#
# $Id$
#
########################################################################

class Board < ActiveRecord::Base

  belongs_to :platform
  belongs_to :project
  belongs_to :prefix

  has_many(:designs,       :order => 'name' )
  has_many   :board_reviewers
  has_many   :design_review_documents
  has_one    :audit

  has_and_belongs_to_many :fab_houses
  has_and_belongs_to_many :users

  validates_presence_of :platform_id
  validates_presence_of :project_id


  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################

  
  # Provide the user record for the reviewer identified by the role
  #
  # :call-seq:
  #   role_reviewer(role_id) -> user
  #
  # Returns a user record that identifies the board's reviewer for the role.
  # If there is no reviewer then nil is returned
  def role_reviewer(role_id)
    self.board_reviewers.detect { |br| br.role_id == role_id }
  end
  

  # Provide the mnemonic based number for the board
  #
  # :call-seq:
  #   name() -> string
  #
  # Returns the mnemonic based number in a string
  def name 
    self.prefix.pcb_mnemonic + self.number
  end


  # Retrieve a list of the current documents that have been attached to
  # the board
  #
  # :call-seq:
  #   current_document_list() -> [document]
  #
  # Returns an array of documents
  def current_document_list
    list = []
    DocumentType.get_document_types.each do |doc_type|
      next if doc_type.name == 'Other'
      document = self.get_current_document(doc_type)
      list << document if document
    end
    list + self.get_documents_other
  end


  # Retrieve the current document for the document type.
  #
  # :call-seq:
  #   get_current_document(document_type) -> document
  #
  # Returns the most recent version of the document type
  def get_current_document(document_type)

    @documents = self.design_review_documents

    docs = @documents.collect { |d| d if d.document_type_id == document_type.id }.compact
    if document_type.name != 'Other' && docs.size > 0
      docs.sort_by { |d| d.document.created_on }.pop
    else
      nil
    end
  end


  # Retrieve a list of the obsolete documents that have been attached to
  # the board
  #
  # :call-seq:
  #   get_obsolete_document_list() -> [document]
  #
  # Returns an array of documents
  def get_obsolete_document_list(document_type)

    if document_type.name != 'Other'
      @documents = self.design_review_documents
      docs = @documents.collect { |d| d if d.document_type_id == document_type.id }.compact
      if docs.size > 0
        docs = docs.sort_by { |d| d.document.created_on }
      end
      docs.pop
      docs
    else
      []
    end
    
  end


  # Indicate if multiple documents for the document type have been attached
  # to the board
  #
  # :call-seq:
  #   multiple_document?(document_type) -> boolean
  #
  # Returns the most recent version of the document type
  def multiple_documents?(document_type)
    @documents = self.design_review_documents

    other_document = document_type.name == 'Other'
    if !other_document
      @documents |= self.design_review_documents
      docs = @documents.collect { |d| d if d.document_type_id == document_type.id }.compact
    end

    !other_document && docs.size > 1
    
  end


 # Retrieve a list of the 'Other' document type documents that have been
 # attached to the board
 #
 # :call-seq:
 #   get_documents_other() -> [document]
 #
 # Returns an array of documents
 def get_documents_other
    @documents = self.design_review_documents

    doc_type_other = DocumentType.find_by_name('Other')
    @documents.collect { |d| d if d.document_type_id == doc_type_other.id }.compact
  end
  
  
end
