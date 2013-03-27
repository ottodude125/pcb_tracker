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
  
  
  MAX_FILE_SIZE = 16777215


  ##############################################################################
  #
  # Instance Methods
  #
  ##############################################################################


  # Set the document fields using the document_field record
  #
  # :call-seq:
  #   document=(document_field) -> document
  #
  # The document fields are loaded with the new data
  def document=(document_field)
    self.name         = base_part_of(document_field.original_filename)
    self.content_type = document_field.content_type.chomp
    self.data         = document_field.read
  end


  # Return the record of the user who created the document
  #
  # :call-seq:
  #   user() -> user
  #
  # Looks up the user and returns the record
  def user
    User.find(self.created_by) if self.created_by != 0
  end


  # Store this instance of the document in the database and create
  # a new design review document record.
  #
  # :call-seq:
  #   attach(design_review, document_type, user) -> nil
  #
  # The document is stored in the database, a design review document is
  # created, and mail is sent to indicate that the document has been attached.
  # If the data is too large to store, then none of that happens.  An error
  # is returned to indicate the problem.
  def attach(design_review, document_type, user)

    if self.data.size < Document::MAX_FILE_SIZE

      self.created_by = user.id
      self.unpacked   = 0

      if self.save
        drd_doc = DesignReviewDocument.new( :document_type_id => document_type.id,
                                            :board_id         => design_review.design.board_id,
                                            :design_id        => design_review.design_id,
                                            :document_id      => self.id)
                                          
        if drd_doc.save
          design_review.reload
          if design_review.design.board.multiple_documents?(document_type)
            subject = "Updated #{document_type.name} document - #{self.name}"
          else
            subject = "Created #{document_type.name} document - #{self.name}"
          end
          DocumentMailer::attachment_update(drd_doc, user, subject).deliver
        else
          errors.add(:design_review_document, "Failed to create the design review document")
          # TODO: THIS CALLS FOR LOGGING
        end
      end
    else
      errors.add(:file_size, "Files must be smaller than #{Document::MAX_FILE_SIZE} characters")
    end

  end
  
  
private

  def base_part_of(file_name)
    name = File.basename(file_name)
    name.gsub(/[^\w._-]/, '')
  end

end
