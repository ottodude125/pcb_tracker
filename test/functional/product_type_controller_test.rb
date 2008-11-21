########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: product_type_controller_test.rb
#
# This file contains the functional tests for the product type controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'product_type_controller'

# Re-raise errors caught by the controller.
class ProductTypeController; def rescue_action(e) raise e end; end

class ProductTypeControllerTest < Test::Unit::TestCase
  
  def setup
    @controller = ProductTypeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:product_types,
           :users)


  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the ProductType class
  #
  ######################################################################
  #
  def test_list

    # Try editing from a non-Admin account.
    # VERIFY: The user is redirected.
    get :list, {}, rich_designer_session
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The platform list data is retrieved
    get(:list, { :page => 1 }, cathy_admin_session)
    assert_equal(4, assigns(:product_types).size)

  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the edit method
  # from the ProductType class
  #
  ######################################################################
  #
  def test_edit
    
    # Try editing from an Admin account
    admin_session = cathy_admin_session
    get(:edit, { :id => product_types(:production).id }, admin_session)
    assert_response 200
    assert_equal(product_types(:production).name, assigns(:product_type).name)

    assert_raise(ActiveRecord::RecordNotFound) do
      get(:edit, { :id => 1000000 }, admin_session)
    end
 
  end


  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update method
  # from the ProductType Controller class
  #
  ######################################################################
  #
  def test_update

    product_type      = ProductType.find(product_types(:p1_eng).id)
    product_type.name = 'Yugo'

    post(:update,
        { :product_type => product_type.attributes }, 
        cathy_admin_session)
    assert_equal('Product Type was successfully updated.', flash['notice'])
    assert_redirected_to(:action => 'edit', :id => product_type.id)
    update = ProductType.find(product_type.id)
    assert_equal('Yugo', update.name)
  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the ProductType Controller class
  #
  ######################################################################
  #
  def test_create

    # Verify that a product_type can be added.  The number of product_types
    # will increase by one.
    product_type_count = ProductType.count

    new_product_type = { 'active' => '1', 'name'   => 'Thunderbird' }

    admin_session = cathy_admin_session
    
    post(:create, {:new_product_type => new_product_type}, admin_session)
    product_type_count += 1
    assert_equal(product_type_count, ProductType.count)
    assert_equal("Product Type #{new_product_type['name']} added", 
                 flash['notice'])
    assert_redirected_to(:action => 'list')
    
    # Try to add a second platform with the same name.
    # It should not get added.
    post(:create, {:new_product_type => new_product_type}, admin_session)
    assert_equal(product_type_count,            ProductType.count)
    #assert_equal("Name has already been taken", flash['notice'])
    assert_redirected_to(:action => 'add')


    # Try to add a platform withhout a name.
    # It should not get added.
    post(:create, 
         { :new_product_type => { 'active' => '1', 'name' => '' } },
         admin_session)
    assert_equal(product_type_count,    ProductType.count)
    #assert_equal("Name can't be blank", flash['notice'])
    assert_redirected_to(:action => 'add')

  end


end
