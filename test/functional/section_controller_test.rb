require File.expand_path( "../../test_helper", __FILE__ )
require 'section_controller'

# Re-raise errors caught by the controller.
class SectionController; def rescue_action(e) raise e end; end

class SectionControllerTest < ActionController::TestCase
  
  
  def setup
    
    @controller = SectionController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
  end


  fixtures(:checklists,
           :checks,
           :roles_users,
           :roles,
           :sections,
           :subsections,
           :users)


  ######################################################################
  #
  # test_append
  #
  # Description:
  # This method does the functional testing of the append method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_append

    # Try appending without logging in.
    section_01_1 = sections(:section_01_1)
    post(:append, { :id => section_01_1.id }, {})
    
    assert_redirected_to(:controller => 'user', :action => 'login')

    # Try appending from a non-Admin account.
    post(:append, {:id => section_01_1.id}, rich_designer_session)
    
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    #assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try appending from an Admin account
    post(:append, { :id => section_01_1.id }, cathy_admin_session)
    
    assert_response 200
    assert_equal(checklists(:checklist_0_1).id,
                 assigns(:new_section).checklist_id)
  end


  ######################################################################
  #
  # test_append_section
  #
  # Description:
  # This method performs the functional testing of the append_section
  # method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_append_section

    new_section = { 'date_code_check'  => '1',
                    'dot_rev_check'    => '1',
                    'full_review'      => '1',
                    'name'             => 'New Section 01 2 4',
                    'background_color' => '0f0f0f',
                    'url'              => 'www.dogpile.com' }
    section = { 'id' => sections(:section_01_1).id }

    checklist_0_1 = checklists(:checklist_0_1)
    sections = Section.find(:all,
                            :conditions => "checklist_id=#{checklist_0_1.id}")
    assert_equal(4, sections.size)

    post(:append_section,
         { :new_section => new_section, :section => section },
         cathy_admin_session)
    assert_equal('Section appended successfully.', flash['notice'])

    sections = Section.find(:all,
                            :conditions => "checklist_id=#{checklist_0_1.id}",
                            :order      => 'position')
    assert_equal(5, sections.size)

    1.upto(sections.size) { |x| assert_equal((x), sections[x-1][:position])}

    assert_equal(sections(:section_01_1).id, sections[0][:id])
    assert_equal('New Section 01 2 4',       sections[1][:name])
    assert_equal(sections(:section_01_2).id, sections[2][:id])
    assert_equal(sections(:section_01_3).id, sections[3][:id])

  end

  ######################################################################
  #
  # test_destroy
  #
  # Description:
  # This method performs the functional testing of the destroy
  # method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_destroy

    checklist = Checklist.find(subsections(:subsection_01_1_1).checklist.id)
    assert_equal(6, checklist.designer_only_count)
    assert_equal(5, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(3, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(3, checklist.dr_designer_auditor_count)

    @request.session[:user]        = nil
    @request.session[:active_role] = nil
    @request.session[:roles]       = nil

    section_01_1 = sections(:section_01_1)
    
    get(:destroy, { :id => section_01_1.id }, {})
    assert_redirected_to(:controller => 'user', :action => 'login')
    assert_equal('Please log in', flash[:notice])

    get(:destroy, { :id => section_01_1.id }, rich_designer_session)
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    #assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    
    checklist_0_1 = checklists(:checklist_0_1)
    sections = Section.find(:all,
                            :conditions => "checklist_id=#{checklist_0_1.id}",
                            :order      => 'position ASC')
    assert_equal(4, sections.size)
    assert_equal(section_01_1.position,            sections[0].position)
    assert_equal(sections(:section_01_2).position, sections[1].position)
    assert_equal(sections(:section_01_3).position, sections[2].position)

    check_count = 0
    section_01_1.subsections.each { |ss| check_count += ss.checks.size}
    assert_equal(6, check_count)

    get(:destroy, { :id => section_01_1.id }, cathy_admin_session)

    check_count = 0
    section_01_1.subsections.each { |ss| check_count += ss.checks.size}
    assert_equal(0, check_count)

    sections = checklist_0_1.sections
    assert_equal(3, sections.size)
    assert_equal(1, sections[0].position)
    assert_equal(2, sections[1].position)

    checklist.reload
    assert_equal(3, checklist.designer_only_count)
    assert_equal(3, checklist.designer_auditor_count)
    assert_equal(0, checklist.dc_designer_only_count)
    assert_equal(0, checklist.dc_designer_auditor_count)
    assert_equal(0, checklist.dr_designer_only_count)
    assert_equal(0, checklist.dr_designer_auditor_count)

  end

  ######################################################################
  #
  # test_edit
  #
  # Description:
  # This method performs the functional testing of the edit
  # method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_edit

   section_01_1 = sections(:section_01_1)
    # Try editing without logging in.
    post(:edit, { :id => section_01_1.id }, {})
    assert_redirected_to(:controller => 'user', :action => 'login')

    # Try editing from a non-Admin account.
    post(:edit, { :id => section_01_1.id }, rich_designer_session)
    assert_redirected_to(:controller => 'tracker', :action => 'index')
    #assert_equal(Pcbtr::MESSAGES[:admin_only],     flash['notice'])

    admin_session = cathy_admin_session
    # Try editing from an Admin account
    post(:edit, { :id => section_01_1.id }, admin_session)
    assert_response 200
    assert_equal(section_01_1.id, assigns(:section).id)

    assert_raise(ActiveRecord::RecordNotFound) do
      post(:edit, { :id => 32423423 }, admin_session)
    end

end


  ######################################################################
  #
  # test_insert
  #
  # Description:
  # This method performs the functional testing of the insert
  # method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_insert

    # Try inserting from a non-Admin account.
    post(:insert, { :id => sections(:section_01_1).id }, rich_designer_session)
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])

    # Try inserting from an Admin account
    post(:insert, { :id => sections(:section_01_1).id }, cathy_admin_session)
    assert_response 200
    assert_equal(sections(:section_01_1).checklist_id,
                 assigns(:new_section).checklist_id)

  end

  ######################################################################
  #
  # test_insert_section
  #
  # Description:
  # This method performs the functional testing of the insert_section
  # method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_insert_section

    checklist_0_1 = checklists(:checklist_0_1)
    sections = checklist_0_1.sections
    assert_equal(4, sections.size)

    new_section = { 'date_code_check'  => '1',
                    'dot_rev_check'    => '1',
                    'full_review'      => '1',
                    'name'             => 'New Section 01 2 4',
                    'background_color' => '0f0f0f',
                    'url'              => 'www.dogpile.com' }

    post(:insert_section,
         { :new_section => new_section,
           :section     => { 'id' => sections(:section_01_1).id } },
         cathy_admin_session)
    checklist_0_1.reload
    sections = checklist_0_1.sections
    assert_equal(5, sections.size)

    assert_equal('New Section 01 2 4', sections[0].name)
    assert_equal(sections(:section_01_1).name,   sections[1].name)
    assert_equal(sections(:section_01_2).name,   sections[2].name)
    assert_equal(sections(:section_01_3).name,   sections[3].name)

  end
  

  ######################################################################
  #
  # test_move_down
  #
  # Description:
  # This method performs the functional testing of the move_down
  # method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_move_down

    checklist_0_1 = checklists(:checklist_0_1)
    sections = checklist_0_1.sections
    
    assert_equal(sections(:section_01_1).id, sections[0].id)
    assert_equal(sections(:section_01_2).id, sections[1].id)
    assert_equal(sections(:section_01_3).id, sections[2].id)
    assert_equal(4, sections.size)

    section_01_2 = sections(:section_01_2)
    get(:move_down, { :id => section_01_2.id }, rich_designer_session)
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])
    assert_redirected_to(:controller => 'tracker', :action => 'index')
 
    get(:move_down, { :id => section_01_2.id }, cathy_admin_session)
    assert('Sections were re-ordered', flash['notice'])
    assert_redirected_to(:controller => 'checklist',
                         :action     => 'edit',
                         :id         => section_01_2.checklist_id)
    
    checklist_0_1.reload
    sections = checklist_0_1.sections
    assert_equal(sections(:section_01_1).id, sections[0].id)
    assert_equal(sections(:section_01_2).id, sections[2].id)
    assert_equal(sections(:section_01_3).id, sections[1].id)
    assert_equal(4, sections.size)

  end


  ######################################################################
  #
  # test_move_up
  #
  # Description:
  # This method performs the functional testing of the move_up
  # method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_move_up

    checklist_0_1 = checklists(:checklist_0_1)
    sections = checklist_0_1.sections
    
    assert_equal(sections(:section_01_1).id, sections[0].id)
    assert_equal(sections(:section_01_2).id, sections[1].id)
    assert_equal(sections(:section_01_3).id, sections[2].id)
    assert_equal(4, sections.size)

    section_01_2 = sections(:section_01_2)
    get(:move_up, { :id => section_01_2.id }, rich_designer_session)
    assert_equal(Pcbtr::MESSAGES[:admin_only], flash['notice'])
    assert_redirected_to(:controller => 'tracker', :action     => 'index')

    get(:move_up, { :id => section_01_2.id }, cathy_admin_session)
    assert('Sections were re-ordered', flash['notice'])
    assert_redirected_to(:controller => 'checklist',
                         :action     => 'edit',
                         :id         => section_01_2.checklist_id)
    
    checklist_0_1.reload
    sections = checklist_0_1.sections
    assert_equal(sections(:section_01_1).id, sections[1].id)
    assert_equal(sections(:section_01_2).id, sections[0].id)
    assert_equal(sections(:section_01_3).id, sections[2].id)
    assert_equal(4, sections.size)

  end


  ######################################################################
  #
  # test_update
  #
  # Description:
  # This method performs the functional testing of the update
  # method.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def test_update

    section_01_1 = sections(:section_01_1)
    section = Section.find(section_01_1.id)
    assert_equal(section_01_1.url, section.url)

    section.url = 'www.yahoo.com'
    get(:update, { :section => section.attributes }, cathy_admin_session)
    assert_equal('Section was successfully updated.', flash['notice'])
    assert_redirected_to(:controller => 'checklist',
			                   :action     => 'edit',
                         :id         => section_01_1.checklist_id)

  end


  ######################################################################
  #
  # dump
  #
  # Description:
  # This method dumps section data to the console.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # Additional information: Verifies the following
  # 
  #   - 
  #   - 
  #
  ######################################################################
  #
  def dump(message, checklist_id=0)

    if checklist_id == 0
      sections = Section.find_all("1", "checklist_id ASC")
    else
      sections = Section.find_all("checklist_id=#{checklist_id}",
				  "position")
    end

    print "\n"
    print "*** #{message} \n"
    print " Number of subsections: #{sections.size}\n\n"
    print "|********************************************************|\n"
    print "|     ID      |   CHECKLIST |  SORT ORDER  |\n"
    for s in sections
      printf("|%12s |%12s | %12s |",
	     s.id, s.checklist_id, s.position)
      print "\n"
    end
    print "|********************************************************|\n"
  end


end
