########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_controller_test.rb
#
# This file contains the functional tests for the design controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'design_controller'

# Re-raise errors caught by the controller.
class DesignController; def rescue_action(e) raise e end; end

class DesignControllerTest < Test::Unit::TestCase
  def setup
    @controller = DesignController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:audits,
           :boards,
           :boards_fab_houses,
           :board_reviewers,
           :designs,
           :design_checks,
           :design_review_results,
           :design_reviews,
	   :fab_houses,
           :review_status,
           :review_types,
           :review_types_roles,
           :revisions,
           :roles,
           :roles_users,
           :suffixes,
           :users)


  def test_1_id
    print("\n*** Design Controller Test\n")
    print("*** $Id$\n")
  end


  ######################################################################
  #
  # test_add
  #
  # Description:
  # This method does the functional testing of the add method
  # from the Design class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def test_add
    
    la453 = Board.find(boards(:la453).id)
    set_admin
    post(:add,
         :board_id => la453.id)

    details = flash[:details]
    assert_equal(la453.id,  details[:board_id])
    assert_equal("la453",   details[:design_name])
    assert_equal("FLEX",    details[:platform])
    assert_equal("AWG5000", details[:project])

  end


  ######################################################################
  #
  # test_create
  #
  # Description:
  # This method does the functional testing of the create method
  # from the Design class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # To Do: Test for duplicate board entry.
  #
  ######################################################################
  #
  def test_create
    
    la453    = boards(:la453)
    bob_g    = users(:bob_g)
    scott_g  = users(:scott_g)
    rev_a    = revisions(:rev_a)
    suffix_2 = suffixes(:suffix_2)
    set_admin
    post(:add,
         :board_id => la453.id)

    post(:select_revision,
         :type => 'Date Code')

    post(:select_suffix,
         :id => rev_a.id)

    post(:select_complete,
         :suffix_id => suffix_2.id)

    details = flash[:details]

    assert_equal(5,  Design.find_all("board_id='#{details[:board_id]}'").size)
    assert_equal(45, DesignReview.find_all.size)
    assert_equal(51, DesignReviewResult.find_all.size)
    assert_equal(15, Audit.find_all.size)
    assert_equal(43, DesignCheck.find_all.size)

    board_reviewers = {
      'CE-DFT'             => '7101',
      'HWENG'              => '6000',
      'DFM'                => '7150',
      'Library'            => '7401',
      'Mechanical'         => '7251',
      'Mechanical-MFG'     => '7251',
      'Operations Manager' => '7301',
      'PCB Design'         => '4001',
      'PCB Input Gate'     => '4000',
      'PCB Mechanical'     => '7451',
      'Planning'           => '7651',
      'SLM BOM'            => '7500',
      'SLM-Vendor'         => '7550',
      'TDE'                => '7201',
      'Valor'              => '5002'}

    reviewer_flags = {
      'CE-DFT'             => '0',
      'HWENG'              => '1',
      'DFM'                => '1',
      'Library'            => '1',
      'Mechanical'         => '1',
      'Mechanical-MFG'     => '0',
      'Operations Manager' => '1',
      'PCB Design'         => '1',
      'PCB Input Gate'     => '1',
      'PCB Mechanical'     => '1',
      'Planning'           => '1',
      'SLM BOM'            => '1',
      'SLM-Vendor'         => '1',
      'TDE'                => '1',
      'Valor'              => '1'}

    fab_house_selections = {
      '1' => '0',
      '2' => '1',
      '3' => '0',
      '4' => '1',
      '5' => '0',
      '6' => '1',
      '7' => '0',
      '8' => '1'}

    post(:create,
         :review_type     => {"Pre-Artwork" => '1',
                              "Placement"   => '0',
                              "Routing"     => '0',
                              "Final"       => '1',
                              "Release"     => '1'},
         :board_reviewers => board_reviewers,
         :reviewer        => reviewer_flags,
         :fab_house       => fab_house_selections,
         :priority        => {:id => 2})

    designs = Design.find_all("board_id='#{details[:board_id]}'",
                              'created_on ASC')
    assert_equal(6, designs.size)

    new_design = designs.pop

    assert_equal(la453.id,      new_design.board_id)
    assert_equal("Date Code",   new_design.design_type)
    assert_equal(rev_a.id,      new_design.revision_id)
    assert_equal(suffix_2.id,   new_design.suffix_id)
    assert_equal('la453a_eco2', new_design.name)

    assert_equal(50, DesignReview.find_all.size)
    design_reviews = DesignReview.find_all("design_id='#{new_design.id}'")
    assert_equal(5,  design_reviews.size)
    # Verify the the design review results table was updated.
    assert_equal(78, DesignReviewResult.find_all.size)
    assert_equal(46, DesignCheck.find_all.size)

    expected_vals = {
      'Pre-Artwork' => {
        :status     => 'Not Started',
        :roles      => [5, 6, 8, 9, 10, 13, 14, 15, 16, 17, 18]},
      'Placement'   => {
        :status     => 'Review Skipped',
        :roles      => [5, 8, 9, 10]},
      'Routing'     => {
        :status     => 'Review Skipped',
        :roles      => [5, 8]},
      'Final'       => {
        :status     => 'Not Started',
        :roles      => [5, 6, 8, 9, 10, 12, 13]},
      'Release'     => {
        :status     => 'Not Started',
        :roles      => [5, 12, 19]}}

    for design_review in design_reviews

      expect = expected_vals[design_review.review_type.name]
      assert_equal(expect[:status],
                   design_review.review_status.name)

      design_review_results =
        DesignReviewResult.find_all("design_review_id='#{design_review.id}'")
      assert_equal(expect[:roles].size, design_review_results.size)
      
      roles = Array.new
      for drr in design_review_results
        roles.push(drr.role_id)
      end
      assert_equal(expect[:roles], roles.sort)

    end


    assert_equal(16, Audit.find_all.size)
    assert_equal(1,  Audit.find_all("design_id='#{new_design.id}'").size)

  end


  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the create method
  # from the Design class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # To Do: Test for duplicate board entry.
  #
  ######################################################################
  #
  def test_list
    
    print("?")
    assert true

  end


  ######################################################################
  #
  # test_select_complete
  #
  # Description:
  # This method does the functional testing of the select_complete method
  # from the Design class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # To Do: Test for duplicate board entry.
  #
  ######################################################################
  #
  def test_select_complete
    
    la453    = boards(:la453)
    bob_g    = users(:bob_g)
    scott_g  = users(:scott_g)
    rev_a    = revisions(:rev_a)
    suffix_2 = suffixes(:suffix_2)
    set_admin
    post(:add,
         :board_id => la453.id)

    post(:select_revision,
         :type => 'Date Code')

    post(:select_suffix,
         :id => rev_a.id)

    post(:select_complete,
         :suffix_id => suffix_2.id)

    details = flash[:details]
    assert_equal(la453.id,         details[:board_id])
    assert_equal("Date Code",      details[:design_type])
    assert_equal(rev_a.id.to_s,    details[:revision_id])
    assert_equal(suffix_2.id.to_s, details[:suffix_id])
    assert_equal('la453a_eco2',    details[:design_name])
    assert_equal('FLEX',           details[:platform])
    assert_equal('AWG5000',        details[:project])

    review_types = assigns(:review_types)

    pre_artwork = review_types(:pre_artwork)
    placement   = review_types(:placement)
    routing     = review_types(:routing)
    final       = review_types(:final)
    release     = review_types(:release)
    assert_equal(5, review_types.size)
    assert_equal(pre_artwork.name, review_types.shift.name)
    assert_equal(placement.name,   review_types.shift.name)
    assert_equal(routing.name,     review_types.shift.name)
    assert_equal(final.name,       review_types.shift.name)
    assert_equal(release.name,     review_types.shift.name)
    assert_equal(0, review_types.size)

    expected_reviewers = [
      {:group          => 'CE-DFT',
       :reviewer_count => 2,
       :selected       => 7100,
       :group_list     => [7100, 7101]},
      {:group          => 'DFM',
       :reviewer_count => 3,
       :selected       => 7151,
       :group_list     => [6001, 7150, 7151]},
      {:group          => 'Hardware Engineering Manager',
       :reviewer_count => 2,
       :selected       => 18501,
       :group_list     => [18500, 18501]},
      {:group          => 'HWENG',
       :reviewer_count => 4,
       :selected       => 6000,
       :group_list     => [6000, 7000, 7001, 7200]},
      {:group          => 'Library',
       :reviewer_count => 2,
       :selected       => 7401,
       :group_list     => [7400, 7401]},
      {:group          => 'Mechanical',
       :reviewer_count => 2,
       :selected       => 7250,
       :group_list     => [7250, 7251]},
      {:group          => 'Mechanical-MFG',
       :reviewer_count => 2,
       :selected       => 7300,
       :group_list     => [7300, 7301]},
      {:group          => 'Operations Manager',
       :reviewer_count => 2,
       :selected       => 7600,
       :group_list     => [7600, 7601]},
      {:group          => 'PCB Design',
       :reviewer_count => 1,
       :selected       => 4001,
       :group_list     => [4001]},
      {:group          => 'PCB Input Gate',
       :reviewer_count => 2,
       :selected       => 7350,
       :group_list     => [4000, 7350]},
      {:group          => 'PCB Mechanical',
       :reviewer_count => 2,
       :selected       => 7451,
       :group_list     => [7450, 7451]},
      {:group          => 'Planning',
       :reviewer_count => 2,
       :selected       => 7651,
       :group_list     => [7650, 7651]},
      {:group          => 'Program Manager',
       :reviewer_count => 2,
       :selected       => 19000,
       :group_list     => [19000, 19001]},
      {:group          => 'SLM BOM',
       :reviewer_count => 1,
       :selected       => 7500,
       :group_list     => [7500]},
      {:group          => 'SLM-Vendor',
       :reviewer_count => 1,
       :selected       => 7550,
       :group_list     => [7550]},
      {:group          => 'TDE',
       :reviewer_count => 2,
       :selected       => 7200,
       :group_list     => [7200, 7201]},
      {:group          => 'Valor',
       :reviewer_count => 4,
       :selected       => 7050,
       :group_list     => [5000, 5001, 5002, 7050]}
    ]

    reviewers = assigns(:reviewers)

    while reviewers.size > 0
      reviewer_list = reviewers.shift
      expected = expected_reviewers.shift

      assert_equal(expected[:group],          reviewer_list[:group])
      assert_equal(expected[:reviewer_count], reviewer_list[:reviewers].size)
      assert_equal(expected[:selected],       reviewer_list[:reviewer_id])
      assert(expected[:group_list].include?(reviewer_list[:reviewer_id]),
             "The selected reviewer (#{reviewer_list[:reviewer_id]}) is not in the list of expected values.")

      group_list = Array.new
      for select in reviewer_list[:reviewers]
        group_list.push(select.id)
      end
      assert_equal(expected[:group_list], group_list.sort)
    end

  end


  ######################################################################
  #
  # test_select_revision
  #
  # Description:
  # This method does the functional testing of the select_revision method
  # from the Design class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # To Do: Test for duplicate board entry.
  #
  ######################################################################
  #
  def test_select_revision
    
    la453   = boards(:la453)
    bob_g   = users(:bob_g)
    scott_g = users(:scott_g)
    set_admin
    post(:add,
         :board_id => la453.id)

    post(:select_revision,
         :type => 'Date Code')

    details = flash[:details]
    assert_equal(la453.id,    details[:board_id])
    assert_equal("Date Code", details[:design_type])
    assert_equal("la453",     details[:design_name])
    assert_equal("FLEX",      details[:platform])

    revisions = assigns(:revisions)
    assert_equal(2,   revisions.size)
    assert_equal('b', revisions.shift.name)
    assert_equal('a', revisions.shift.name)


    post(:select_revision,
         :type => 'New')

    details = flash[:details]

    assert_equal("New", details[:design_type])

    revisions = assigns(:revisions)
    assert_equal(5,   revisions.size)
    assert_equal(revisions(:rev_c).name, revisions.shift.name)
    assert_equal(revisions(:rev_d).name, revisions.shift.name)
    assert_equal(revisions(:rev_e).name, revisions.shift.name)
    assert_equal(revisions(:rev_f).name, revisions.shift.name)
    assert_equal(revisions(:rev_g).name, revisions.shift.name)
    assert_equal(0,   revisions.size)

  end


  ######################################################################
  #
  # test_seletc_suffix
  #
  # Description:
  # This method does the functional testing of the select_suffix method
  # from the Design class
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  # To Do: Test for duplicate board entry.
  #
  ######################################################################
  #
  def test_select_suffix
    
    la453   = boards(:la453)
    bob_g   = users(:bob_g)
    scott_g = users(:scott_g)
    rev_a   = revisions(:rev_a)
    set_admin
    post(:add,
         :board_id => la453.id)

    post(:select_revision,
         :type => 'Date Code')

    post(:select_suffix,
         :id => rev_a.id)

    details = flash[:details]
    assert_equal(la453.id,      details[:board_id])
    assert_equal("Date Code",   details[:design_type])
    assert_equal(rev_a.id.to_s, details[:revision_id])
    assert_equal('la453a',      details[:design_name])
    assert_equal('FLEX',        details[:platform])
    assert_equal('AWG5000',     details[:project])

    suffixes = assigns(:suffixes)
    assert_equal(6, suffixes.size)
    assert_equal(suffixes(:suffix_2).name, suffixes.shift.name)
    assert_equal(suffixes(:suffix_3).name, suffixes.shift.name)
    assert_equal(suffixes(:suffix_4).name, suffixes.shift.name)
    assert_equal(suffixes(:suffix_5).name, suffixes.shift.name)
    assert_equal(suffixes(:suffix_6).name, suffixes.shift.name)
    assert_equal(suffixes(:suffix_7).name, suffixes.shift.name)
    assert_equal(0, suffixes.size)

  end
  
  
  private
  
  
  def dump_designs

    print "\n\ndump_designs\n"
    
    designs = Design.find_all
    print "There are #{designs.size} designs\n"
    
    for design in designs
    
      if design.phase_id == 0 
        phase = 'Not Set'
      elsif design.phase_id < 255
        phase = ReviewType.find(design.phase_id).name
      else
        phase = "COMPLETE"
      end
      print "#{design.name} (#{design.id})  phase: #{phase}  #{design.design_reviews.size} design reviews\n"
      for dr in design.design_reviews
        print "#{dr.id} #{dr.review_type.name} - #{dr.review_status.name}"
        print "\n"
      end
      design_review_list = design.design_reviews.sort_by { |dr| dr.review_type.sort_order }
      print "\n"
    
    end
    
    print "\n\n"

  end


end
