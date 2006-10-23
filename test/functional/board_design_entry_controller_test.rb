require File.dirname(__FILE__) + '/../test_helper'
require 'board_design_entry_controller'

# Re-raise errors caught by the controller.
class BoardDesignEntryController; def rescue_action(e) raise e end; end

class BoardDesignEntryControllerTest < Test::Unit::TestCase
  def setup
    @controller = BoardDesignEntryController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @emails     = ActionMailer::Base.deliveries
    @emails.clear
  end
  
  fixtures(:board_design_entries,
           :board_design_entry_users,
           :boards,
           :design_directories,
           :divisions,
           :documents,
           :incoming_directories,
           :locations,
           :platforms,
           :prefixes,
           :product_types,
           :projects,
           :revisions,
           :users)


  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the originator_list method
  # from the Board Design Entry class
  #
  ######################################################################
  #
  def test_lists

    # Try listing without being logged in - it should bounce to
    # the tracker index.
    post(:originator_list)
    assert_redirected_to(:controller => 'tracker',
		                 :action     => 'index')
    assert_equal(Pcbtr::PCBTR_BASE_URL + 'board_design_entry/originator_list' +
                 ' - unavailable unless logged in.', 
                 flash['notice'])

    # Try listing from an account that does not have any
    # entries and verify that the list is empty.
    set_user(users(:cathy_m).id, 'Designer')
    post(:originator_list)

    assert_response(200)
    
    assert_equal(0, assigns(:board_design_entries).size)

    # Try listing from an account that does have an
    # entry and verify that the list has the correct
    # number of entries.
    set_user(users(:lee_s).id, 'HWENG')
    post(:originator_list)
    
    assert_response(200)
    
    board_design_list = assigns(:board_design_entries)
    assert_equal(1, board_design_list.size)

    #Verify that the list entry is correct.
    assert_equal('la021c', board_design_list[0].design_name)

    # Try another user and verify that the list has the 
    # correct number of entries and that the entry is correct.
    set_user(users(:john_j).id, 'HWENG')
    post(:originator_list)
    
    assert_response(200)
    
    board_design_list = assigns(:board_design_entries)
    assert_equal(4, board_design_list.size)

    #Verify that the list entries are correct.
    assert_equal('mx008b4',            board_design_list[0].design_name)
    assert_equal('mx008b4_ecoP123456', board_design_list[1].design_name)
    
    # The process list should show all of the entries.
    set_user(users(:cathy_m).id, 'Input Gate')
    post(:processor_list)

    assert_response(200)
    
    assert_equal(6, assigns(:board_design_entries).size)

  end
  
  
  ######################################################################
  #
  # test_delete
  #
  # Description:
  # This method does the functional testing of the originator and
  # processor delete functions.
  #
  ######################################################################
  #
  def test_create_entry
  
    post(:new_entry)
    
    params = assigns(:params)
    assert_equal("#{Pcbtr::PCBTR_BASE_URL}#{params[:controller]}/#{params[:action]} - " +
                 "unavailable unless logged in.",
                 flash['notice'])
               
    set_user(users(:lee_s).id, 'HWENG')

    post(:get_design_id)
    
    new_entry = assigns(:board_design_entry)
    assert_equal('new',    new_entry.entry_type)
    assert_equal(6,        assigns(:prefix_list).size)
    assert_equal(7,        assigns(:revision_list).size)
    assert_equal('adding', assigns(:user_action))
    assert_equal('true',   assigns(:new_entry))
    
    post(:create_board_design_entry, 
         :board_design_entry => { :prefix_id => '',
                                  :number    => '434' })

    assert_template('get_design_id')
    assert_equal("The following information must be provided in order to proceed <br />" +
                 "<ul>  <li>PCB Mnemonic</li></ul>",
                 flash['notice'])
                 
    assert_equal('434', assigns(:board_design_entry).number)
    assert_equal('new', assigns(:board_design_entry).entry_type)
    assert_equal(6,        assigns(:prefix_list).size)
    assert_equal(7,        assigns(:revision_list).size)
    assert_equal('adding', assigns(:user_action))
    assert_equal('true',   assigns(:new_entry))

    post(:create_board_design_entry, 
         :board_design_entry => { :prefix_id => '',
                                  :number    => '43a' })

    assert_template('get_design_id')
    assert_equal("The following information must be provided in order to proceed <br />" +
                 "<ul>  <li>PCB Mnemonic</li>" +
                 "  <li>Number (must be 3 digits)</li></ul>",
                 flash['notice'])

    assert_equal('43a', assigns(:board_design_entry).number)
    assert_equal('new', assigns(:board_design_entry).entry_type)
    assert_equal(6,        assigns(:prefix_list).size)
    assert_equal(7,        assigns(:revision_list).size)
    assert_equal('adding', assigns(:user_action))
    assert_equal('true',   assigns(:new_entry))
    
    post(:create_board_design_entry, 
         :board_design_entry => { :prefix_id => '1',
                                  :number    => '437' })

    new_entry = assigns(:board_design_entry)
    assert_equal("The design entry has been stored in the database",
                 flash['notice'])
    assert_equal('mx437', new_entry.design)
    assert_equal(8,       new_entry.board_design_entry_users.size)
    assert_equal(0,       new_entry.platform_id)
    assert_equal(0,       new_entry.project_id)
    assert_equal('',      new_entry.description)
    assert_equal(10,      BoardDesignEntryUser.find_all.size)


    post(:create_board_design_entry, 
         :board_design_entry => { :prefix_id => '6',
                                  :number    => '455' })

    new_entry = assigns(:board_design_entry)
    assert_equal("The design entry has been stored in the database",
                 flash['notice'])
    delete_entry = new_entry.dup
    assert_equal('la455',        new_entry.design)
    assert_equal(8,              new_entry.board_design_entry_users.size)
    assert_equal(2,              new_entry.platform_id)
    assert_equal(2,              new_entry.project_id)
    assert_equal('la455 design', new_entry.description)
    assert_equal(18,             BoardDesignEntryUser.find_all.size)
    assert_redirected_to(:action      => 'new_entry',
                         :id          => new_entry.id,
                         :user_action => 'adding')
    check_id = new_entry.id

    follow_redirect
        
    assert_equal('adding', assigns(:user_action))
    new_entry = assigns(:board_design_entry)
    assert_equal('la455',        new_entry.design)
    assert_equal(8,              new_entry.board_design_entry_users.size)
    assert_equal(2,              new_entry.platform_id)
    assert_equal(2,              new_entry.project_id)
    assert_equal('la455 design', new_entry.description)
    assert_equal('new',          new_entry.entry_type)
    assert_equal(check_id,       new_entry.id)
    assert_response(:success)
    
    assert_equal(2,  assigns(:design_dir_list).size)
    assert_equal(2,  assigns(:division_list).size)
    assert_equal(2,  assigns(:incoming_dir_list).size)
    assert_equal(2,  assigns(:location_list).size)
    assert_equal(5,  assigns(:platform_list).size)
    assert_equal(6,  assigns(:prefix_list).size)
    assert_equal(3,  assigns(:product_type_list).size)
    assert_equal(14, assigns(:project_list).size)
    assert_equal(7,  assigns(:revision_list).size)

    assert_equal(8, BoardDesignEntry.find_all.size)
    assert_equal(3, BoardDesignEntry.find_all_by_originator_id(session[:user].id).size)


    bde = { :id              => new_entry.id,
            :description     => '',
            :division_id     => '',
            :entry_type      => '',
            :location_id     => '',
            :number          => '',
            :platform_id     => '',
            :prefix_id       => '',
            :product_type_id => '',
            :project_id      => '',
            :revision_id     => ''}
           
    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')
                                  
    assert_equal("The following information must be provided in order to proceed <br />" +
                 "<ul>  <li>Board Description</li>  <li>Division</li>  "                 +
                 "<li>Location</li>  <li>PCB Mnemonic</li>  <li>Platform</li>  "         +
                 "<li>Product Type</li>  <li>Project</li>  <li>Revision</li>  "                                 +
                 "<li>Number (must be 3 digits)</li></ul>",
                 flash['notice'])
    assert_template('new_entry')
    assert_equal(2,  assigns(:design_dir_list).size)
    assert_equal(2,  assigns(:division_list).size)
    assert_equal(2,  assigns(:incoming_dir_list).size)
    assert_equal(2,  assigns(:location_list).size)
    assert_equal(5,  assigns(:platform_list).size)
    assert_equal(6,  assigns(:prefix_list).size)
    assert_equal(3,  assigns(:product_type_list).size)
    assert_equal(14, assigns(:project_list).size)
    assert_equal(7,  assigns(:revision_list).size)

    returned_bde = assigns(:board_design_entry)
    bde.each { |k,v| assert_equal("#{k}->#{v}", "#{k}->#{returned_bde[k]}") }
    assert(assigns(:new_entry))
    assert_equal('adding', assigns(:user_action))

    bde = { :id              => new_entry.id,
            :description     => '',
            :division_id     => '1',
            :entry_type      => 'new',
            :location_id     => '1',
            :number          => '234',
            :platform_id     => '2',
            :prefix_id       => '2',
            :product_type_id => '2',
            :project_id      => '3',
            :revision_id     => '2'}

    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')
                                  
    assert_equal("The following information must be provided in order to proceed <br />" +
                 "<ul>  <li>Board Description</li></ul>",
                 flash['notice'])
    assert_template('new_entry')
    assert_equal(2,  assigns(:design_dir_list).size)
    assert_equal(2,  assigns(:division_list).size)
    assert_equal(2,  assigns(:incoming_dir_list).size)
    assert_equal(2,  assigns(:location_list).size)
    assert_equal(5,  assigns(:platform_list).size)
    assert_equal(6,  assigns(:prefix_list).size)
    assert_equal(3,  assigns(:product_type_list).size)
    assert_equal(14, assigns(:project_list).size)
    assert_equal(7,  assigns(:revision_list).size)

    returned_bde = assigns(:board_design_entry)
    bde.each { |k,v| assert_equal("#{k}->#{v}", "#{k}->#{returned_bde[k]}") }
    assert(assigns(:new_entry))
    assert_equal('adding', assigns(:user_action))
                 
    bde[:description] = 'Entry Description'
    bde[:division_id] = ''

    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')
                                  
    assert_equal("The following information must be provided in order to proceed <br />" +
                 "<ul>  <li>Division</li></ul>",
                 flash['notice'])
    assert_template('new_entry')
    assert_equal(2,  assigns(:design_dir_list).size)
    assert_equal(2,  assigns(:division_list).size)
    assert_equal(2,  assigns(:incoming_dir_list).size)
    assert_equal(2,  assigns(:location_list).size)
    assert_equal(5,  assigns(:platform_list).size)
    assert_equal(6,  assigns(:prefix_list).size)
    assert_equal(3,  assigns(:product_type_list).size)
    assert_equal(14, assigns(:project_list).size)
    assert_equal(7,  assigns(:revision_list).size)

    returned_bde = assigns(:board_design_entry)
    bde.each { |k,v| assert_equal("#{k}->#{v}", "#{k}->#{returned_bde[k]}") }
    assert(assigns(:new_entry))
    assert_equal('adding', assigns(:user_action))

    bde[:division_id] = '1'
    bde[:location_id] = ''

    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')
                                  
    assert_equal("The following information must be provided in order to proceed <br />" +
                 "<ul>  <li>Location</li></ul>",
                 flash['notice'])
    assert_template('new_entry')
    assert_equal(2,  assigns(:design_dir_list).size)
    assert_equal(2,  assigns(:division_list).size)
    assert_equal(2,  assigns(:incoming_dir_list).size)
    assert_equal(2,  assigns(:location_list).size)
    assert_equal(5,  assigns(:platform_list).size)
    assert_equal(6,  assigns(:prefix_list).size)
    assert_equal(3,  assigns(:product_type_list).size)
    assert_equal(14, assigns(:project_list).size)
    assert_equal(7,  assigns(:revision_list).size)

    returned_bde = assigns(:board_design_entry)
    bde.each { |k,v| assert_equal("#{k}->#{v}", "#{k}->#{returned_bde[k]}") }
    assert(assigns(:new_entry))
    assert_equal('adding', assigns(:user_action))

    bde[:location_id] = '1'
    bde[:platform_id]  = ''

    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')
                                  
    assert_equal("The following information must be provided in order to proceed <br />" +
                 "<ul>  <li>Platform</li></ul>",
                 flash['notice'])
    assert_template('new_entry')
    assert_equal(2,  assigns(:design_dir_list).size)
    assert_equal(2,  assigns(:division_list).size)
    assert_equal(2,  assigns(:incoming_dir_list).size)
    assert_equal(2,  assigns(:location_list).size)
    assert_equal(5,  assigns(:platform_list).size)
    assert_equal(6,  assigns(:prefix_list).size)
    assert_equal(3,  assigns(:product_type_list).size)
    assert_equal(14, assigns(:project_list).size)
    assert_equal(7,  assigns(:revision_list).size)

    returned_bde = assigns(:board_design_entry)
    bde.each { |k,v| assert_equal("#{k}->#{v}", "#{k}->#{returned_bde[k]}") }
    assert(assigns(:new_entry))
    assert_equal('adding', assigns(:user_action))

    bde[:platform_id]  = '2'
    bde[:prefix_id]    = ''

    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')
                                  
    assert_equal("The following information must be provided in order to proceed <br />" +
                 "<ul>  <li>PCB Mnemonic</li></ul>",
                 flash['notice'])
    assert_template('new_entry')
    assert_equal(2,  assigns(:design_dir_list).size)
    assert_equal(2,  assigns(:division_list).size)
    assert_equal(2,  assigns(:incoming_dir_list).size)
    assert_equal(2,  assigns(:location_list).size)
    assert_equal(5,  assigns(:platform_list).size)
    assert_equal(6,  assigns(:prefix_list).size)
    assert_equal(3,  assigns(:product_type_list).size)
    assert_equal(14, assigns(:project_list).size)
    assert_equal(7,  assigns(:revision_list).size)

    returned_bde = assigns(:board_design_entry)
    bde.each { |k,v| assert_equal("#{k}->#{v}", "#{k}->#{returned_bde[k]}") }
    assert(assigns(:new_entry))
    assert_equal('adding', assigns(:user_action))

    bde[:prefix_id]       = '2'
    bde[:product_type_id] = ''

    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')
                                  
    assert_equal("The following information must be provided in order to proceed <br />" +
                 "<ul>  <li>Product Type</li></ul>",
                 flash['notice'])
    assert_template('new_entry')
    assert_equal(2,  assigns(:design_dir_list).size)
    assert_equal(2,  assigns(:division_list).size)
    assert_equal(2,  assigns(:incoming_dir_list).size)
    assert_equal(2,  assigns(:location_list).size)
    assert_equal(5,  assigns(:platform_list).size)
    assert_equal(6,  assigns(:prefix_list).size)
    assert_equal(3,  assigns(:product_type_list).size)
    assert_equal(14, assigns(:project_list).size)
    assert_equal(7,  assigns(:revision_list).size)

    returned_bde = assigns(:board_design_entry)
    bde.each { |k,v| assert_equal("#{k}->#{v}", "#{k}->#{returned_bde[k]}") }
    assert(assigns(:new_entry))
    assert_equal('adding', assigns(:user_action))

    bde[:product_type_id] = '2'
    bde[:project_id]      = ''

    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')
                                  
    assert_equal("The following information must be provided in order to proceed <br />" +
                 "<ul>  <li>Project</li></ul>",
                 flash['notice'])
    assert_template('new_entry')
    assert_equal(2,  assigns(:design_dir_list).size)
    assert_equal(2,  assigns(:division_list).size)
    assert_equal(2,  assigns(:incoming_dir_list).size)
    assert_equal(2,  assigns(:location_list).size)
    assert_equal(5,  assigns(:platform_list).size)
    assert_equal(6,  assigns(:prefix_list).size)
    assert_equal(3,  assigns(:product_type_list).size)
    assert_equal(14, assigns(:project_list).size)
    assert_equal(7,  assigns(:revision_list).size)

    returned_bde = assigns(:board_design_entry)
    bde.each { |k,v| assert_equal("#{k}->#{v}", "#{k}->#{returned_bde[k]}") }
    assert(assigns(:new_entry))
    assert_equal('adding', assigns(:user_action))

    bde[:project_id]  = '3'
    bde[:revision_id] = ''

    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')
                                  
    assert_equal("The following information must be provided in order to proceed <br />" +
                 "<ul>  <li>Revision</li></ul>",
                 flash['notice'])
    assert_template('new_entry')
    assert_equal(2,  assigns(:design_dir_list).size)
    assert_equal(2,  assigns(:division_list).size)
    assert_equal(2,  assigns(:incoming_dir_list).size)
    assert_equal(2,  assigns(:location_list).size)
    assert_equal(5,  assigns(:platform_list).size)
    assert_equal(6,  assigns(:prefix_list).size)
    assert_equal(3,  assigns(:product_type_list).size)
    assert_equal(14, assigns(:project_list).size)
    assert_equal(7,  assigns(:revision_list).size)

    returned_bde = assigns(:board_design_entry)
    bde.each { |k,v| assert_equal("#{k}->#{v}", "#{k}->#{returned_bde[k]}") }
    assert(assigns(:new_entry))
    assert_equal('adding', assigns(:user_action))

    bde[:revision_id] = '3'
    bde[:number]      = '23'

    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')
                                  
    assert_equal("The following information must be provided in order to proceed <br />" +
                 "<ul>  <li>Number (must be 3 digits)</li></ul>",
                 flash['notice'])
    assert_template('new_entry')
    assert_equal(2,  assigns(:design_dir_list).size)
    assert_equal(2,  assigns(:division_list).size)
    assert_equal(2,  assigns(:incoming_dir_list).size)
    assert_equal(2,  assigns(:location_list).size)
    assert_equal(5,  assigns(:platform_list).size)
    assert_equal(6,  assigns(:prefix_list).size)
    assert_equal(3,  assigns(:product_type_list).size)
    assert_equal(14, assigns(:project_list).size)
    assert_equal(7,  assigns(:revision_list).size)

    returned_bde = assigns(:board_design_entry)
    bde.each { |k,v| assert_equal("#{k}->#{v}", "#{k}->#{returned_bde[k]}") }
    assert(assigns(:new_entry))
    assert_equal('adding', assigns(:user_action))
    
    originator = User.find(session[:user].id)
    assert_equal("Lee Schaff", originator.name)
    assert_equal(0,            originator.location_id)
    assert_equal(0,            session[:user].location_id)
    assert_equal(0,            originator.division_id)
    assert_equal(0,            session[:user].division_id)

    bde = { :description      => 'Entry Description',
            :division_id      => '1',
            :entry_type       => 'new',
            :location_id      => '1',
            :platform_id      => '2',
            :prefix_id        => '2',
            :product_type_id  => '2',
            :project_id       => '3',
            :revision_id      => '3',
            :number           => '541' }
            
    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')

    assert_equal("Entry bt541c has been updated", flash['notice'])
    
    originator.reload
    assert_equal("Lee Schaff", originator.name)
    assert_equal(1,            originator.location_id)
    assert_equal(1,            session[:user].location_id)
    assert_equal(1,            originator.division_id)
    assert_equal(1,            session[:user].division_id)
    
    assert_redirected_to(:action      => 'design_constraints',
                         :id          => new_entry.id,
                         :user_action => 'adding')
                         
                         
    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'updating',
         :viewer             => '')

    assert_equal("Entry bt541c has been updated", flash['notice'])
    
    assert_redirected_to(:action      => 'edit_entry',
                         :id          => new_entry.id,
                         :user_action => 'updating')

    assert_equal(8, BoardDesignEntry.find_all.size)
    assert_equal(3, BoardDesignEntry.find_all_by_originator_id(session[:user].id).size)
    
    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')

    assert_equal("No update was made - the entry already exists",
                 flash['notice'])
    assert_redirected_to(:action      => 'edit_entry',
                         :id          => new_entry.id,
                         :user_action => 'adding',
                         :viewer      => '')

    bde = { :description      => 'Entry Description',
            :division_id      => '1',
            :entry_type       => 'new',
            :location_id      => '1',
            :platform_id      => '2',
            :prefix_id        => '6',
            :product_type_id  => '2',
            :project_id       => '3',
            :revision_id      => '2',
            :number           => '453' }

    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')

    assert_equal("la453b duplicates an existing design - the database was not updated",
                 flash['notice'])
    assert_redirected_to(:action      => 'edit_entry',
                         :id          => new_entry.id,
                         :user_action => 'adding',
                         :viewer      => '')
                         
    bde = { :description      => 'Entry Description',
            :division_id      => '1',
            :entry_type       => 'new',
            :location_id      => '1',
            :platform_id      => '2',
            :prefix_id        => '1',
            :product_type_id  => '2',
            :project_id       => '3',
            :revision_id      => '1',
            :number           => '700' }
    
    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')

    assert_equal("mx700a not created - a newer revision exists in the system",
                 flash['notice'])
    assert_redirected_to(:action      => 'edit_entry',
                         :id          => new_entry.id,
                         :user_action => 'adding',
                         :viewer      => '')
    
    bde[:entry_type]       = 'dot_rev'
    bde[:numeric_revision] = ''
    
    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')

    assert_equal("Entry not created - a numeric revision must be specified for a Dot Rev",
                 flash['notice'])
    assert_redirected_to(:action      => 'edit_entry',
                         :id          => new_entry.id,
                         :user_action => 'adding',
                         :viewer      => '')

    bde[:numeric_revision] = '4'
    
    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')

    assert_equal("Entry mx700a4 has been updated",
                 flash['notice'])
    assert_redirected_to(:action      => 'design_constraints',
                         :id          => new_entry.id,
                         :user_action => 'adding')
    

    bde[:prefix_id]   = '6'
    bde[:number]      = '453'
    bde[:entry_type]  = 'date_code'
    bde[:revision_id] = '2'
    bde[:eco_number]  = '2'
    
    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')

    assert_equal("la453b4_eco2 duplicates an existing design - the database was not updated",
                 flash['notice'])
    assert_redirected_to(:action      => 'edit_entry',
                         :id          => new_entry.id,
                         :user_action => 'adding',
                         :viewer      => '')

    bde[:eco_number]  = ''
    
    post(:update_entry,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding',
         :viewer             => '')

    assert_equal("Entry not created - an ECO number must be specified for a Date Code entry",
                 flash['notice'])
    assert_redirected_to(:action      => 'edit_entry',
                         :id          => new_entry.id,
                         :user_action => 'adding',
                         :viewer      => '')
            
                         
    post(:view_entry, :id => new_entry.id, :return => 'test')
    assert_equal(new_entry.id, assigns(:board_design_entry).id)
    assert_equal('test',       assigns(:return))
    assert_equal('Lee Schaff', assigns(:originator).name)
    assert_equal(1,            assigns(:managers).size)
    assert_equal(7,           assigns(:reviewers).size)
    
    
    assert_equal('new', new_entry.entry_type)
    post(:entry_type_selected, 
         :id   => new_entry.id,
         :type => 'dot_rev')
    assert_equal(new_entry.id, assigns(:board_design_entry).id)
    assert_equal('dot_rev',    assigns(:board_design_entry).entry_type)
    
    
    assert_equal(0, new_entry.make_from)
    post(:process_make_from, 
         :id    => new_entry.id,
         :value => 'yes')
    assert_equal(new_entry.id, assigns(:board_design_entry).id)
    assert(assigns(:board_design_entry).make_from?)

    post(:process_make_from, 
         :id    => new_entry.id,
         :value => 'no')
    assert_equal(0, assigns(:board_design_entry).make_from)


    assert_equal(0, new_entry.lead_free_devices)
    post(:process_lead_free, 
         :id    => new_entry.id,
         :value => 'yes')
    assert_equal(new_entry.id, assigns(:board_design_entry).id)
    assert(assigns(:board_design_entry).lead_free_devices?)

    post(:process_lead_free, 
         :id    => new_entry.id,
         :value => 'no')
    assert_equal(0, assigns(:board_design_entry).lead_free_devices)
    
    
    post(:entry_input_checklist, :id => new_entry.id)
    assert_equal(new_entry.id, assigns(:board_design_entry).id)
    
    
    post(:set_review_team, :id => new_entry.id, :user_action => 'test')
    assert_equal(new_entry.id, assigns(:board_design_entry).id)
    assert_equal('test',       assigns(:user_action))
    assert_equal(5,            assigns(:reviewers).size)    


    post(:set_management_team, :id => new_entry.id, :user_action => 'testing')
    assert_equal(new_entry.id, assigns(:board_design_entry).id)
    assert_equal('testing',    assigns(:user_action))
    assert_equal(1,            assigns(:managers).size)    
  
    hweng_role = Role.find_by_name("HWENG")
    
    post(:set_team_member,
         :bde_id  => new_entry.id,
         :role_id => hweng_role.id,
         :id      => session[:user].id)

    hweng_reviewer = new_entry.board_design_entry_users(true).detect { |bde_u|
                       bde_u.role_id == hweng_role.id }
    assert_equal(session[:user].id, hweng_reviewer.user_id)
    assert_equal(hweng_role.id,     hweng_reviewer.role_id)
    assert_equal(new_entry.id,      hweng_reviewer.board_design_entry_id)
    assert_equal(1,                 hweng_reviewer.required)

    post(:set_role_required,
         :bde_id    => new_entry.id,
         :role_id   => hweng_role.id,
         :required  => 'not_required')

    hweng_reviewer = new_entry.board_design_entry_users(true).detect { |bde_u|
                       bde_u.role_id == hweng_role.id }
    assert_equal(session[:user].id, hweng_reviewer.user_id)
    assert_equal(hweng_role.id,     hweng_reviewer.role_id)
    assert_equal(new_entry.id,      hweng_reviewer.board_design_entry_id)
    assert_equal(0,                 hweng_reviewer.required)

    post(:set_role_required,
         :bde_id    => new_entry.id,
         :role_id   => hweng_role.id,
         :required  => 'required')

    hweng_reviewer = new_entry.board_design_entry_users(true).detect { |bde_u|
                       bde_u.role_id == hweng_role.id }
    assert_equal(1, hweng_reviewer.required)

    assert_equal(0, new_entry.constraints_complete)
    
    post(:toggle_processor_checks,
         :id    => new_entry.id,
         :field => 'constraints_complete')
    
    new_entry.reload
    assert_equal(1, new_entry.constraints_complete)

    post(:toggle_processor_checks,
         :id    => new_entry.id,
         :field => 'constraints_complete')
    
    new_entry.reload
    assert_equal(0, new_entry.constraints_complete)
    
    
    post(:edit_entry, 
         :id          => new_entry.id,
         :user_action => 'update',
         :viewer      => 'testing')
    assert_equal(new_entry.id, assigns(:board_design_entry).id)
    assert_equal('testing',    assigns(:viewer))
    assert_equal(2,            assigns(:design_dir_list).size)
    assert_equal(2,            assigns(:division_list).size)
    assert_equal(2,            assigns(:incoming_dir_list).size)
    assert_equal(2,            assigns(:location_list).size)
    assert_equal(5,            assigns(:platform_list).size)
    assert_equal(6,            assigns(:prefix_list).size)
    assert_equal(3,            assigns(:product_type_list).size)
    assert_equal(14,           assigns(:project_list).size)
    assert_equal(7,            assigns(:revision_list).size)
    assert_template('new_entry')
    
    
    post(:design_constraints,
         :id          => new_entry.id,
         :user_action => 'adding')
    assert_equal(new_entry.id, assigns(:board_design_entry).id)
    assert_equal('adding',     assigns(:user_action))


    post(:view_originator_comments,
         :id          => new_entry.id,
         :user_action => 'adding')
    assert_equal(new_entry.id, assigns(:board_design_entry).id)
    assert_equal('adding',     assigns(:user_action))
    
    
    bde[:originator_comments] = 'Test Originator Comments'
    assert_equal('', assigns(:board_design_entry).originator_comments)
    
    post(:submit_originator_comments,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'adding')
         
    new_entry.reload
    assert_equal('Test Originator Comments', new_entry.originator_comments)
    assert_redirected_to(:action => 'originator_list')
    
    bde[:originator_comments] = 'Updated originator comments'

    post(:submit_originator_comments,
         :id                 => new_entry.id,
         :board_design_entry => bde,
         :user_action        => 'updating')
 
    new_entry.reload
    assert_equal('Updated originator comments', new_entry.originator_comments)
    assert_redirected_to(:action => 'view_entry', :id => new_entry.id.to_s)


    post(:view_processor_comments,
         :id          => new_entry.id,
         :user_action => 'updating')
    assert_equal(new_entry.id, assigns(:board_design_entry).id)
    assert_equal('updating',   assigns(:user_action))


    bde[:input_gate_comments] = 'Test Processor Comments'
    assert_equal('', assigns(:board_design_entry).input_gate_comments)
    
    post(:submit_processor_comments,
         :id                 => new_entry.id,
         :board_design_entry => bde)
         
    new_entry.reload
    assert_equal('Test Processor Comments', new_entry.input_gate_comments)
    assert_redirected_to(:action => "view_entry",
                         :id     => new_entry.id.to_s,
                         :viewer => "processor")
                         
         
    assert(new_entry.originated?)
    
    post(:submit, :id => new_entry.id)
    
    new_entry.reload
    assert(new_entry.submitted?)
    assert_redirected_to(:action => 'originator_list')
    assert_equal(1, @emails.size)
    email = @emails[0]
    assert_equal('The mx700a4 has been submitted for entry to PCB Design', email.subject)
    
    new_entry.originated
    new_entry.reload
    assert(new_entry.originated?)
    
    
    test_data = {
      'differential_pairs' => {
        :label        => 'Differential Pairs:',
        :checkbox_var => :diff_pair,
        :div_id       => :diff_pairs
      },
      'controlled_impedance' => {
        :label        => 'Controlled Impedance:',
        :checkbox_var => :controlled_imp,
        :div_id       => :controlled_impedance
      },
      'scheduled_nets' => {
        :label        => 'Scheduled Nets:',
        :checkbox_var => :sched_nets,
        :div_id       => :scheduled_nets
      },
      'propagation_delay' => {
        :label        => 'Propagation Delay:',
        :checkbox_var => :prop_delay,
        :div_id       => :prop_delay
      },
      'matched_propagation_delay' => {
        :label        => 'Matched Propagation Delay:',
        :checkbox_var => :matched_prop_delay,
        :div_id       => :matched_prop_delay
      }
    }
    
    test_data.each { |field, test_data|

      # Check the initial value.
      assert_equal(false, new_entry.send(field+'?'))
      
      post(:update_yes_no,
           :id    => new_entry.id,
           :field => field,
           :value => 'Yes')
           
      assert_equal(new_entry.id,             assigns(:board_design_entry).id)
      assert_equal(field,                    assigns(:field))
      assert_equal('No',                     assigns(:new_value))
      assert_equal('Yes',                    assigns(:current_value))
      assert_equal(test_data[:label],        assigns(:label))
      assert_equal(test_data[:checkbox_var], assigns(:checkbox_var))
      assert_equal(test_data[:div_id],       assigns(:div_id))
           
      # Check the updated value.
      new_entry.reload
      assert_equal(true, new_entry.send(field+'?'))
    
      post(:update_yes_no,
           :id    => new_entry.id,
           :field => field,
           :value => 'No')
           
      # Check the updated value.
      new_entry.reload
      assert_equal(false, new_entry.send(field+'?'))
    }


    assert_equal(19, BoardDesignEntryUser.find_all.size)
    assert_equal(8,  BoardDesignEntry.find_all.size)
    assert_equal(3,  BoardDesignEntry.find_all_by_originator_id(session[:user].id).size)
    
    post(:destroy, :id => new_entry.id)

    assert_equal(7,  BoardDesignEntry.find_all.size)
    assert_equal(2,  BoardDesignEntry.find_all_by_originator_id(session[:user].id).size)
    assert_equal(10, BoardDesignEntryUser.find_all.size)
    
  end
  
  
  ######################################################################
  #
  # test_delete
  #
  # Description:
  # This method does the functional testing of the originator and
  # processor delete functions.
  #
  ######################################################################
  #
  def test_delete

    # Verify the number of Board Design Entries to start.
    board_design_entries = BoardDesignEntry.find_all
    assert_equal(6, board_design_entries.size)
  
    # Try listing from an account that does have an
    # entry and verify that the list has the correct
    # number of entries.
    set_user(users(:lee_s).id, 'HWENG')
    post(:originator_list)
    
    assert_response(200)
    
    board_design_list = assigns(:board_design_entries)
    assert_equal(1, board_design_list.size)
    
    assert_equal(4, Document.find_all.size)

    post(:destroy, :id => board_design_list[0].id)

    assert_equal(1, Document.find_all.size)

    post(:originator_list)
    
    assert_response(200)
    
    board_design_list = assigns(:board_design_entries)
    assert_equal(0, board_design_list.size)

    # Verify the number of Board Design Entries after deleting.
    board_design_entries = BoardDesignEntry.find_all
    assert_equal(5, board_design_entries.size)
  
    # Verify the number of entries seen by the processor.
    set_user(users(:cathy_m).id, 'Input Gate')
    post(:processor_list)

    assert_response(200)
    
    assert_equal(5, assigns(:board_design_entries).size)

  end
  
  
  ######################################################################
  #
  # test_processor_functions
  #
  # Description:
  # This method does the functional testing of the functions available 
  # to the PCB Input Gate (processor).
  #
  ######################################################################
  #
  def test_processor_functions
  
    set_user(users(:cathy_m).id, 'Designer')
    
    la021c_entry = BoardDesignEntry.find(board_design_entries(:la021c).id)

    post(:send_back, :id => la021c_entry.id)
    assert_equal(la021c_entry.id, assigns(:board_design_entry).id)
    
    la021c_entry.submitted
    la021c_entry.reload
    assert_equal(true, la021c_entry.submitted?)
    
    la021c_entry.input_gate_comments = "Return to Sender!"
    post(:return_entry_to_originator,
         :id                 => la021c_entry.id,
         :board_design_entry => la021c_entry)
         
    la021c_entry_1 = BoardDesignEntry.find(board_design_entries(:la021c).id)
    assert_equal(true, la021c_entry_1.originated?)
    assert_equal('Return to Sender!', la021c_entry_1.input_gate_comments)
    assert_redirected_to(:action => 'processor_list')
  
  end
  
  
  ######################################################################
  #
  # test_access
  #
  # Description:
  # This method verifies that users who are not tracker admin do not
  # have access to view/functions that are limited to admins.
  #
  ######################################################################
  #
   def test_entry_update
   
    set_user(users(:cathy_m).id, "Designer")
    post(:processor_list)
    assert_response(200)
  
    set_user(users(:lee_s).id, 'HWENG')

    post(:processor_list)
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal("Access Prohibited", flash['notice'])
    
    post(:send_back)
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal("Access Prohibited", flash['notice'])
    
    post(:return_entry_to_originator)
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    assert_equal("Access Prohibited", flash['notice'])
    
  end
  
  
end
