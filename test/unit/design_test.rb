########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_test.rb
#
# This file contains the unit tests for the design model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class DesignTest < Test::Unit::TestCase
  fixtures(:designs,
           :design_review_comments,
           :priorities,
           :review_types,
           :roles,
           :users)

  def setup
    @design = Design.find(1)
  end

  ######################################################################
  #
  # test_people
  #
  # Description:
  # Validates the behaviour of the following methods.
  #
  #   designer()
  #   peer()
  #   input_gate()
  #
  ######################################################################
  #
  def test_people
  
    # Verify the behavior when the IDs are not set.
    new_design = Design.new
    assert_equal('Not Assigned', new_design.designer.name)
    assert_equal('Not Assigned', new_design.peer.name)
    assert_equal('Not Assigned', new_design.input_gate.name)
    
    # Verify the correct name when the designer_id is set.
    assert_equal('Robert Goldin', designs(:mx600a).designer.name)
    assert_equal('Scott Glover',  designs(:mx600a).peer.name)
    assert_equal('Cathy McLaren', designs(:mx600a).input_gate.name)
    
  end
  
  
  ######################################################################
  #
  # test_all_reviewers
  #
  # Description:
  # Validates the behaviour of the following methods.
  #
  #   all_reviewers()
  #
  ######################################################################
  #
  def test_all_reviewers
  
    expected_reviewers =
      [ users(:espo),      users(:heng_k),    users(:lee_s),
        users(:dave_m),    users(:tom_f),     users(:anthony_g),
        users(:cathy_m),   users(:john_g),    users(:matt_d),
        users(:art_d),     users(:dan_g),     users(:rich_a),
        users(:lisa_a),    users(:jim_l),     users(:eileen_c) ]

    assert_equal(expected_reviewers, designs(:mx234a).all_reviewers)
    
    sorted = true
    expected_reviewers =
      expected_reviewers.sort_by { |u| u.last_name }
    assert_equal(expected_reviewers, designs(:mx234a).all_reviewers(sorted))
    
  end
  
  
  ######################################################################
  #
  # test_get_associated_users
  #
  # Description:
  # Validates the behaviour of the following methods.
  #
  #   get_associated_users()
  #
  ######################################################################
  #
  def test_get_associated_users
  
    mx234a_users = designs(:mx234a).get_associated_users
    
    assert_equal(users(:bob_g),   mx234a_users[:designer])
    assert_equal(users(:scott_g), mx234a_users[:peer])
    assert_equal(users(:cathy_m), mx234a_users[:pcb_input])
    
    reviewers = mx234a_users[:reviewers].sort_by{ |u| u.last_name }
    expected_reviewers = [
      users(:rich_a),     users(:lisa_a),     users(:eileen_c),
      users(:art_d),      users(:matt_d),     users(:espo),
      users(:tom_f),      users(:anthony_g),  users(:john_g),
      users(:dan_g),      users(:jim_l),      users(:dave_m),
      users(:cathy_m),    users(:lee_s),      users(:heng_k)
    ]
    assert_equal(expected_reviewers, reviewers)

  end
  

  ######################################################################
  #
  # test_get_associated_users_by_role
  #
  # Description:
  # Validates the behaviour of the following methods.
  #
  #   get_associated_users_by_role()
  #
  ######################################################################
  #
  def test_get_associated_users_by_role
  
    mx234a_users = designs(:mx234a).get_associated_users_by_role
    expected_users = {
      :designer                      => users(:bob_g),
      :peer                          => users(:scott_g),
      :pcb_input                     => users(:cathy_m),
      'PCB_Mechanical'               => users(:john_g),
      'PCB Input Gate'               => users(:cathy_m),
      'DFM'                          => users(:heng_k),
      'SLM-Vendor'                   => users(:dan_g),
      'Operations Manager'           => users(:eileen_c),
      'PCB Design'                   => users(:jim_l),
      'HWENG'                        => users(:lee_s),
      'Planning'                     => users(:matt_d),
      'CE-DFT'                       => users(:espo),
      'Valor'                        => users(:lisa_a),
      'Mechanical'                   => users(:tom_f),
      'SLM BOM'                      => users(:art_d),
      'Mechanical-MFG'               => users(:anthony_g),
      'Library'                      => users(:dave_m),
      'TDE'                          => users(:rich_a),
      'Hardware Engineering Manager' => User.new(:first_name => 'Not', 
                                                 :last_name => 'Set'),
      'Program Manager'              => User.new(:first_name => 'Not', 
                                                 :last_name => 'Set')
    }
    
    assert_equal(expected_users.size,
                 mx234a_users.size)
    mx234a_users.each { |key, value|
      if expected_users[key]
        assert_equal(expected_users[key].name, value.name)
      end
    }
    
  end
  
  
  ######################################################################
  #
  # test_types
  #
  # Description:
  # Validates the behaviour of the following methods.
  #
  #   new?()
  #   date_code?()
  #   dot_rev?()
  #
  ######################################################################
  #
  def test_types 
  
    assert_equal(true,  designs(:mx234a).new?)
    assert_equal(false, designs(:mx234a).date_code?)
    assert_equal(false, designs(:mx234a).dot_rev?)
    
    assert_equal(false, designs(:la453a_eco1).new?)
    assert_equal(true,  designs(:la453a_eco1).date_code?)
    assert_equal(false, designs(:la453a_eco1).dot_rev?)
  
    assert_equal(false, designs(:la453a1).new?)
    assert_equal(false, designs(:la453a1).date_code?)
    assert_equal(true,  designs(:la453a1).dot_rev?)
  
  end


  ######################################################################
  #
  # test_accessors
  #
  # Description:
  # Validates the behaviour of the following methods.
  #
  #   name()
  #   phase()
  #   priority_name()
  #   belongs_to()
  #
  ######################################################################
  #
 def test_accessors
 
   design = Design.new

   assert_equal('Not Started', design.phase.name)

   design.phase_id = ReviewType.find_by_name('Final').id
   assert_equal('Final', design.phase.name)
   
   design.phase_id = Design::COMPLETE
   assert_equal("Complete", design.phase.name)
   
   
   assert_equal('Not Set', design.priority_name)
   
   design.priority_id = Priority.find_by_name('High').id
   assert_equal('High', design.priority_name)
   
   
   assert_equal('mx234a',       designs(:mx234a).name)
   assert_equal('la453a2',      designs(:la453a2).name)
   assert_equal('la453b4_eco2', designs(:la453b4_eco2).name)
   
   
   section_all        = Section.new(:full_review     => 1,
                                    :date_code_check => 1,
                                    :dot_rev_check   => 1)
   section_nothing    = Section.new(:full_review     => 0,
                                    :date_code_check => 0,
                                    :dot_rev_check   => 0)
   subsection_all     = Subsection.new(:full_review     => 1,
                                       :date_code_check => 1,
                                       :dot_rev_check   => 1)
   subsection_nothing = Subsection.new(:full_review     => 0,
                                       :date_code_check => 0,
                                       :dot_rev_check   => 0)
   check_all          = Check.new(:full_review     => 1,
                                  :date_code_check => 1,
                                  :dot_rev_check   => 1)
   check_nothing      = Check.new(:full_review     => 0,
                                  :date_code_check => 0,
                                  :dot_rev_check   => 0)
   
   design.design_type = 'New'
   assert(design.belongs_to(section_all))
   assert(!design.belongs_to(section_nothing))
   assert(design.belongs_to(subsection_all))
   assert(!design.belongs_to(subsection_nothing))
   assert(design.belongs_to(check_all))
   assert(!design.belongs_to(check_nothing))
   
   design.design_type = 'Date Code'
   assert(design.belongs_to(section_all))
   assert(!design.belongs_to(section_nothing))
   assert(design.belongs_to(subsection_all))
   assert(!design.belongs_to(subsection_nothing))
   assert(design.belongs_to(check_all))
   assert(!design.belongs_to(check_nothing))

   design.design_type = 'Dot Rev'
   assert(design.belongs_to(section_all))
   assert(!design.belongs_to(section_nothing))
   assert(design.belongs_to(subsection_all))
   assert(!design.belongs_to(subsection_nothing))
   assert(design.belongs_to(check_all))
   assert(!design.belongs_to(check_nothing))
 
 end
 
 
 ######################################################################
 def test_increment_review
 
  # Verify a design where no reviews are skipped.
  mx234a = designs(:mx234a)
  assert_equal(review_types(:pre_artwork).id, mx234a.phase_id)
  mx234a.increment_review
  mx234a.reload
  assert_equal(review_types(:placement).id,   mx234a.phase_id)
  mx234a.increment_review
  mx234a.reload
  assert_equal(review_types(:routing).id,     mx234a.phase_id)
  mx234a.increment_review
  mx234a.reload
  assert_equal(review_types(:final).id,       mx234a.phase_id)
  mx234a.increment_review
  mx234a.reload
  assert_equal(review_types(:release).id,     mx234a.phase_id)
  mx234a.increment_review
  mx234a.reload
  assert_equal(Design::COMPLETE,              mx234a.phase_id)
  
  # Reset and try with the Placement and Routing reviews set to skipped.
  mx234a.phase_id  = review_types(:pre_artwork).id
  review_skipped   = ReviewStatus.find_by_name("Review Skipped")
  placement_review = mx234a.design_reviews.detect { |dr| dr.review_type_id == review_types(:placement).id }
  routing_review   = mx234a.design_reviews.detect { |dr| dr.review_type_id == review_types(:routing).id }
  placement_review.review_status = review_skipped
  placement_review.update
  routing_review.review_status = review_skipped
  routing_review.update
  
  assert_equal(review_types(:pre_artwork).id, mx234a.phase_id)
  mx234a.increment_review
  mx234a.reload
  assert_equal(review_types(:final).id,       mx234a.phase_id)
  mx234a.increment_review
  mx234a.reload
  assert_equal(review_types(:release).id,     mx234a.phase_id)
  mx234a.increment_review
  mx234a.reload
  assert_equal(Design::COMPLETE,              mx234a.phase_id)

  # Reset and try with all of the reviews set to skipped.
  mx234a.phase_id  = review_types(:pre_artwork).id
  mx234a.design_reviews.each do |dr|
    dr.review_status = review_skipped
    dr.update
  end
  
  assert_equal(review_types(:pre_artwork).id, mx234a.phase_id)
  mx234a.increment_review
  mx234a.reload
  assert_equal(Design::COMPLETE,              mx234a.phase_id)

 end
 
 
 ######################################################################
 def test_next_review
 
  # Verify a design where no reviews are skipped.
  mx234a = designs(:mx234a)
  assert_equal(review_types(:pre_artwork).id, mx234a.phase_id)
  
  next_review_id = mx234a.next_review
  assert_equal(review_types(:placement).id,   next_review_id)
  mx234a.phase_id = next_review_id

  next_review_id  = mx234a.next_review
  assert_equal(review_types(:routing).id,     next_review_id)
  mx234a.phase_id = next_review_id
  
  next_review_id  = mx234a.next_review
  assert_equal(review_types(:final).id,       next_review_id)
  mx234a.phase_id = next_review_id
  
  next_review_id  = mx234a.next_review
  assert_equal(review_types(:release).id,     next_review_id)
  mx234a.phase_id = next_review_id
  
  next_review_id  = mx234a.next_review
  assert_equal(Design::COMPLETE,              next_review_id)
  
  # Reset and try with the Placement and Routing reviews set to skipped.
  mx234a.phase_id  = review_types(:pre_artwork).id
  review_skipped   = ReviewStatus.find_by_name("Review Skipped")
  placement_review = mx234a.design_reviews.detect { |dr| dr.review_type_id == review_types(:placement).id }
  routing_review   = mx234a.design_reviews.detect { |dr| dr.review_type_id == review_types(:routing).id }
  placement_review.review_status = review_skipped
  placement_review.update
  routing_review.review_status = review_skipped
  routing_review.update
  
  assert_equal(review_types(:pre_artwork).id, mx234a.phase_id)
  
  next_review_id = mx234a.next_review
  assert_equal(review_types(:final).id,       next_review_id)
  mx234a.phase_id = next_review_id
  
  next_review_id = mx234a.next_review
  assert_equal(review_types(:release).id,     next_review_id)
  mx234a.phase_id = next_review_id
  
  next_review_id = mx234a.next_review
  assert_equal(Design::COMPLETE,              next_review_id)

  # Reset and try with all of the reviews set to skipped.
  mx234a.phase_id  = review_types(:pre_artwork).id
  mx234a.design_reviews.each do |dr|
    dr.review_status = review_skipped
    dr.update
  end
  
  assert_equal(review_types(:pre_artwork).id, mx234a.phase_id)
  
  next_review_id = mx234a.next_review
  assert_equal(Design::COMPLETE,              next_review_id)

 end
 
 
  ######################################################################
  def test_role_functions

    test_data = [ { :role     => roles(:admin),
                    :comments => [design_review_comments(:comment_four),
                                  design_review_comments(:comment_one)] },
                  { :role     => roles(:designer),
                    :comments => [design_review_comments(:comment_six),
                                  design_review_comments(:comment_three)] },
                  { :role     => roles(:manager),
                    :comments => [design_review_comments(:comment_five),
                                  design_review_comments(:comment_two)] },
                  { :role     => roles(:hweng),
                    :comments => [] },
                  { :role     => roles(:valor),
                    :comments => [design_review_comments(:comment_six),
                                  design_review_comments(:comment_three)] },
                  { :role     => roles(:ce_dft),
                    :comments => [] },
                  { :role     => roles(:dfm),
                    :comments => [] },
                  { :role     => roles(:tde),
                    :comments => [] },
                  { :role     => roles(:mechanical),
                    :comments => [] },
                  { :role     => roles(:pcb_design),
                    :comments => [design_review_comments(:comment_five),
                                  design_review_comments(:comment_two)] },
                  { :role     => roles(:planning),
                    :comments => [] },
                  { :role     => roles(:pcb_input_gate),
                    :comments => [design_review_comments(:comment_four),
                                  design_review_comments(:comment_one)] },
                  { :role     => roles(:library),
                    :comments => [] },
                  { :role     => roles(:pcb_mechanical),
                    :comments => [] },
                  { :role     => roles(:slm_bom),
                    :comments => [] },
                  { :role     => roles(:slm_vendor),
                    :comments => [] },
                  { :role     => roles(:operations_manager),
                    :comments => [] },
                  { :role     => roles(:pcb_admin),
                    :comments => [] },
                  { :role     => roles(:program_manager),
                    :comments => [] },
                  { :role     => roles(:compliance_emc),
                    :comments => [] },
                  { :role     => roles(:compliance_safety),
                    :comments => [] },
                  { :role     => roles(:hweng_manager),
                    :comments => [] },
                  { :role     => roles(:mechanical_manufacturing),
                    :comments => [] } ]
  
    test_data.each do |test|
      assert_equal(test[:comments], @design.comments_by_role(test[:role].name))
    end
    
    assert_equal([design_review_comments(:comment_six),
                  design_review_comments(:comment_four),
                  design_review_comments(:comment_three),
                  design_review_comments(:comment_one)],
                 @design.comments_by_role(['Designer',           'Valor', 
                                           'Operations Manager', 'PCB Input Gate']))

    assert_equal([design_review_comments(:comment_four),
                  design_review_comments(:comment_one)],
                 @design.comments_by_role(['PCB Admin',          'Operations Manager',
                                           'PCB Input Gate']))
  
  end
    

end
