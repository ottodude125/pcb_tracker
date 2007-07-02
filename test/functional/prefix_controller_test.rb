########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: prefix_controller_test.rb
#
# This file contains the functional tests for the board number prefix
# controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'prefix_controller'

# Re-raise errors caught by the controller.
class PrefixController; def rescue_action(e) raise e end; end

class PrefixControllerTest < Test::Unit::TestCase
  def setup
    @controller = PrefixController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  fixtures(:prefixes,
           :users)
  
  
  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the Prefix class
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

    # Try editing from a non-Admin account.
    # VERIFY: The user is redirected.
    set_non_admin
    post :list

    assert_redirected_to(:controller => 'tracker',
                         :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The project list data is retrieved
    set_admin
    post(:list,
         :page => 1)

    assert_equal(7, assigns(:prefixes).size)

  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the edit method
  # from the Prefix class
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

    set_admin
    mx = prefixes(:mx)
    get(:edit,
        :id => mx.id)

    assert_equal(mx.pcb_mnemonic, assigns(:prefix).pcb_mnemonic)
    
  end

  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update method
  # from the Prefix Controller class
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

    prefix = Prefix.find(prefixes(:av).id)
    prefix.pcb_mnemonic = 'os'

    set_admin
    get(:update,
        :prefix => prefix.attributes)

    assert_equal('Prefix was successfully updated.', flash['notice'])
    assert_redirected_to(:action => 'edit',
                         :id     => prefix.id)
    assert_equal('os', prefix.pcb_mnemonic)
  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the Prefix Controller class
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

    assert_equal(7, Prefix.count)

    new_prefix = {
      'active'       => '1',
      'pcb_mnemonic' => 'nh'
    }

    set_admin
    post(:create,
         :new_prefix => new_prefix)

    assert_equal(8,                 Prefix.count)
    assert_equal("Prefix nh added", flash['notice'])
    assert_redirected_to :action => 'list'

    post(:create,
         :new_prefix => new_prefix)
    assert_equal(8, Prefix.count)
    assert_equal("Pcb mnemonic has already been taken", flash['notice'])
    assert_redirected_to :action => 'add'

  end


end
