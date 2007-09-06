require File.dirname(__FILE__) + '/../test_helper'
require 'incoming_directory_controller'

# Re-raise errors caught by the controller.
class IncomingDirectoryController; def rescue_action(e) raise e end; end

class IncomingDirectoryControllerTest < Test::Unit::TestCase
  def setup
    @controller = IncomingDirectoryController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:incoming_directories,
           :users)


  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the incoming_directory class
  #
  ######################################################################
  #
  def test_list

    # Try editing from a non-Admin account.
    # VERIFY: The user is redirected.
    set_non_admin()
    post(:list)

    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try listing from an Admin account
    # VERIFY: The platform list data is retrieved
    set_admin
    post(:list, :page => 1)

    assert_equal(3, assigns(:incoming_directories).size)

  end


  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method does the functional testing of the edit method
  # from the incoming directory class
  #
  ######################################################################
  #
  def test_edit
    
    # Try editing from an Admin account
    set_admin()
    post(:edit, :id => incoming_directories(:board_sj_incoming).id)

    assert_response 200
    assert_equal(incoming_directories(:board_sj_incoming).name, 
                 assigns(:incoming_directory).name)

    assert_raise(ActiveRecord::RecordNotFound) {
      post(:edit, :id => 1000000)
    }

  end


  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method does the functional testing of the update method
  # from the Incoming Directory Controller class
  #
  ######################################################################
  #
  def test_update

    incoming_directory = IncomingDirectory.find(incoming_directories(:board_ah_incoming).id)
    incoming_directory.name = 'Yugo'

    set_admin()
    get(:update, :incoming_directory => incoming_directory.attributes)

    assert_equal('Incoming Directory was successfully updated.', flash['notice'])
    assert_redirected_to(:action => 'edit', :id => incoming_directory.id)
    incoming_directory.reload
    assert_equal('Yugo', incoming_directory.name)
    
  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the Incoming Directory Controller class
  #
  ######################################################################
  #
  def test_create

    # Verify that a incoming directory can be added.  The number of 
    # incoming directories will increase by one.
    incoming_directory_count = IncomingDirectory.count
    assert_equal(2, IncomingDirectory.find_all_by_active(1).size)

    new_incoming_directory = { 'active' => '1', 'name' => 'Thunderbird' }

    set_admin()
    post(:create, :new_incoming_directory => new_incoming_directory)

    incoming_directory_count += 1
    assert_equal(incoming_directory_count, IncomingDirectory.count)
    assert_equal(3,                        IncomingDirectory.find_all_by_active(1).size)
    assert_equal("Incoming Directory #{new_incoming_directory['name']} added", 
                 flash['notice'])
    assert_redirected_to(:action => 'list')
    
    # Try to add a second incoming directory with the same name.
    # It should not get added.
    post(:create, :new_incoming_directory => new_incoming_directory)

    assert_equal(incoming_directory_count, IncomingDirectory.count)
    assert_equal(3,                        IncomingDirectory.find_all_by_active(1).size)
    assert_equal("Name has already been taken", flash['notice'])
    assert_redirected_to(:action => 'add')


    # Try to add a incoming directroy withhout a name.
    # It should not get added.
    post(:create, :new_incoming_directory => { 'active' => '1', 'name' => '' })
    
    assert_equal(incoming_directory_count, IncomingDirectory.count)
    assert_equal(3,                        IncomingDirectory.find_all_by_active(1).size)
    assert_equal("Name can't be blank", flash['notice'])
    assert_redirected_to(:action => 'add')

  end


end
