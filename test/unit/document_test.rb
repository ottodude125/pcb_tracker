########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: document_test.rb
#
# This file contains the unit tests for the document model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class DocumentTest < Test::Unit::TestCase

  
  fixtures :design_reviews,
           :design_review_documents,
           :documents,
           :document_types,
           :users


  def setup
    @document = documents(:mx234a_stackup_document)
    @cathy    = users(:cathy_m)
    @mx234a_placement = design_reviews(:mx234a_placement)

    @emails     = ActionMailer::Base.deliveries
    @emails.clear
  end


  ######################################################################
  # TODO: Figure out how to test document=
  def notest_should_remove_blank_char_from_filename

    document_field = CGI.new( :multipart => true )
    puts document_field.inspect
    document = Document.new(document_field)
                     
    puts document.inspect
    
    
  end


  ######################################################################
  def test_user_returns_nil
    document = Document.new
    assert_nil(document.user)
  end


  ######################################################################
  def test_user_returns_record
    assert_equal(@cathy, @document.user)
  end


  ######################################################################
  def test_document_too_large

    new_document = Document.new( :data         => 'a' * Document::MAX_FILE_SIZE,
                                 :unpacked     => 0,
                                 :name         => 'dummy.doc',
                                 :content_type => 'text/html',
                                 :created_by   => @cathy.id)

    document_count               = Document.count
    design_review_document_count = DesignReviewDocument.count

    new_document.attach(design_reviews(:mx234a_placement),
                        document_types(:stackup),
                        @cathy)

    assert_equal(document_count,               Document.count)
    assert_equal(design_review_document_count, DesignReviewDocument.count)
    assert_equal("Files must be smaller than #{Document::MAX_FILE_SIZE} characters",
                 new_document.errors[:file_size])

  end


  ######################################################################
  # TODO: Figure out why the commented out line causes an error
  def test_document_max_length

    new_document = Document.new( #:data         => 'a' * (Document::MAX_FILE_SIZE - 1),
                                 :data         => 'a' * 100,
                                 :unpacked     => 0,
                                 :name         => 'dummy.doc',
                                 :content_type => 'text/html',
                                 :created_by   => @cathy.id)

    documents               = Document.find(:all)
    design_review_documents = DesignReviewDocument.find(:all)

    new_document.attach(@mx234a_placement,
                        document_types(:stackup),
                        @cathy)

    updated_documents               = Document.find(:all)
    updated_design_review_documents = DesignReviewDocument.find(:all)

    new_document_list               = updated_documents - documents
    new_design_review_document_list = updated_design_review_documents - design_review_documents

    assert_equal(1, new_document_list.size)
    assert_equal(1, new_design_review_document_list.size)

    new_doc                    = new_document_list[0]
    new_design_review_document = new_design_review_document_list[0]

    assert_equal(new_document.id, new_doc.id)
    assert_equal(new_document.id, new_design_review_document.document_id)

    
  end


  ######################################################################
  def test_document_emails

    first_document  = Document.new( :data         => 'a' * 100,
                                    :unpacked     => 0,
                                    :name         => 'dummy.doc',
                                    :content_type => 'text/html',
                                    :created_by   => @cathy.id)
    second_document = Document.new( :data         => 'b' * 100,
                                    :unpacked     => 0,
                                    :name         => 'stackup.doc',
                                    :content_type => 'text/html',
                                    :created_by   => @cathy.id)


    first_document.attach(design_reviews(:la455b_placement),
                          document_types(:stackup),
                          @cathy)

    email = @emails.pop
    assert_equal('FLEX/AWG5000/la455 design(pcb942_455_b0_w): Created Stackup document - dummy.doc',
                 email.subject)

    second_document.attach(design_reviews(:la455b_placement),
                           document_types(:stackup),
                           @cathy)

    email = @emails.pop
    assert_equal('FLEX/AWG5000/la455 design(pcb942_455_b0_w): Updated Stackup document - stackup.doc',
                 email.subject)

  end
  

end
