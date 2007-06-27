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
    
    @mx234a     = designs(:mx234a)
    @other      = oi_categories(:other)
    @board_prep = oi_categories(:board_prep)
    
    
    @emails     = ActionMailer::Base.deliveries
    @emails.clear

    @pat_a      = users(:pat_a)
    @siva_e     = users(:siva_e)
    @scott_g    = users(:scott_g)
    @jan_k      = users(:jan_k)
    @jim_l      = users(:jim_l)
    @cathy_m    = users(:cathy_m)
    @mathi_n    = users(:mathi_n)

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
  
    categories = ['Board Preparation',  'Placement',
                  'Routing',            'Fabrication Drawing',
                  'Nomenclature',       'Assembly Drawing',
                  'Other']

    # Try accessing from an account that is not a PCB Designer and
    # verify that the user is redirected.
    set_user(@pat_a.id, 'Product Support')
    post(:oi_category_selection, :design_id => @mx234a.id)
    
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])

    # Verify that a Teradyne PCB Designer can access the list.
    set_user(@scott_g.id, 'Designer')
    post(:oi_category_selection, :design_id => @mx234a.id)
    
    assert_response(:success)
    assert_not_nil(assigns(:design))
    assert_equal(@mx234a.id, assigns(:design).id)
    assert_equal('mx234a',   assigns(:design).name)
    
    assert_not_nil(assigns(:oi_category_list))
    oi_category_list = assigns(:oi_category_list)
    assert_equal(categories.size, oi_category_list.size)
    categories.each_index do |i| 
      assert_equal(categories[i], oi_category_list[i].name) 
    end
     
    # Verify that a contractor PCB Designer can access the list.
    set_user(@siva_e.id, 'Designer')
    post(:oi_category_selection, :design_id => @mx234a.id)

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
  
    # Try accessing from an account that is not a PCB Designer and
    # verify that the user is redirected.
    set_user(@pat_a.id, 'Product Support')
    post(:section_selection,
         :id        => @board_prep.id,
         :design_id => @mx234a.id)
         
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])

    # Verify that a Teradyne PCB Designer can access the list.
    set_user(@scott_g.id, 'Designer')
    post(:section_selection,
         :id        => @board_prep.id,
         :design_id => @mx234a.id)
    
    assert_response(:success)
    design = assigns(:design)
    assert_not_nil(design)
    assert_equal(@mx234a.id, design.id)
    assert_equal('mx234a',   design.name)
    
    category = assigns(:category)
    assert_not_nil(category)
    assert_equal(@board_prep.id,      category.id)
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
    set_user(@siva_e.id, 'Designer')
    post(:section_selection,
         :id        => @board_prep.id,
         :design_id => @mx234a.id)
    
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])

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
  
    board_prep_sections = [oi_category_sections(:board_prep_1),
                           oi_category_sections(:board_prep_2),
                           oi_category_sections(:board_prep_3)]
    section_ids         = board_prep_sections.collect { |s| s.id }
    team_member_list    = [@siva_e]
    
    section_selections = {}
    section_ids.each { |id| section_selections[id.to_s] = '0' }


    # Try accessing from an account that is not a PCB Designer and
    # verify that the user is redirected.
    set_user(@pat_a.id, 'Product Support')
    post(:process_assignments,
         :category => { :id => @board_prep.id },
         :design   => { :id => @mx234a.id },
         :section  => section_selections)
         
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])
     
     
    # Verify that a contractor PCB Designer can not access the list.
    set_user(@siva_e.id, 'Designer')
    post(:process_assignments,
         :category => { :id => @board_prep.id },
         :design   => { :id => @mx234a.id },
         :section  => section_selections)
    
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])

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
  def test_task_assignment
  
    board_prep_sections = [oi_category_sections(:board_prep_1),
                           oi_category_sections(:board_prep_2),
                           oi_category_sections(:board_prep_3)]
    section_ids         = board_prep_sections.collect { |s| s.id }
    team_member_list    = [@siva_e]
    
    
    # Verify that a Teradyne PCB Designer can access the list
    set_user(@scott_g.id, 'Designer')

    # Section Selection - Other
    post(:section_selection,
         :id        => @other.id,
         :design_id => @mx234a.id)
         
    assert_redirected_to(:action      => :process_assignments,
                         :category_id => @other.id,
                         :design_id   => @mx234a.id,
                         :section_id  => OiCategory.other_category_section_id)
         
    # Section Selection - Board Prep
    post(:section_selection,
         :id        => @board_prep.id,
         :design_id => @mx234a.id )
    
    assert_equal(board_prep_sections, assigns(:sections))
    assert_equal(0,                   assigns(:section_id))
    
    
    # Process Assignments - No step selected
    post(:process_assignments,
         :design   => { :id => @mx234a.id },
         :category => { :id => @board_prep.id } )
         
    assert_equal("Please select the step", flash['notice'])
    assert_nil(flash[:assignment])
    assert_redirected_to(:action    => 'section_selection',
                         :id        => @board_prep.id,
                         :design_id => @mx234a.id)
    
   
    # Process Assignments - No errors
    post(:process_assignments,
         :section_id => oi_category_sections(:board_prep_1).id,
         :design     => { :id => @mx234a.id },
         :category   => { :id => @board_prep.id } )
         
    assert_equal(@mx234a.id,     assigns(:design).id)
    assert_equal(@board_prep.id, assigns(:category).id)
    
    lcr_team_members = assigns(:team_members)
    expected_team_members = [@siva_e, @mathi_n] 
    assert_equal(expected_team_members, lcr_team_members)
    
    assert_equal(oi_category_sections(:board_prep_1).id,
                 assigns(:selected_step).id)
                 
    instruction = assigns(:instruction)
    assert_equal(@board_prep.id, instruction.oi_category_section_id)
    assert_equal(@mx234a.id,     instruction.design_id)
    
    assignment = assigns(:assignment)
    assert_equal((Time.now+1.day).year,             assignment.due_date.year)
    assert_equal((Time.now+1.day).month,            assignment.due_date.month)
    assert_equal((Time.now+1.day).day,              assignment.due_date.day)
    assert_equal(OiAssignment.complexity_id('Low'), assignment.complexity_id)
    
    assert_not_nil(assigns(:comment))
    
    assert(!assigns(:selected_step).outline_drawing_link?)
    
    allegro_board_symbol = '10987654321'
    assignment_comment   = 'This is a test'
    medium_complexity_id = OiAssignment.complexity_id('Medium')
    due_date             = Time.local(2007, "May", 1)
    
    # Process Assignment Details - No allegro board symbol provided.
    post(:process_assignment_details,
         :category    => { :id                     => @board_prep.id },
         :design      => { :id                     => @mx234a.id },
         :comment     => { :comment                => assignment_comment},
         :instruction => { :oi_category_section_id => board_prep_sections[0].id.to_s },
         :assignment  => { :complexity_id          => medium_complexity_id,
                           "due_date(1i)"          => "2007",
                           "due_date(2i)"          => "5",
                           "due_date(3i)"          => "1" },
         :team_member => { "5004" => '1', "5005" => '1' })

    assert_equal('Please identify the Allegro Board Symbol', flash['notice'])
    assert_not_nil(flash[:assignment])
    assignment = flash[:assignment]
    
    assert_equal(medium_complexity_id, assignment[:assignment].complexity_id)
    assert_equal(due_date.to_i,        assignment[:assignment].due_date.to_i)
    
    assert_not_nil(assignment[:design])
    assert_equal(@mx234a.id, assignment[:design].id)
    flash[:assignment][:design].name = 'abc'
    
    assert_not_nil(assignment[:selected_step])
    assert_equal(board_prep_sections[0].id, assignment[:selected_step].id)
    
    assert_not_nil(assignment[:instruction])
    assert_equal(board_prep_sections[0].id,
                 assignment[:instruction].oi_category_section_id)
                 
    assert_not_nil(assignment[:member_selections])
    assert_equal({ "5004" => '1', "5005" => '1' }, assignment[:member_selections])
                 
    assert_not_nil(assignment[:team_members])
    assert_equal([@siva_e, @mathi_n], assignment[:team_members])
                 
    assert_not_nil(assignment[:comment])
    assert_equal(assignment_comment, assignment[:comment].comment )
    
    assert_redirected_to(:action      => 'process_assignments',
                         :category_id => @board_prep.id,
                         :design_id   => @mx234a.id)
                         
    follow_redirect
    
    #Verify that the variable where loaded from the flash.
    assert_equal(assignment[:design],        assigns(:design))    
    assert_equal(assignment[:category],      assigns(:category))
    assert_equal(assignment[:team_members],  assigns(:team_members))
    assert_equal(assignment[:selected_step], assigns(:selected_step))
    assert_equal(assignment[:instruction],   assigns(:instruction))
    assert_equal(assignment[:assignment],    assigns(:assignment))
    assert_equal(assignment[:comment],       assigns(:comment))
    assert_not_nil(flash[:assignment])
    assert_nil(assigns(:outline_drawing))
    
    
    # Process Assignment Details - No team members identified.
    post(:process_assignment_details,
         :category    => { :id                     => @board_prep.id },
         :design      => { :id                     => @mx234a.id },
         :comment     => { :comment                => assignment_comment},
         :instruction => { :oi_category_section_id => board_prep_sections[0].id.to_s,
                           :allegro_board_symbol   => allegro_board_symbol },
         :assignment  => { :complexity_id          => medium_complexity_id,
                           "due_date(1i)"          => "2007",
                           "due_date(2i)"          => "5",
                           "due_date(3i)"          => "1" },
         :team_member => { "5004" => '0', "5005" => '0' })

    assert_equal('Please select a team member or members', flash['notice'])
    assert_not_nil(flash[:assignment])
    assignment = flash[:assignment]
    
    assert_equal(medium_complexity_id, assignment[:assignment].complexity_id)
    assert_equal(due_date.to_i,        assignment[:assignment].due_date.to_i)
    
    assert_not_nil(assignment[:design])
    assert_equal(@mx234a.id, assignment[:design].id)
    flash[:assignment][:design].name = 'abc'
    
    assert_not_nil(assignment[:selected_step])
    assert_equal(board_prep_sections[0].id, assignment[:selected_step].id)
    
    assert_not_nil(assignment[:instruction])
    assert_equal(board_prep_sections[0].id,
                 assignment[:instruction].oi_category_section_id)
                 
    assert_not_nil(assignment[:member_selections])
    assert_equal({ "5004" => '0', "5005" => '0' }, assignment[:member_selections])
                 
    assert_not_nil(assignment[:team_members])
    assert_equal([@siva_e, @mathi_n], assignment[:team_members])
                 
    assert_not_nil(assignment[:comment])
    assert_equal(assignment_comment, assignment[:comment].comment )
    
    assert_redirected_to(:action      => 'process_assignments',
                         :category_id => @board_prep.id,
                         :design_id   => @mx234a.id)
                         
    follow_redirect
    
    #Verify that the variable where loaded from the flash.
    assert_equal(assignment[:design],        assigns(:design))    
    assert_equal(assignment[:category],      assigns(:category))
    assert_equal(assignment[:team_members],  assigns(:team_members))
    assert_equal(assignment[:selected_step], assigns(:selected_step))
    assert_equal(assignment[:instruction],   assigns(:instruction))
    assert_equal(assignment[:assignment],    assigns(:assignment))
    assert_equal(assignment[:comment],       assigns(:comment))
    assert_not_nil(flash[:assignment])
    assert_nil(assigns(:outline_drawing))
    
    section_selections = {}
    section_ids.each { |id| section_selections[id.to_s] = '0' }

    # Process Assignment Details - No team members identified and no allegro board symbol
    # provided.
    post(:process_assignment_details,
         :category    => { :id                     => @board_prep.id },
         :design      => { :id                     => @mx234a.id },
         :comment     => { :comment                => assignment_comment},
         :instruction => { :oi_category_section_id => board_prep_sections[0].id.to_s },
         :assignment  => { :complexity_id          => medium_complexity_id,
                           "due_date(1i)"          => "2007",
                           "due_date(2i)"          => "5",
                           "due_date(3i)"          => "1" },
         :team_member => { "5004" => '0', "5005" => '0' })

    assert_equal('Please identify the Allegro Board Symbol<br />' +
                 'Please select a team member or members', 
                  flash['notice'])
    assert_not_nil(flash[:assignment])
    assignment = flash[:assignment]
    
    assert_equal(medium_complexity_id, assignment[:assignment].complexity_id)
    assert_equal(due_date.to_i,        assignment[:assignment].due_date.to_i)
    
    assert_not_nil(assignment[:design])
    assert_equal(@mx234a.id, assignment[:design].id)
    flash[:assignment][:design].name = 'abc'
    
    assert_not_nil(assignment[:selected_step])
    assert_equal(board_prep_sections[0].id, assignment[:selected_step].id)
    
    assert_not_nil(assignment[:instruction])
    assert_equal(board_prep_sections[0].id,
                 assignment[:instruction].oi_category_section_id)
                 
    assert_not_nil(assignment[:member_selections])
    assert_equal({ "5004" => '0', "5005" => '0' }, assignment[:member_selections])
                 
    assert_not_nil(assignment[:team_members])
    assert_equal([@siva_e, @mathi_n], assignment[:team_members])
                 
    assert_not_nil(assignment[:comment])
    assert_equal(assignment_comment, assignment[:comment].comment )
    
    assert_redirected_to(:action      => 'process_assignments',
                         :category_id => @board_prep.id,
                         :design_id   => @mx234a.id)
                         
    follow_redirect
    
    #Verify that the variable where loaded from the flash.
    assert_equal(assignment[:design],        assigns(:design))    
    assert_equal(assignment[:category],      assigns(:category))
    assert_equal(assignment[:team_members],  assigns(:team_members))
    assert_equal(assignment[:selected_step], assigns(:selected_step))
    assert_equal(assignment[:instruction],   assigns(:instruction))
    assert_equal(assignment[:assignment],    assigns(:assignment))
    assert_equal(assignment[:comment],       assigns(:comment))
    assert_not_nil(flash[:assignment])
    assert_nil(assigns(:outline_drawing))

    instruction_count        = OiInstruction.count
    assignment_count         = OiAssignment.count
    assignment_comment_count = OiAssignmentComment.count
    
    
    post(:view_assignments,
         :id                => @board_prep.id,
         :design_id         => @mx234a.id)
    
    assert_response(:success)
    assert_equal(@mx234a.id, assigns(:design).id)
    assert_equal(0,          assigns(:assignment_list).size)
    

    # Process Assignment Details - No errors
    post(:process_assignment_details,
         :category    => { :id                     => @board_prep.id },
         :design      => { :id                     => @mx234a.id },
         :comment     => { :comment                => assignment_comment},
         :instruction => { :oi_category_section_id => board_prep_sections[0].id.to_s,
                           :allegro_board_symbol   => allegro_board_symbol },
         :assignment  => { :complexity_id          => medium_complexity_id,
                           "due_date(1i)"          => "2007",
                           "due_date(2i)"          => "5",
                           "due_date(3i)"          => "1" },
         :team_member => { "5004" => '1', "5005" => '1' })

    assert_equal('The work assignments have been recorded - mail was sent',
                 flash['notice'])
    assert_nil(flash[:assignment])

    assert_redirected_to(:action      => 'oi_category_selection',
                         :design_id   => @mx234a.id)
    
    
    assert_equal(instruction_count+1, OiInstruction.count)
    instructions = OiInstruction.find(:all)
    last_instruction = instructions.pop
    assert_equal(@scott_g.id,               last_instruction.user_id)
    assert_equal(allegro_board_symbol,      last_instruction.allegro_board_symbol)
    assert_equal(board_prep_sections[0].id, last_instruction.oi_category_section_id)
    
    assert_equal(assignment_count+2, OiAssignment.count)
    assignments      = OiAssignment.find(:all)
    mathi_assignment = assignments.pop
    siva_assignment  = assignments.pop
    
    assert(!siva_assignment.complete?)
    assert_equal(@siva_e.id,           siva_assignment.user_id)
    assert_equal(last_instruction.id,  siva_assignment.oi_instruction_id)
    assert_equal(due_date.to_i,        siva_assignment.due_date.to_i)
    assert_equal(medium_complexity_id, siva_assignment.complexity_id)

    assert(!mathi_assignment.complete?)
    assert_equal(@mathi_n.id,          mathi_assignment.user_id)
    assert_equal(last_instruction.id,  mathi_assignment.oi_instruction_id)
    assert_equal(due_date.to_i,        mathi_assignment.due_date.to_i)
    assert_equal(medium_complexity_id, mathi_assignment.complexity_id)
    
    assert_equal(assignment_comment_count+2, OiAssignmentComment.count)
    assignment_comments = OiAssignmentComment.find(:all)
    mathi_comment = assignment_comments.pop
    siva_comment  = assignment_comments.pop
    
    assert_equal(siva_assignment.id, siva_comment.oi_assignment_id)
    assert_equal(@scott_g.id,        siva_comment.user_id)
    assert_equal(assignment_comment, siva_comment.comment)
    
    assert_equal(mathi_assignment.id, mathi_comment.oi_assignment_id)
    assert_equal(@scott_g.id,         mathi_comment.user_id)
    assert_equal(assignment_comment,  mathi_comment.comment)
    

    # Try accessing from an account that is not a PCB Designer and
    # verify that the user is redirected.
    set_user(@pat_a.id, 'Product Support')
    post(:process_assignment_details)
         
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])
     

    # Verify that a contractor PCB Designer can not access the list.
    set_user(@siva_e.id, 'Designer')
    post(:process_assignment_details)
    
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])

    # Verify the email that was generated
    expected_to = [ [ @siva_e.email ].sort,
                    [ @mathi_n.email ].sort,
                    [ @siva_e.email, @mathi_n.email ].sort ]
    
    expected_cc_list = [@scott_g.email,
                        @jim_l.email, 
                        @jan_k.email, 
                        @cathy_m.email].sort
                       
    assert_equal(2, @emails.size) 
    mathi_email = @emails.pop
    siva_email  = @emails.pop
    
    assert_equal(1,                                        siva_email.to.size)
    assert_equal(@siva_e.email,                             siva_email.to.pop)
    assert_equal(expected_cc_list,                         siva_email.cc.sort)
    assert_equal("Work Assignment Created for the mx234a", siva_email.subject)

    assert_equal(1,                                        mathi_email.to.size)
    assert_equal(@mathi_n.email,                           mathi_email.to.pop)
    assert_equal(expected_cc_list,                         mathi_email.cc.sort)
    assert_equal("Work Assignment Created for the mx234a", mathi_email.subject)

    # Verify that a user from outside the PCB Group can not 
    # access the  view_assignments view
    set_user(@pat_a.id, 'Product Support')
    post(:view_assignments)
         
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])
     

    # Verify that a contractor PCB Designer can not access the 
    # view_assignments view
    set_user(@siva_e.id, 'Designer')
    post(:view_assignments)
    
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])

    # Verify that a Teradyne PCB Designer can access the 
    # view_assignments view
    set_user(@scott_g.id, 'Designer')
    post(:view_assignments,
         :id                => @board_prep.id,
         :design_id         => @mx234a.id)
    
    assert_response(:success)
    assert_equal(@mx234a.id, assigns(:design).id)
    
    assignment_list = assigns(:assignment_list)
    assert_equal(1, assignment_list.size)
    
    expected_sections = board_prep_sections.dup
    
    # There is only on category populated
    assignment_list.each do |category, assignments|
      assert_equal(expected_sections.shift.id, category.id)
      assert_equal(2, assignments.size)
    end
    
    # Verify that a user from outside the PCB Group can not 
    # access the  assignment_view view
    set_user(@pat_a.id, 'Product Support')
    post(:assignment_view)
         
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])
     
    # Verify that a Teradyne PCB Designer can access the 
    # the  assignment_view view
    set_user(@scott_g.id, 'Designer')
    assignment_id = assignments.pop.id
    post(:assignment_view, :id => assignment_id)
    
    assert_response(:success)
    assert_equal(assignment_id,  assigns(:assignment).id)
    assert_equal(@mx234a.id,     assigns(:design).id)
    assert_equal(@board_prep.id, assigns(:category).id)

    comments = assigns(:comments)
    assert_equal(1, comments.size)
    comment  = comments.pop
    assert_equal(assignment_comment, comment.comment)
    
    assert_not_nil(assigns(:post_comment))
    
    
    # Verify that a user from outside the PCB Group can not 
    # access the  category_details view
    set_user(@pat_a.id, 'Product Support')
    post(:category_details)
         
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])
     
    # Verify that a contractor Team Member can access the 
    # category_details view
    set_user(@siva_e.id, 'Designer')
    post(:category_details, :id => @mx234a.id)
    
    assert_response(:success)
    assert_equal(@mx234a.id, assigns(:design).id)
    
    siva_assignments = assigns(:category_list)
    assert_equal(2, siva_assignments.size)
    assert_not_nil(siva_assignments[@board_prep])
    
    assignment_list = siva_assignments[@board_prep]
    assert_equal(1, assignment_list.size)
    assert_not_nil(assignment_list.detect { |a| 
                     a.oi_instruction.oi_category_section_id == board_prep_sections[0].id })    
    assignment_list.each { |a| assert_equal(@siva_e.id, a.user_id) }

    # Verify that a user from outside the PCB Group can not 
    # access the  assignment_details view
    set_user(@pat_a.id, 'Product Support')
    post(:assignment_details)
         
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])
     
    # Verify that a contractor Team Member can access the 
    # category_details view
    set_user(@siva_e.id, 'Designer')
    post(:assignment_details,
         :id                  => @board_prep.id,
         :design_id           => @mx234a.id)
    
    assert_response(:success)
    assert_equal(@mx234a.id,     assigns(:design).id)
    assert_equal(@board_prep.id, assigns(:category).id)
    
    section_list = assigns(:section_list)
    assert_equal('Board Preparation', section_list[:category].name)
    assert_equal(1,                   section_list[:assignment_list].size)
    assert_equal(1, section_list[:assignment_list][0].oi_instruction.oi_category_section_id)


    # Verify that a user from outside the PCB Group can not 
    # update an assignment.
    set_user(@pat_a.id, 'Product Support')
    post(:assignment_update)
         
    assert_redirected_to(:controller => 'tracker', :action     => 'index')
    assert_equal("You are not authorized to access this page", flash['notice'])

    # Verify that a member of the PCB Design group can 
    # update an assignment
    set_user(@siva_e.id, 'Designer')
    
    # Get the instruction with 2 assignments associated with it
    instruction = OiInstruction.find_by_design_id_and_oi_category_section_id(
                    @mx234a.id,
                    board_prep_sections[0].id)

    siva_assignment  = instruction.oi_assignments.detect { |a| a.user_id == @siva_e.id }
    mathi_assignment = instruction.oi_assignments.detect { |a| a.user_id == @mathi_n.id }

    assert_equal(2,           instruction.oi_assignments.size)
    assert_equal(1,           siva_assignment.oi_assignment_comments.size)
    assert_equal(0,           siva_assignment.complete)
    assert_equal(@siva_e.id,  siva_assignment.user_id)
    assert_equal(1,           mathi_assignment.oi_assignment_comments.size)
    assert_equal(0,           mathi_assignment.complete)
    assert_equal(@mathi_n.id, mathi_assignment.user_id)
    siva_assignment_comment  = siva_assignment.oi_assignment_comments.pop
    mathi_assignment_comment = mathi_assignment.oi_assignment_comments.pop
    assert_not_equal(siva_assignment_comment.id, mathi_assignment_comment.id)


    post(:assignment_update,
         :assignment   => siva_assignment,
         :post_comment => {:comment => 'My 2 cents'})
         
    siva_assignment.reload
    mathi_assignment.reload

    assert_equal(2,           instruction.oi_assignments.size)
    assert_equal(2,           siva_assignment.oi_assignment_comments.size)
    assert_equal(0,           siva_assignment.complete)
    assert_equal(@siva_e.id,  siva_assignment.user_id)
    assert_equal(1,           mathi_assignment.oi_assignment_comments.size)
    assert_equal(0,           mathi_assignment.complete)
    assert_equal(@mathi_n.id, mathi_assignment.user_id)

    cc_list = expected_cc_list.dup + [@siva_e.email] - [@scott_g.email]
    email = @emails.pop
    assert_equal([@scott_g.email], email.to.sort)
    assert_equal(cc_list.sort,     email.cc.sort)
    assert_equal("#{@mx234a.name}:: Work Assignment Update", email.subject)


    post(:assignment_update,
         :assignment   => { :id       => siva_assignment.id,
                            :complete => "1"},
         :post_comment => {:comment => 'It is done'})
         
    siva_assignment.reload
    mathi_assignment.reload

    assert_equal(2,           instruction.oi_assignments.size)
    assert_equal(3,           siva_assignment.oi_assignment_comments.size)
    assert_equal(1,           siva_assignment.complete)
    assert_equal(@siva_e.id,  siva_assignment.user_id)
    assert_equal(1,           mathi_assignment.oi_assignment_comments.size)
    assert_equal(0,           mathi_assignment.complete)
    assert_equal(@mathi_n.id, mathi_assignment.user_id)

    email = @emails.pop
    assert_equal([@scott_g.email], email.to.sort)
    assert_equal(cc_list.sort,     email.cc.sort)
    assert_equal("#{@mx234a.name}:: Work Assignment Update - Completed",
                 email.subject)
    
    set_user(@scott_g.id, 'Designer')
    post(:assignment_update,
         :assignment   => { :id       => siva_assignment.id,
                            :complete => "0"},
         :post_comment => {:comment => 'My 2 cents'})
         
    siva_assignment.reload
    mathi_assignment.reload

    assert_equal(2,           instruction.oi_assignments.size)
    assert_equal(4,           siva_assignment.oi_assignment_comments.size)
    assert_equal(0,           siva_assignment.complete)
    assert_equal(@siva_e.id,  siva_assignment.user_id)
    assert_equal(1,           mathi_assignment.oi_assignment_comments.size)
    assert_equal(0,           mathi_assignment.complete)
    assert_equal(@mathi_n.id, mathi_assignment.user_id)

    cc_list = expected_cc_list.dup
    email = @emails.pop
    assert_equal([@siva_e.email], email.to.sort)
    assert_equal(cc_list.sort,    email.cc.sort)
    assert_equal("#{@mx234a.name}:: Work Assignment Update - Reopened",
                 email.subject)
    
  end


  ######################################################################
  #
  # test_report_card_list
  #
  # Description:
  # This method does the functional testing of the report card list view.
  #
  ######################################################################
  #
  def test_report_card_list
  
    set_user(@scott_g.id, 'Designer')
    post(:report_card_list,
         :id        => @board_prep.id,
         :design_id => @mx234a.id)
         
    assert_equal(@mx234a.id,     assigns(:design).id)
    assert_equal(@board_prep.id, assigns(:category).id)
    assert_nil(assigns(:assignments_list))
    
  end

  
end
