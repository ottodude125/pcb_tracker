########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: oi_instruction_controller_test.rb
#
# This file contains the functional tests for io_instruction_controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'oi_instruction_controller'

# Re-raise errors caught by the controller.
class OiInstructionController; def rescue_action(e) raise e end; end

class OiInstructionControllerTest < Test::Unit::TestCase
  def setup
    @controller = OiInstructionController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @emails     = ActionMailer::Base.deliveries
    @emails.clear
  end

  
  fixtures(:designs,
           :document_types,
           :oi_assignments,
           :oi_assignment_comments,
           :oi_categories,
           :oi_category_sections,
           :oi_instructions,
           :roles,
           :roles_users,
	       :users)
  

  ######################################################################
  #
  # test_oi_category_selection
  #
  # Description:
  # This method does the functional testing of the oi_category_selection
  # method from the OI Instruction Controller class
  #
  ######################################################################
  #
  def test_io_category_selection
  
    mx234a = designs(:mx234a)
    categories = ['Board Preparation',  'Placement',
                  'Routing',            'Fabrication Drawing',
                  'Nomenclature',       'Assembly Drawing',
                  'Other']

    # Try accessing from an account that is not a PCB Designer and
    # verify that the user is redirected.
    set_user(users(:pat_a).id, 'Product Support')
    post(:oi_category_selection, :design_id => mx234a.id)
    
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])

    # Verify that a Teradyne PCB Designer can access the list.
    set_user(users(:scott_g).id, 'Designer')
    post(:oi_category_selection, :design_id => mx234a.id)
    
    assert_response(:success)
    assert_not_nil(assigns(:design))
    assert_equal(mx234a.id, assigns(:design).id)
    assert_equal('mx234a',  assigns(:design).name)
    
    assert_not_nil(assigns(:oi_category_list))
    oi_category_list = assigns(:oi_category_list)
    assert_equal(categories.size, oi_category_list.size)
    categories.each_index do |i| 
      assert_equal(categories[i], oi_category_list[i].name) 
    end
     
    # Verify that a contractor PCB Designer can access the list.
    set_user(users(:siva_e).id, 'Designer')
    post(:oi_category_selection, :design_id => mx234a.id)

    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])

  end
  
  
  ######################################################################
  #
  # test_section_selection
  #
  # Description:
  # This method does the functional testing of the section_selection
  # method from the OI Instruction Controller class
  #
  ######################################################################
  #
  def test_section_selection
  
    mx234a     = designs(:mx234a)
    board_prep = oi_categories(:board_prep)

    # Try accessing from an account that is not a PCB Designer and
    # verify that the user is redirected.
    set_user(users(:pat_a).id, 'Product Support')
    post(:section_selection,
         :id        => oi_categories(:board_prep).id,
         :design_id => mx234a.id)
         
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])

    # Verify that a Teradyne PCB Designer can access the list.
    set_user(users(:scott_g).id, 'Designer')
    post(:section_selection,
         :id        => board_prep.id,
         :design_id => mx234a.id)
    
    assert_response(:success)
    design = assigns(:design)
    assert_not_nil(design)
    assert_equal(mx234a.id, design.id)
    assert_equal('mx234a',  design.name)
    
    category = assigns(:category)
    assert_not_nil(category)
    assert_equal(board_prep.id, category.id)
    assert_equal('Board Preparation', category.name)
    
    exp_sections = [oi_category_sections(:board_prep_1),
                    oi_category_sections(:board_prep_2),
                    oi_category_sections(:board_prep_3)]
    sections = assigns(:sections)
    
    exp_sections.each do |exp_section|
      actual_section = sections.shift
      assert_equal(exp_section.id,           actual_section.id)
      assert_equal(exp_section.name,         actual_section.name)
      assert_equal(exp_section.url1,         actual_section.url1)
      assert_equal(exp_section.instructions, actual_section.instructions)
      assert_equal(exp_section.oi_category_id,
                   actual_section.oi_category_id)
      assert_equal(exp_section.allegro_board_symbol,
                   actual_section.allegro_board_symbol)
      assert_equal(exp_section.outline_drawing_link,
                   actual_section.outline_drawing_link)
    end
     
    # Verify that a contractor PCB Designer can not access the list.
    set_user(users(:siva_e).id, 'Designer')
    post(:section_selection,
         :id        => board_prep.id,
         :design_id => mx234a.id)
    
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])


    set_user(users(:scott_g).id, 'Designer')
    other = oi_categories(:other)

    post(:section_selection,
         :id        => other.id,
         :design_id => mx234a.id)

    assert_redirected_to(:action      => :process_assignments,
                         :category_id => other.id,
                         :design_id   => mx234a.id)
    follow_redirect
    
    assert_equal(mx234a.id, assigns(:design).id)
    assert_equal(other.id,  assigns(:category).id)

  end


  ######################################################################
  #
  # test_process_assignments
  #
  # Description:
  # This method does the functional testing of the 
  #
  ######################################################################
  #
  def test_process_assignments
  
    mx234a              = designs(:mx234a)
    board_prep          = oi_categories(:board_prep)
    board_prep_sections = [oi_category_sections(:board_prep_1),
                           oi_category_sections(:board_prep_2),
                           oi_category_sections(:board_prep_3)]
    section_ids         = board_prep_sections.collect { |s| s.id }
    team_member_list    = [users(:siva_e)]
    
    section_selections = {}
    section_ids.each { |id| section_selections[id.to_s] = '0' }


    # Try accessing from an account that is not a PCB Designer and
    # verify that the user is redirected.
    set_user(users(:pat_a).id, 'Product Support')
    post(:process_assignments,
         :category => { :id => oi_categories(:board_prep).id },
         :design   => { :id => mx234a.id },
         :section  => section_selections)
         
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])
     
     
    # Verify that a contractor PCB Designer can not access the list.
    set_user(users(:siva_e).id, 'Designer')
    post(:process_assignments,
         :category => { :id => oi_categories(:board_prep).id },
         :design   => { :id => mx234a.id },
         :section  => section_selections)
    
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])


    # Verify that a Teradyne PCB Designer can access the list
    set_user(users(:scott_g).id, 'Designer')
    post(:process_assignments,
         :category => { :id => oi_categories(:board_prep).id },
         :design   => { :id => mx234a.id },
         :section  => section_selections)
    
    # None of the sections where selected, verify the response.
    assert_redirected_to(:action    => 'section_selection',
                         :design_id => mx234a.id,
                         :id        => oi_categories(:board_prep).id)

    assert_equal('Please select the step(s)', flash['notice'])
    flash[:section].each_value do |value|
      assert_equal('0', value)
    end

    # Make a selection and access again
    board_prep_section_1 = oi_category_sections(:board_prep_1)
    section_selections[board_prep_section_1.id.to_s] = '1'

    post(:process_assignments,
         :category => { :id => oi_categories(:board_prep).id },
         :design   => { :id => mx234a.id },
         :section  => section_selections)
    
    # Verify the response.
    assert_response(:success)
    flash[:section].each do |key, value|
      assert_equal(section_selections[key.to_s], value)      
    end
    
    team_members = assigns(:team_members)
    assert_equal(team_member_list.size,  team_members.size)
    assert_equal(team_member_list[0].id, team_members[0].id)
    

    selected_steps = assigns(:selected_steps)
    assert_equal(1, selected_steps.size)
    assert_equal(board_prep_section_1.id, selected_steps[0].id)
    
    assert_equal(mx234a.id,     assigns(:design).id)
    category = assigns(:category)
    assert_not_nil(category)
    assert_equal(board_prep.id, category.id)
    assert_equal('Board Preparation', category.name)

    assert_nil(assigns(:outline_drawing))
    
    assert_equal([:allegro_board_symbol_name, true], assigns(:common_field))
   
    common_fields = assigns(:common_fields)
    assert(common_fields[:allegro_board_symbol_name])
    assert(!common_fields[:outline_drawing_link])
    
    step_instructions = assigns(:step_instructions)
    assert_nil(step_instructions[0])
    assert_not_nil(step_instructions[board_prep_section_1.id])
    assert_equal(board_prep_section_1.id,
                 step_instructions[board_prep_section_1.id].oi_category_section_id)
 
    # Make a selection and access again
    board_prep_section_2 = oi_category_sections(:board_prep_2)
    board_prep_section_3 = oi_category_sections(:board_prep_3)
    section_selections[board_prep_section_2.id.to_s] = '1'
    section_selections[board_prep_section_3.id.to_s] = '1'

    post(:process_assignments,
         :category => { :id => oi_categories(:board_prep).id },
         :design   => { :id => mx234a.id },
         :section  => section_selections)
    
    # Verify the response.
    assert_response(:success)
    flash[:section].each do |key, value|
      assert_equal(section_selections[key.to_s],value)      
    end
    
    selected_steps = assigns(:selected_steps)
    assert_equal(3, selected_steps.size)
    assert_equal(board_prep_section_1.id, selected_steps[0].id)
    assert_equal(board_prep_section_2.id, selected_steps[1].id)
    assert_equal(board_prep_section_3.id, selected_steps[2].id)
    
    assert_equal(mx234a.id,     assigns(:design).id)
    category = assigns(:category)
    assert_not_nil(category)
    assert_equal(board_prep.id, category.id)
    assert_equal('Board Preparation', category.name)

    assert_nil(assigns(:outline_drawing))
    assert_not_nil(assigns(:common_field))
   
    common_fields = assigns(:common_fields)
    assert(common_fields[:allegro_board_symbol_name])
    assert(common_fields[:outline_drawing_link])
    
    step_instructions = assigns(:step_instructions)
    assert_nil(step_instructions[0])
    assert_not_nil(step_instructions[board_prep_section_1.id])
    assert_equal(board_prep_section_1.id,
                 step_instructions[board_prep_section_1.id].oi_category_section_id)
    assert_not_nil(step_instructions[board_prep_section_2.id])
    assert_equal(board_prep_section_2.id,
                 step_instructions[board_prep_section_2.id].oi_category_section_id)
    assert_not_nil(step_instructions[board_prep_section_3.id])
    assert_equal(board_prep_section_3.id,
                 step_instructions[board_prep_section_3.id].oi_category_section_id)
   
  end
  ######################################################################
  #
  # test_process_assignment_details
  #
  # Description:
  # This method does the functional testing of the 
  #
  ######################################################################
  #
  def test_process_assignment_details
  
    mx234a              = designs(:mx234a)
    board_prep          = oi_categories(:board_prep)
    board_prep_sections = [oi_category_sections(:board_prep_1),
                           oi_category_sections(:board_prep_2),
                           oi_category_sections(:board_prep_3)]
    section_ids         = board_prep_sections.collect { |s| s.id }
    siva                = users(:siva_e)
    scott               = users(:scott_g)
    mathi               = users(:mathi_n)
    team_member_list    = [siva]
    
    section_selections = {}
    section_ids.each { |id| section_selections[id.to_s] = '0' }


    # Try accessing from an account that is not a PCB Designer and
    # verify that the user is redirected.
    set_user(users(:pat_a).id, 'Product Support')
    post(:process_assignment_details)
         
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])
     

    # Verify that a contractor PCB Designer can not access the list.
    set_user(siva.id, 'Designer')
    post(:process_assignment_details)
    
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])


    # Verify that a Teradyne PCB Designer can access the list
    set_user(scott.id, 'Designer')
    post(:process_assignment_details,
         :category => { :id => board_prep.id },
         :design   => { :id => mx234a.id },
         :allegro_board_symbol => { :name => '' })
    
    # The allegro board symbol was not provided.  Verify the 
    # response
    assert_redirected_to(:action      => 'process_assignments',
                         :design_id   => mx234a.id,
                         :category_id => board_prep.id)
    assert_equal('Please identify the Allegro Board Symbol', flash['notice'])
    flash['notice'] = nil

    # Test the response when team members skipped for a section.
    post(:process_assignment_details,
         :category             => { :id => board_prep.id },
         :design               => { :id => mx234a.id },
         :allegro_board_symbol => { :name => 'ABS-1234' },
         :team_member_5004_1   => { :selected => '0' },
         :team_member_5005_1   => { :selected => '0' },
         :team_member_5004_2   => { :selected => '0' },
         :team_member_5005_2   => { :selected => '0' },
         :team_member_5004_3   => { :selected => '0' },
         :team_member_5005_3   => { :selected => '0' },
         :complexity_1         => { :id => 1 },
         :complexity_2         => { :id => 2 },
         :complexity_3         => { :id => 3 })
    
    assert_redirected_to(:action      => 'process_assignments',
                         :design_id   => mx234a.id,
                         :category_id => board_prep.id)
    assert_equal('Please select team member(s) for each step', flash['notice'])
    assert_equal('ABS-1234', flash[:allegro_board_symbol])
    flash['notice'] = nil

    # Test the response when team members skipped for a section.
    post(:process_assignment_details,
         :category             => { :id => board_prep.id },
         :design               => { :id => mx234a.id },
         :allegro_board_symbol => { :name => '' },
         :team_member_5004_1   => { :selected => '0'},
         :team_member_5005_1   => { :selected => '0'},
         :team_member_5004_2   => { :selected => '0'},
         :team_member_5005_2   => { :selected => '0'},
         :team_member_5004_3   => { :selected => '0'},
         :team_member_5005_3   => { :selected => '0'},
         :complexity_1         => { :id => 1 },
         :complexity_2         => { :id => 2 },
         :complexity_3         => { :id => 3 })
    
    assert_redirected_to(:action      => 'process_assignments',
                         :design_id   => mx234a.id,
                         :category_id => board_prep.id)
    assert_equal('Please identify the Allegro Board Symbol<br />' +
                 'Please select team member(s) for each step', 
                 flash['notice'])


    pre_post = { :instructions        => OiInstruction.find_all,
                 :assignments         => OiAssignment.find_all,
                 :assignment_comments => OiAssignmentComment.find_all }
    assert_equal(2, pre_post[:instructions].size)
    assert_equal(2, pre_post[:assignments].size)
    assert_equal(2, pre_post[:assignment_comments].size)
    assert_equal(0, @emails.size)
    
    # This posting has no errors and will result in updates to
    # the database.
    post(:process_assignment_details,
         :category             => { :id => board_prep.id },
         :design               => { :id => mx234a.id },
         :allegro_board_symbol => { :name => 'ABS-1234' },
         :team_member_5004_1   => { :selected => '1'},
         :team_member_5005_1   => { :selected => '0'},
         :team_member_5004_2   => { :selected => '0'},
         :team_member_5005_2   => { :selected => '1'},
         :team_member_5004_3   => { :selected => '1'},
         :team_member_5005_3   => { :selected => '1'},
         :complexity_1         => { :id => 1 },
         :complexity_2         => { :id => 2 },
         :complexity_3         => { :id => 3 },
         :step_instructions_1  => "Step 1 Instructions",
         :step_instructions_2  => "Step 2 Instructions",
         :step_instructions_3  => "Step 3 Instructions")
         
    expected_results = {
      1 => [{ :user_id           => 5004,
              :step_instructions => "Step 1 Instructions",
              :complexity_id     => 1 }],
      2 => [{ :user_id           => 5005,
              :step_instructions => "Step 2 Instructions",
              :complexity_id     => 2 }],
      3 => [{ :user_id           => 5004,
              :step_instructions => "Step 3 Instructions",
              :complexity_id     => 3 },
            { :user_id           => 5005,
              :step_instructions => "Step 3 Instructions",
              :complexity_id     => 3 }]
    }

    # Verify the response.
    assert_redirected_to(:action      => 'oi_category_selection',
                         :design_id   => mx234a.id)
    assert_equal('The work assignments have been recorded - mail was sent', 
                 flash['notice'])
                 
    oi_instructions = OiInstruction.find_all - pre_post[:instructions]
    assert_equal(3, oi_instructions.size)
    
    expected_sections = board_prep_sections.dup
    oi_instructions.sort_by { |i| i.oi_category_section_id}.each do |i|

        assert_equal(mx234a.id,                  i.design_id)
        assert_equal(scott.id,                   i.user_id)
        assert_equal(expected_sections.shift.id, i.oi_category_section_id)
    
        expected_assignments = expected_results[i.oi_category_section_id]
        index = 0
        i.oi_assignments.sort_by { |a| a.user_id }.each do |a|
        
          expected_assignment = expected_assignments[index]
          index += 1

          assert_equal(i.id, a.oi_instruction_id)
          assert_equal(expected_assignment[:user_id],       a.user_id)
          assert_equal(expected_assignment[:complexity_id], a.complexity_id)
          
          a.oi_assignment_comments.each do |ac|
            assert_equal(a.id,               ac.oi_assignment_id)
            assert_equal(scott.id,           ac.user_id)
            assert_equal(expected_assignment[:step_instructions],
                         ac.comment)
          end
        
        end
    
    end

    oi_assignments = OiAssignment.find_all - pre_post[:assignments]
    assert_equal(4, oi_assignments.size)
    
    oi_assignment_comments = OiAssignmentComment.find_all - pre_post[:assignment_comments]
    assert_equal(4, oi_assignment_comments.size)

    # Verify the email that was generated
    expected_to = [ [ siva.email ].sort,
                    [ mathi.email ].sort,
                    [ siva.email, mathi.email ].sort ]
    
    expected_cc_list = [users(:jim_l).email, 
                        users(:jan_k).email, 
                        users(:cathy_m).email].sort
                        
    @emails.each do |email|
      assert_equal(expected_to.shift,   email.to.sort)
      assert_equal(expected_cc_list,    email.cc.sort)
      assert_equal("#{mx234a.name}:: Work Assignment Created",
                   email.subject)
    end
    @emails.clear

    # Verify that a user from outside the PCB Group can not 
    # access the  view_assignments view
    set_user(users(:pat_a).id, 'Product Support')
    post(:view_assignments)
         
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])
     

    # Verify that a contractor PCB Designer can not access the 
    # view_assignments view
    set_user(siva.id, 'Designer')
    post(:view_assignments)
    
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])

    # Verify that a Teradyne PCB Designer can access the 
    # view_assignments view
    set_user(scott.id, 'Designer')
    post(:view_assignments,
         :id                => board_prep.id,
         :design_id         => mx234a.id)
    
    assert_response(:success)
    assert(mx234a.id, assigns(:design).id)
    
    assignment_list = assigns(:assignment_list)
    assert_equal(3, assignment_list.size)
    
    expected_sections = board_prep_sections.dup
    
    assignment_list.each do |category, assignment_list|
      assert_equal(expected_sections.shift.id, category.id)
      assert_equal(expected_results[category.id].size, assignment_list.size)
    end
    
    # Verify that a user from outside the PCB Group can not 
    # access the  assignment_view view
    set_user(users(:pat_a).id, 'Product Support')
    post(:assignment_view)
         
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])
     
    # Verify that a Teradyne PCB Designer can access the 
    # the  assignment_view view
    set_user(scott.id, 'Designer')
    assignment_id = assignment_list.pop.id
    post(:assignment_view, :id => assignment_id)
    
    assert_response(:success)
    assert_equal(assignment_id, assigns(:assignment).id)
    assert_equal(mx234a.id,     assigns(:design).id)
    assert_equal(board_prep.id, assigns(:category).id)

    comments = assigns(:comments)
    assert_equal(1, comments.size)
    comment  = comments.pop
    assert_equal("Step 3 Instructions", comment.comment)
    
    assert_not_nil(assigns(:post_comment))
    
    
    # Verify that a user from outside the PCB Group can not 
    # access the  category_details view
    set_user(users(:pat_a).id, 'Product Support')
    post(:category_details)
         
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])
     
    # Verify that a contractor Team Member can access the 
    # category_details view
    set_user(siva.id, 'Designer')
    post(:category_details, :id => mx234a.id)
    
    assert_response(:success)
    assert_equal(mx234a.id, assigns(:design).id)
    
    siva_assignments = assigns(:category_list)
    assert_equal(1, siva_assignments.size)
    assert_not_nil(siva_assignments[board_prep])
    
    assignment_list = siva_assignments[board_prep]
    assert_equal(2, assignment_list.size)
    assert_not_nil(assignment_list.detect { |a| 
                     a.oi_instruction.oi_category_section_id == board_prep_sections[0].id })    
    assert_not_nil(assignment_list.detect { |a| 
                     a.oi_instruction.oi_category_section_id == board_prep_sections[2].id })    
    assignment_list.each { |a| assert_equal(siva.id, a.user_id) }

    # Verify that a user from outside the PCB Group can not 
    # access the  assignment_details view
    set_user(users(:pat_a).id, 'Product Support')
    post(:assignment_details)
         
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])
     
    # Verify that a contractor Team Member can access the 
    # category_details view
    set_user(siva.id, 'Designer')
    post(:assignment_details,
         :id                  => board_prep.id,
         :design_id           => mx234a.id)
    
    assert_response(:success)
    assert_equal(mx234a.id,     assigns(:design).id)
    assert_equal(board_prep.id, assigns(:category).id)
    
    section_list = assigns(:section_list)
    assert_equal('Board Preparation', section_list[:category].name)
    assert_equal(2,                   section_list[:assignment_list].size)
    assert_equal(1, section_list[:assignment_list][0].oi_instruction.oi_category_section_id)
    assert_equal(3, section_list[:assignment_list][1].oi_instruction.oi_category_section_id)


    # Verify that a user from outside the PCB Group can not 
    # update an assignment.
    set_user(users(:pat_a).id, 'Product Support')
    post(:assignment_update)
         
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])

    # Verify that a member of the PCB Design group can 
    # update an assignment
    set_user(siva.id, 'Designer')
    
    # Get the instruction with 2 assignments associated with it
    instruction = OiInstruction.find_by_design_id_and_oi_category_section_id(
                    mx234a.id,
                    board_prep_sections[2].id)

    siva_assignment  = instruction.oi_assignments.detect { |a| a.user_id == siva.id }
    mathi_assignment = instruction.oi_assignments.detect { |a| a.user_id == mathi.id }

    assert_equal(2,         instruction.oi_assignments.size)
    assert_equal(1,         siva_assignment.oi_assignment_comments.size)
    assert_equal(0,         siva_assignment.complete)
    assert_equal(siva.id,   siva_assignment.user_id)
    assert_equal(1,         mathi_assignment.oi_assignment_comments.size)
    assert_equal(0,         mathi_assignment.complete)
    assert_equal(mathi.id,  mathi_assignment.user_id)
    siva_assignment_comment  = siva_assignment.oi_assignment_comments.pop
    mathi_assignment_comment = mathi_assignment.oi_assignment_comments.pop
    assert_not_equal(siva_assignment_comment.id, mathi_assignment_comment.id)


    post(:assignment_update,
         :assignment   => siva_assignment,
         :post_comment => {:comment => 'My 2 cents'})
         
    siva_assignment.reload
    mathi_assignment.reload

    assert_equal(2,         instruction.oi_assignments.size)
    assert_equal(2,         siva_assignment.oi_assignment_comments.size)
    assert_equal(0,         siva_assignment.complete)
    assert_equal(siva.id,   siva_assignment.user_id)
    assert_equal(1,         mathi_assignment.oi_assignment_comments.size)
    assert_equal(0,         mathi_assignment.complete)
    assert_equal(mathi.id,  mathi_assignment.user_id)

    cc_list = expected_cc_list.dup + [siva.email]
    email = @emails.pop
    assert_equal([scott.email],  email.to.sort)
    assert_equal(cc_list.sort,   email.cc.sort)
    assert_equal("#{mx234a.name}:: Work Assignment Update", email.subject)


    post(:assignment_update,
         :assignment   => { :id       => siva_assignment.id,
                            :complete => "1"},
         :post_comment => {:comment => 'It is done'})
         
    siva_assignment.reload
    mathi_assignment.reload

    assert_equal(2,         instruction.oi_assignments.size)
    assert_equal(3,         siva_assignment.oi_assignment_comments.size)
    assert_equal(1,         siva_assignment.complete)
    assert_equal(siva.id,   siva_assignment.user_id)
    assert_equal(1,         mathi_assignment.oi_assignment_comments.size)
    assert_equal(0,         mathi_assignment.complete)
    assert_equal(mathi.id,  mathi_assignment.user_id)

    email = @emails.pop
    assert_equal([scott.email],  email.to.sort)
    assert_equal(cc_list.sort,   email.cc.sort)
    assert_equal("#{mx234a.name}:: Work Assignment Update - Completed",
                 email.subject)
    
    set_user(scott.id, 'Designer')
    post(:assignment_update,
         :assignment   => { :id       => siva_assignment.id,
                            :complete => "0"},
         :post_comment => {:comment => 'My 2 cents'})
         
    siva_assignment.reload
    mathi_assignment.reload

    assert_equal(2,         instruction.oi_assignments.size)
    assert_equal(4,         siva_assignment.oi_assignment_comments.size)
    assert_equal(0,         siva_assignment.complete)
    assert_equal(siva.id,   siva_assignment.user_id)
    assert_equal(1,         mathi_assignment.oi_assignment_comments.size)
    assert_equal(0,         mathi_assignment.complete)
    assert_equal(mathi.id,  mathi_assignment.user_id)

    cc_list = expected_cc_list.dup + [scott.email]
    email = @emails.pop
    assert_equal([siva.email],  email.to.sort)
    assert_equal(cc_list.sort,   email.cc.sort)
    assert_equal("#{mx234a.name}:: Work Assignment Update - Reopened",
                 email.subject)
    
  end
  
  
end
