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
    
    other = DocumentType.get_other_document_type.name
    pad_p = DocumentType.get_pad_patterns_document_type.name
    mechd = DocumentType.get_mech_drawing_document_type.name
    test  = DocumentType.get_test_document_type.name
    
    DocumentType.get_document_types.each do |doc_type|
      next if doc_type.name == other
      next if doc_type.name == pad_p
      next if doc_type.name == mechd
      next if doc_type.name == test
      document = self.get_current_document(doc_type)
      list << document if document
    end
    list.push(*self.get_documents_pad_patterns)
    list.push(*self.get_documents_mech_drawing)
    list.push(*self.get_documents_other)
    list.push(*self.get_documents_test)
  end


  # Retrieve the current document for the document type.
  #
  # :call-seq:
  #   get_current_document(document_type) -> document
  #
  # Returns the most recent version of the document type
  def get_current_document(document_type)

    documents = self.design_review_documents
    other = DocumentType.get_other_document_type.name
    pad_p = DocumentType.get_pad_patterns_document_type.name
    mechd = DocumentType.get_mech_drawing_document_type.name
    test  = DocumentType.get_test_document_type.name

    docs = documents.collect { |d| d if d.document_type_id == document_type.id }.compact
    if document_type.name != other && document_type.name != pad_p && document_type.name != mechd && document_type.name != test && docs.size > 0
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
    other = DocumentType.get_other_document_type.name
    pad_p = DocumentType.get_pad_patterns_document_type.name
    mechd = DocumentType.get_mech_drawing_document_type.name
    test  = DocumentType.get_test_document_type.name

    if document_type.name != other && document_type.name != pad_p && document_type.name != mechd && document_type.name != test
      documents = self.design_review_documents
      docs = documents.collect { |d| d if d.document_type_id == document_type.id }.compact
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
    documents = self.design_review_documents
    other = DocumentType.get_other_document_type.name
    pad_p = DocumentType.get_pad_patterns_document_type.name
    mechd = DocumentType.get_mech_drawing_document_type.name
    test  = DocumentType.get_test_document_type.name

    other_document = document_type.name == other
    pad_p_document = document_type.name == pad_p
    mechd_document = document_type.name == mechd
    test_document  = document_type.name == test
    
    if !other_document && !pad_p_document && !mechd_document && !test_document
      documents |= self.design_review_documents
      docs = documents.collect { |d| d if d.document_type_id == document_type.id }.compact
    end

    !other_document && !pad_p_document && !mechd_document && !test_document && docs.size > 1
    
  end

 # Retrieve a list of the 'Other' document type documents that have been
 # attached to the board
 #
 # :call-seq:
 #   get_documents_other() -> [document]
 #
 # Returns an array of documents
 def get_documents_other
    documents = self.design_review_documents

    doc_type_other = DocumentType.get_other_document_type
    documents.collect { |d| d if d.document_type_id == doc_type_other.id }.compact
  end
  

 # Retrieve a list of the 'Pad Patterns' document type documents that have been
 # attached to the board
 #
 # :call-seq:
 #   get_documents_pad_patterns() -> [document]
 #
 # Returns an array of documents
 def get_documents_pad_patterns
    documents = self.design_review_documents

    doc_type_pad_p = DocumentType.get_pad_patterns_document_type
    documents.collect { |d| d if d.document_type_id == doc_type_pad_p.id }.compact
  end

 # Retrieve a list of the 'Mech Drawing' document type documents that have been
 # attached to the board
 #
 # :call-seq:
 #   get_documents_mech_drawing() -> [document]
 #
 # Returns an array of documents
 def get_documents_mech_drawing
    documents = self.design_review_documents

    doc_type_mechd = DocumentType.get_mech_drawing_document_type
    documents.collect { |d| d if d.document_type_id == doc_type_mechd.id }.compact
  end  

 # Retrieve a list of the 'Test' document type documents that have been
 # attached to the board
 #
 # :call-seq:
 #   get_documents_test() -> [document]
 #
 # Returns an array of documents
 def get_documents_test
    documents = self.design_review_documents

    doc_type_test = DocumentType.get_test_document_type
    documents.collect { |d| d if d.document_type_id == doc_type_test.id }.compact
  end
  
  ######################################################################
  #
  # copy_to_on_milestone
  #
  # Description:
  # Given a board this method will return a list of the
  # people who should be CC'ed on all milestone mails
  #
  # Parameters:
  #   board - the board to get the milestone CC list for.
  #
  ######################################################################
  #
  def copy_to_on_milestone
    self.add_board_reviewer(
                       ['Program Manager',
                        'Hardware Engineering Manager'])
  end


  ######################################################################
  #
  # add_board_reviewer
  #
  # Description:
  # Given a board and a list of roles this function will load the
  # CC list with users associated with the role for that board.
  #
  # Parameters:
  #   board - the board record.
  #   roles - a list of roles.  The associated user's email will be
  #           added to the CC list.
  #
  ######################################################################
  #
  def add_board_reviewer(roles)

    cc_list   = []
    role_list = Role.find(:all)

    roles.each do |role|

      reviewer_role  = role_list.detect { |r| r.name == role }
      board_reviewer = self.board_reviewers.detect { |br| br.role_id == reviewer_role.id }

      if board_reviewer && board_reviewer.reviewer_id?
        cc_list << User.find(board_reviewer.reviewer_id).email
      end

    end

    return cc_list

  end

end
