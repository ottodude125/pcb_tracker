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

  belongs_to :design
  belongs_to :document
  belongs_to :document_type
  
  has_many :document_types
  
end
