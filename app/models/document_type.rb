########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: document_type.rb
#
# This file maintains the state for document types.
#
# $Id$
#
########################################################################

class DocumentType < ActiveRecord::Base

  belongs_to      :design_review_document

  validates_uniqueness_of(:name,
                          :message => 'already exists in the database')

  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


  ######################################################################
  #
  # get_document_types
  #
  # Description:
  # This method retrieves all of the document type records
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of document type records ordered by name
  #
  ######################################################################
  #
  def self.get_document_types
    self.find(:all, :order => 'name')
  end
  
  
  ######################################################################
  #
  # get_active_document_types
  #
  # Description:
  # This method retrieves all of the active document type records
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of active document type records ordered by name
  #
  ######################################################################
  #
  def self.get_active_document_types
    self.find(:all, :conditions => 'active=1', :order => 'name')
  end

  ######################################################################
  #
  # get_test_document_type
  #
  # Description:
  # This method retrieves the Test document type
  #
  # Parameters:
  # None
  #
  # Return value:
  # A document type
  #
  ######################################################################
  #
  def self.get_test_document_type
    self.find_by_name("Test")
  end
  
  ######################################################################
  #
  # get_other_document_type
  #
  # Description:
  # This method retrieves the Other document type
  #
  # Parameters:
  # None
  #
  # Return value:
  # A document type
  #
  ######################################################################
  #
  def self.get_other_document_type
    self.find_by_name("Other")
  end
  
  ######################################################################
  #
  # get_mech_drawing_document_type
  #
  # Description:
  # This method retrieves the Mech Drawing document type
  #
  # Parameters:
  # None
  #
  # Return value:
  # A document type
  #
  ######################################################################
  #
  def self.get_mech_drawing_document_type
    self.find_by_name("Mech Drawing")
  end
  
  ######################################################################
  #
  # get_pad_patterns_document_type
  #
  # Description:
  # This method retrieves the Pad Patterns document type
  #
  # Parameters:
  # None
  #
  # Return value:
  # A document type
  #
  ######################################################################
  #
  def self.get_pad_patterns_document_type
    self.find_by_name("Pad Patterns")
  end
        
end
