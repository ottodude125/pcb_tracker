########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: board_controller_test.rb
#
# This file contains the functional tests for the board controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'board_controller'

# Re-raise errors caught by the controller.
class BoardController; def rescue_action(e) raise e end; end

class BoardControllerTest < Test::Unit::TestCase
  def setup
    @controller = BoardController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:audits,
           :board_reviewers,
           :boards,
           :design_review_documents,
           :design_review_results,
           :design_reviews,
           :designs,
           :fab_houses,
           :ipd_posts,
           :part_numbers,
           :platforms,
           :prefixes,
           :priorities,
           :projects,
           :review_statuses,
           :review_types,
           :revisions,
           :users)


  ######################################################################
  #
  # test_filtered_list
  #
  # Description:
  # This method does the functional testing of the filtered_list method
  #
  ######################################################################
  #
  def test_filtered_list

  end
  
  
  ######################################################################
  #
  # test_show_boards
  #
  # Description:
  # This method does the functional testing of the show_boards method
  #
  ######################################################################
  #
  def test_show_boards
  
    get(:show_boards)

    assert_equal(1, assigns(:rows))
    assert_equal(8, assigns(:columns))
    
    unique_pcb_part_numbers = Design.get_unique_pcb_numbers
    assert_equal(8, unique_pcb_part_numbers.size)
    
    part_numbers = assigns(:part_numbers)
    assert_equal(1, part_numbers.size)
    assert_equal(8, part_numbers[0].size)

    row = 0
    col = 0
    unique_pcb_part_numbers.each_with_index do |pn, i|
      assert_equal(pn, part_numbers[row][col])
      col += 1
      if col == assigns(:columns)
        col  = 0
        row += 1
      end
    end
    
  end
  
  
  ######################################################################
  #
  # test_design_information
  #
  # Description:
  # This method does the functional testing of the design_information
  # method
  #
  ######################################################################
  #
  def test_design_information

  end


  ######################################################################
  #
  # test_board_design_search
  #
  # Description:
  # This method does the functional testing of the board_design_search
  # method
  #
  ######################################################################
  #
  def test_board_design_search
  
    all_boards = { 'mx232' => { :id           => boards(:boards_027).id,
                                :all_designs  => 1,
                                :post_final   => 0,
                                :post_release => 0,
                                :sg_designs   => 1 },
                   'mx234' => { :id           => boards(:mx234).id,
                                :all_designs  => 3,
                                :post_final   => 0,
                                :post_release => 0,
                                :sg_designs   => 0 },
                   'la453' => { :id           => boards(:la453).id,
                                :all_designs  => 3,
                                :post_final   => 1,
                                :post_release => 1,
                                :sg_designs   => 2 },
                   'la454' => { :id           => boards(:la454).id,
                                :all_designs  => 1,
                                :post_final   => 0,
                                :post_release => 0,
                                :sg_designs   => 0 },
                   'la455' => { :id           => boards(:la455).id,
                                :all_designs  => 1,
                                :post_final   => 0,
                                :post_release => 0,
                                :sg_designs   => 1 },
                   'mx600' => { :id           => boards(:mx600).id,
                                :all_designs  => 1,
                                :post_final   => 0,
                                :post_release => 0,
                                :sg_designs   => 0 },
                   'mx700' => { :id           => boards(:mx700).id,
                                :all_designs  => 1,
                                :post_final   => 0,
                                :post_release => 0,
                                :sg_designs   => 0 },
                   'mx999' => { :id           => boards(:mx999).id,
                                :all_designs  => 3,
                                :post_final   => 0,
                                :post_release => 0,
                                :sg_designs   => 0 } }
  
    get(:board_design_search,
        { :platform    => { :id    => '' },
          :project     => { :id    => '' },
          :user        => { :id    => '' },
          :review_type => { :phase => 'All'} },
        {})
         
    assert_equal('All Projects',  assigns(:project))
    assert_equal('All Platforms', assigns(:platform))
    assert_equal('All Designers', assigns(:designer))
    
    board_list = assigns(:board_list)
    assert_equal(all_boards.size, board_list.size)

    board_list.each do |board|
      expected_brd = all_boards.detect { |k,v| k == board.name}
      assert_not_nil(expected_brd)

      expected_board = Board.find(expected_brd[1][:id])
      assert_equal(expected_brd[1][:all_designs], board.designs.size)
    end 


    get(:board_design_search,
        { :platform    => { :id    => '' },
          :project     => { :id    => '2' },
          :user        => { :id    => '' },
          :review_type => { :phase => 'All' } },
        {})
         
    assert_equal('AWG5000',       assigns(:project))
    assert_equal('All Platforms', assigns(:platform))
    assert_equal('All Designers', assigns(:designer))
    
    board_list = assigns(:board_list)
    assert_equal(3, board_list.size)
    
    board_list.each do |board|
      expected_brd = all_boards.detect { |k,v| k == board.name}
      assert_not_nil(expected_brd)

      expected_board = Board.find(expected_brd[1][:id])
      assert_equal(expected_brd[1][:all_designs], board.designs.size)
    end 


    get(:board_design_search,
         { :platform    => { :id    => '1' },
          :project     => { :id    => '' },
          :user        => { :id    => '' },
          :review_type => { :phase => 'All' } },
         {})
         
    assert_equal('All Projects',  assigns(:project))
    assert_equal('Catalyst',      assigns(:platform))
    assert_equal('All Designers', assigns(:designer))
    
    board_list = assigns(:board_list)
    assert_equal(4, board_list.size)
    
    board_list.each do |board|
      expected_brd = all_boards.detect { |k,v| k == board.name}
      assert_not_nil(expected_brd)

      expected_board = Board.find(expected_brd[1][:id])
      assert_equal(expected_brd[1][:all_designs], board.designs.size)
    end 


    get(:board_design_search,
        { :platform    => { :id    => '2' },
          :project     => { :id    => '2' },
          :user        => { :id    => '' },
          :review_type => { :phase => 'All' } },
        {})
         
    assert_equal('AWG5000',       assigns(:project))
    assert_equal('FLEX',          assigns(:platform))
    assert_equal('All Designers', assigns(:designer))
    
    board_list = assigns(:board_list)
    assert_equal(3, board_list.size)
    
    board_list.each do |board|
      expected_brd = all_boards.detect { |k,v| k == board.name}
      assert_not_nil(expected_brd)

      expected_board = Board.find(expected_brd[1][:id])
      assert_equal(expected_brd[1][:all_designs], board.designs.size)
    end 


    get(:board_design_search,
        { :platform    => { :id    => '' },
          :project     => { :id    => '' },
          :user        => { :id    => users(:scott_g).id },
          :review_type => { :phase => 'All' } },
        {})
         
    assert_equal('All Projects',  assigns(:project))
    assert_equal('All Platforms', assigns(:platform))
    assert_equal('Scott Glover',  assigns(:designer))
    
    board_list = assigns(:board_list)
    assert_equal(all_boards.size, board_list.size)
    
    board_list.each do |board|
      expected_brd = all_boards.detect { |k,v| k == board.name}
      assert_not_nil(expected_brd)

      expected_board = Board.find(expected_brd[1][:id])
      assert_equal(expected_brd[1][:sg_designs], board.designs.size)
    end 


    get(:board_design_search,
        { :platform    => { :id    => '' },
          :project     => { :id    => '' },
          :user        => { :id    => '' },
          :review_type => { :phase => 'Final' } },
        {})
         
    assert_equal('All Projects',  assigns(:project))
    assert_equal('All Platforms', assigns(:platform))
    assert_equal('All Designers', assigns(:designer))
    
    board_list = assigns(:board_list)
    assert_equal(all_boards.size, board_list.size)
    board_list.each do |board|
      expected_brd = all_boards.detect { |k,v| k == board.name}
      assert_not_nil(expected_brd)

      expected_board = Board.find(expected_brd[1][:id])
      assert_equal(expected_brd[1][:post_final], board.designs.size)
    end 


    post(:board_design_search,
         { :platform    => { :id    => '' },
           :project     => { :id    => '' },
           :user        => { :id    => '' },
           :review_type => { :phase => 'Release' } },
         {})
         
    assert_equal('All Projects',  assigns(:project))
    assert_equal('All Platforms', assigns(:platform))
    assert_equal('All Designers', assigns(:designer))
    
    board_list = assigns(:board_list)
    assert_equal(all_boards.size, board_list.size)
    
    board_list.each do |board|
      expected_brd = all_boards.detect { |k,v| k == board.name}
      assert_not_nil(expected_brd)

      expected_board = Board.find(expected_brd[1][:id])
      assert_equal(expected_brd[1][:post_release], board.designs.size)
    end 

  end


  ######################################################################
  #
  # test_design_information
  #
  # Description:
  # This method does the functional testing of the design_information
  # method
  #
  ######################################################################
  #
  def test_design_information
  
    expected_designs = Design.find(:all)
    expected_designs.delete_if do |d| 
      !(d.part_number.pcb_prefix == '942' && d.part_number.pcb_number == '453') 
    end
    
    get(:design_information, { :part_number => '942-453' }, {})
    
    assert_response(:success)
    designs = assigns(:designs)
    assert_equal(expected_designs.size, designs.size)
    
    expected_designs.each { |ed| designs.delete_if { |d| d.id == ed.id } }
    assert_equal(0, designs.size)
  
  end
  
  
  ######################################################################
  #
  # test_seach_options
  #
  # Description:
  # This method does the functional testing of the seach_options
  # method
  #
  ######################################################################
  #
  def test_search_options
  
    platform_ids = Platform.find(:all).collect   { |p| p.id }
    project_ids  = Project.get_projects.collect  { |p| p.id }
    users        = User.find(:all)

    designers = User.find(:all).delete_if do |u| 
      !u.roles.detect { |r| r.name == "Designer" } 
    end
    designers = designers.sort_by { |d| d.id }
    
    login_list = [nil,             # Nobody
                  { :id => users(:scott_g).id, :role => 'Designer' }, 
                  { :id => users(:pat_a).id,   :role => 'DFM' }]
                  
    login_list.each do |login|
    
      session = login ? set_session(login[:id], login[:role]) : {}

      # Call without being logged in and verify the data
      post(:search_options, {}, session)

      if login && login[:role] == 'Designer'
        assert_equal(login[:id], assigns(:designer).id)
      else
        assert_nil(assigns(:designer))
      end
    
      platforms = assigns(:platforms)
      assert_equal(platform_ids.size, platforms.size)
      platform_ids.each { |id| assert_not_nil(platforms.detect { |p| p.id == id }) }
    
      projects  = assigns(:projects)
      assert_equal(project_ids.size, projects.size)
      project_ids.each { |id| assert_not_nil(projects.detect { |p| p.id == id }) }
      
      assert_equal(designers, assigns(:designers).sort_by  { |d| d.id })
      
    end

  end
  
  
end
