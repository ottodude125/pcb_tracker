########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: document_type_controller_test.rb
#
# This file contains the functional tests for the document type
# controller
#
# $Id$
#
########################################################################
#
require File.expand_path( "../../test_helper", __FILE__ )
require 'document_type_controller'

# Re-raise errors caught by the controller.
class DocumentTypeController; def rescue_action(e) raise e end; end

class DocumentTypeControllerTest < ActionController::TestCase
  def setup
    @controller = DocumentTypeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:document_types,
           :users)


  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the DocumentType class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_list

    # Try listing from a non-Admin account.
    # VERIFY: The user is redirected.
    post :list, {}, rich_designer_session
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    post(:list, { :page => 1 }, cathy_admin_session)
    assert_equal(5, assigns(:document_types).size)
  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the edit method
  # from the DocumentType class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_edit

    stackup = document_types(:stackup)
    get(:edit, { :id => stackup.id }, cathy_admin_session)
    assert_equal(stackup.name, assigns(:document_type).name)
    
  end

  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update method
  # from the DocumentType Controller class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_update

    doc_one = document_types(:doc_one)
    document_type      = DocumentType.find(doc_one.id)
    document_type.name = 'Test'

    get(:update, { :document_type => document_type.attributes }, cathy_admin_session)
    assert_equal('Update recorded', flash['notice'])
    assert_equal('Test',            document_type.name)
    assert_redirected_to(:action => 'edit', :id => document_type.id)
    
  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the DocumentType Controller class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_create

    assert_equal(5, DocumentType.count)

    admin_session     = cathy_admin_session
    new_document_type = { 'active' => '1',
                          'name'   => 'Yankee' }

    post(:create, { :new_document_type => new_document_type }, admin_session)
    assert_equal(6,              DocumentType.count)
    assert_equal("Yankee added", flash['notice'])
    assert_redirected_to :action => 'list'

    post(:create, { :new_document_type => new_document_type }, admin_session)
    assert_equal(6,                                     DocumentType.count)
    #assert_equal("Name already exists in the database", flash['notice'])
    assert_redirected_to :action => 'add'

  end


end
