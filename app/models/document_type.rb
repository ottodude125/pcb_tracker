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

  def self.get_all
    self.find(:all, :order => 'name')
  end
  
  
  def self.get_all_active
    self.find(:all, :conditions => 'active=1', :order => 'name')
  end

end
