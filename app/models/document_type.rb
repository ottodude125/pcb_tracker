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

end
