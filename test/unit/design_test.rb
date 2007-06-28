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
           :design_centers,
           :design_reviews,
           :design_review_comments,
           :design_review_results,
           :priorities,
           :review_statuses,
           :review_types,
           :roles,
           :users)


  def setup
    @design = Design.find(1)
  end

  ######################################################################
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
  def test_all_reviewers
  
    expected_reviewers =
      [ users(:espo),      users(:heng_k),    users(:lee_s),
        users(:dave_m),    users(:tom_f),     users(:anthony_g),
        users(:cathy_m),   users(:john_g),    users(:matt_d),
        users(:art_d),     users(:dan_g),     users(:rich_a),
        users(:lisa_a),    users(:jim_l),     users(:eileen_c) ]

    #assert_equal(expected_reviewers, designs(:mx234a).all_reviewers)
    
    expected_reviewers = expected_reviewers.sort_by { |u| u.last_name }
    reviewers          = designs(:mx234a).all_reviewers
    
    assert_equal(expected_reviewers.size, reviewers.size)
    assert_equal(expected_reviewers, designs(:mx234a).all_reviewers)
    
  end
  
  
  ######################################################################
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
  def test_accessors
 
   design = Design.new

   assert_equal('Not Started', design.phase.name)

   design.phase_id = ReviewType.get_final.id
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
  
  
 ######################################################################
 def test_find
 
   active_designs = Design.find_all_active
   all_designs    = Design.find(:all)
   assert(active_designs.size < all_designs.size)
   
   active_designs.each { |d| assert(!d.complete?) }
 
   complete_designs = all_designs - active_designs
   assert(all_designs.size == (complete_designs.size + active_designs.size))
   complete_designs.each { |d| assert(d.complete?) }
 
 end
 
 
 ######################################################################
 def test_phase
 
   review_type_list = ReviewType.get_review_types
   complete_design  = designs(:la453a2)
 
   review_type_list.each { |rt| assert(!complete_design.in_phase?(rt)) }
   
   design_in_placement = designs(:la453a1)
   
   review_type_list.each do |rt|
     if rt.name != 'Placement'
       assert(!design_in_placement.in_phase?(rt))
     else
       assert(design_in_placement.in_phase?(rt))
     end
   end
 
 end
 
 
 def test_admin_updates
 
 
    la455b = designs(:la455b)
    mx234c = designs(:mx234c)
   
    cathy_m   = users(:cathy_m)
    bob_g     = users(:bob_g)
    jan_k     = users(:jan_k)
    jim_l     = users(:jim_l)
    patrice_m = users(:patrice_m)
    rich_m    = users(:rich_m)
    scott_g   = users(:scott_g)
   
    high = priorities(:high)
    low  = priorities(:low)
    
    boston = design_centers(:boston_harrison)
    oregon = design_centers(:oregon)
   
    in_review       = review_statuses(:in_review)
    not_started     = review_statuses(:not_started)
    review_complete = review_statuses(:review_complete)
    review_skipped  = review_statuses(:review_skipped)
    pending_repost  = review_statuses(:pending_repost)
    on_hold         = review_statuses(:on_hold)
   
    existing_design_updates = DesignUpdate.find(:all)
   
    gold_design = { :designer       => scott_g,
                    :peer           => rich_m,
                    :pcb_input_gate => cathy_m,
                    :criticality    => high }
   
    gold_design_reviews = { 'Pre-Artwork' => { :designer      => cathy_m,
                                               :design_center => boston,
                                               :criticality   => high,
                                               :status        => review_complete },
                            'Placement'   => { :designer      => scott_g,
                                               :design_center => boston,
                                               :criticality   => high,
                                               :status        => in_review },
                            'Routing'     => { :designer      => scott_g,
                                               :design_center => boston,
                                               :criticality   => high,
                                               :status        => not_started },
                            'Final'       => { :designer      => scott_g,
                                               :design_center => boston,
                                               :criticality   => high,
                                               :status        => not_started },
                            'Release'     => { :designer      => patrice_m,
                                               :design_center => boston,
                                               :criticality   => high,
                                               :status        => not_started } }
   
    # The Pre-Art review is complete.  This should not change the design or the 
    # Pre-Art design review.
    update = { :pcb_input_gate => jan_k }
    la455b.admin_updates(update, "", jim_l)
 
    validate_design(gold_design, la455b)
    validate_design_reviews(gold_design_reviews, la455b.design_reviews)
   
    design_updates = DesignUpdate.find(:all) - existing_design_updates
    assert_equal(0, design_updates.size)
    existing_design_updates += design_updates

   
    # Update the designer
    update = { :designer => bob_g }
   
    # The design and design reviews will be changed as described below.
    gold_design[:designer] = bob_g
    gold_design_reviews['Placement'][:designer] = bob_g
    gold_design_reviews['Routing'][:designer]   = bob_g
    gold_design_reviews['Final'][:designer]     = bob_g
 
    la455b.admin_updates(update, "", jim_l)
 
    validate_design(gold_design, la455b)
    validate_design_reviews(gold_design_reviews, la455b.design_reviews)
   
    design_updates = DesignUpdate.find(:all) - existing_design_updates
    assert_equal(4, design_updates.size)
    
    # Seperate the design updates into the one for the design and the 3
    # for the design reviews
    design_review_updates = []
    design_updates.each { |du| design_review_updates << du if du.design_id == 0 }
    
    assert_equal(3, design_review_updates.size)
    design_review_id_list = [9, 7, 8]
    design_review_updates.sort_by { |dru| dru.design_review.review_type.name }.each_with_index do |dru, i|
      assert_equal(la455b.name,     dru.design_review.design.name)
      assert_equal(0,               dru.design_id)
      assert_equal(jim_l.name,      dru.user.name)
      assert_equal('Designer',      dru.what)
      assert_equal(scott_g.name,    dru.old_value)
      assert_equal(bob_g.name,      dru.new_value)
      assert(design_review_id_list.include?(dru.design_review_id))
      design_review_id_list.delete_if { |drid| drid == dru.design_review_id }
    end
    
    design_update_list = design_updates - design_review_updates
    assert_equal(1, design_update_list.size)
    design_update = design_update_list[0]
    assert_equal(la455b.name,  design_update.design.name)
    assert_equal(0,            design_update.design_review_id)
    assert_equal(jim_l.name,   design_update.user.name)
    assert_equal('Designer',   design_update.what)
    assert_equal(scott_g.name, design_update.old_value)
    assert_equal(bob_g.name,   design_update.new_value)
    existing_design_updates += design_updates

    # Update the peer
    update = { :peer => scott_g }
   
    # The design will be changed as described below.
    gold_design[:peer] = scott_g

    # Verify that the valor reviewer is not scott prior to the update.
    valor_design_review_result =
      la455b.get_design_review('Final').get_review_result('Valor')
    assert_not_equal(scott_g.name, valor_design_review_result.reviewer.name)

    la455b.admin_updates(update, "", jim_l)
 
    validate_design(gold_design, la455b)
    validate_design_reviews(gold_design_reviews, la455b.design_reviews)
    # Verify that the valor reviewer is scott after the update.
    valor_design_review_result.reload
    assert_equal(scott_g.name, valor_design_review_result.reviewer.name)
    
    valor_design_review_result.reload
    assert_equal(scott_g.name, valor_design_review_result.reviewer.name)

    design_updates = DesignUpdate.find(:all) - existing_design_updates

    lisa_a = users(:lisa_a)
    assert_equal(2, design_updates.size)
    design_update = design_updates[1]
    assert_equal(la455b.name,    design_update.design.name)
    assert_equal(jim_l.name,     design_update.user.name)
    assert_equal('Peer Auditor', design_update.what)
    assert_equal(rich_m.name,    design_update.old_value)
    assert_equal(scott_g.name,   design_update.new_value)
    design_update = design_updates[0]
    assert_equal(la455b.name,        design_update.design_review.design.name)
    assert_equal(jim_l.name,         design_update.user.name)
    assert_equal('Valor Reviewer',   design_update.what)
    assert_equal(lisa_a.name,        design_update.old_value)
    assert_equal(scott_g.name,       design_update.new_value)
    existing_design_updates += design_updates

    # Update the release poster
    update = { :release_poster => cathy_m}
    gold_design_reviews['Release'][:designer] = cathy_m
    
    la455b.admin_updates(update, "", jim_l)
 
    validate_design(gold_design, la455b)
    validate_design_reviews(gold_design_reviews, la455b.design_reviews)
    
    design_updates = DesignUpdate.find(:all) - existing_design_updates
    assert_equal(1, design_updates.size)
    assert_equal('Release',          design_updates[0].design_review.review_type.name)
    assert_equal(0,                  design_updates[0].design_id)
    assert_equal('Release Poster',   design_updates[0].what)
    assert_equal('Patrice Michaels', design_updates[0].old_value)
    assert_equal('Cathy McLaren',    design_updates[0].new_value)

    existing_design_updates += design_updates


    # Update the criticality
    update = { :criticality => low }
    gold_design[:criticality] = low
    gold_design_reviews['Placement'][:criticality] = low
    gold_design_reviews['Routing'][:criticality]   = low
    gold_design_reviews['Final'][:criticality]     = low
    gold_design_reviews['Release'][:criticality]   = low

    la455b.admin_updates(update, "", jim_l)
 
    validate_design(gold_design, la455b)
    validate_design_reviews(gold_design_reviews, la455b.design_reviews)

    design_updates = DesignUpdate.find(:all) - existing_design_updates
    assert_equal(4, design_updates.size)
    assert_equal('Placement',   design_updates[0].design_review.review_type.name)
    assert_equal(0,             design_updates[0].design_id)
    assert_equal('Criticality', design_updates[0].what)
    assert_equal('High',        design_updates[0].old_value)
    assert_equal('Low',         design_updates[0].new_value)
    assert_equal('Routing',     design_updates[1].design_review.review_type.name)
    assert_equal(0,             design_updates[1].design_id)
    assert_equal('Criticality', design_updates[1].what)
    assert_equal('High',        design_updates[1].old_value)
    assert_equal('Low',         design_updates[1].new_value)
    assert_equal('Final',       design_updates[2].design_review.review_type.name)
    assert_equal(0,             design_updates[2].design_id)
    assert_equal('Criticality', design_updates[2].what)
    assert_equal('High',        design_updates[2].old_value)
    assert_equal('Low',         design_updates[2].new_value)
    assert_equal('Release',     design_updates[3].design_review.review_type.name)
    assert_equal(0,             design_updates[3].design_id)
    assert_equal('Criticality', design_updates[3].what)
    assert_equal('High',        design_updates[3].old_value)
    assert_equal('Low',         design_updates[3].new_value)
    design_updates.each { |update| assert_equal(jim_l.name, update.user.name) }
    existing_design_updates += design_updates

    # Update the design center
    update = { :design_center => oregon }
    gold_design[:design_center] = oregon
    gold_design_reviews['Pre-Artwork'][:design_center] = oregon
    gold_design_reviews['Placement'][:design_center]   = oregon
    gold_design_reviews['Routing'][:design_center]     = oregon
    gold_design_reviews['Final'][:design_center]       = oregon
    gold_design_reviews['Release'][:design_center]     = oregon

    la455b.admin_updates(update, "", jim_l)
  
    validate_design(gold_design, la455b)
    validate_design_reviews(gold_design_reviews, la455b.design_reviews)
 
    design_updates = DesignUpdate.find(:all) - existing_design_updates
    assert_equal(5, design_updates.size)
    assert_equal('Pre-Artwork',       design_updates[0].design_review.review_type.name)
    assert_equal('Design Center',     design_updates[0].what)
    assert_equal('Boston (Harrison)', design_updates[0].old_value)
    assert_equal('Oregon',            design_updates[0].new_value)
    assert_equal('Placement',         design_updates[1].design_review.review_type.name)
    assert_equal('Design Center',     design_updates[1].what)
    assert_equal('Boston (Harrison)', design_updates[1].old_value)
    assert_equal('Oregon',            design_updates[1].new_value)
    assert_equal('Routing',           design_updates[2].design_review.review_type.name)
    assert_equal('Design Center',     design_updates[2].what)
    assert_equal('Boston (Harrison)', design_updates[2].old_value)
    assert_equal('Oregon',            design_updates[2].new_value)
    assert_equal('Final',             design_updates[3].design_review.review_type.name)
    assert_equal('Design Center',     design_updates[3].what)
    assert_equal('Boston (Harrison)', design_updates[3].old_value)
    assert_equal('Oregon',            design_updates[3].new_value)
    assert_equal('Release',           design_updates[4].design_review.review_type.name)
    assert_equal('Design Center',     design_updates[4].what)
    assert_equal('Boston (Harrison)', design_updates[4].old_value)
    assert_equal('Oregon',            design_updates[4].new_value)
    existing_design_updates += design_updates
    0.upto(design_updates.size-1) do |i| 
      assert_equal(jim_l.name, design_updates[i].user.name)
      assert_equal(0,          design_updates[i].design_id)
    end

    # Update the status
    update = { :status => on_hold 
    }
    gold_design_reviews['Placement'][:status] = on_hold

    la455b.admin_updates(update, "", jim_l)
 
    validate_design(gold_design, la455b)
    validate_design_reviews(gold_design_reviews, la455b.design_reviews)

    design_updates = DesignUpdate.find(:all) - existing_design_updates
    assert_equal(1, design_updates.size)
    design_update = design_updates[0]
    assert_equal(0,                design_update.design_id)
    assert_equal('Placement',      design_update.design_review.review_type.name)
    assert_equal(jim_l.name,       design_update.user.name)
    assert_equal('Review Status',  design_update.what)
    assert_equal('In Review',      design_update.old_value)
    assert_equal('Review On-Hold', design_update.new_value)
    existing_design_updates += design_updates


    # Verify that the PCB Input Gate can be updated
    gold_design = { :designer       => rich_m,
                    :peer           => scott_g,
                    :pcb_input_gate => cathy_m,
                    :criticality    => low }
   
    gold_design_reviews = { 'Pre-Artwork' => { :designer      => cathy_m,
                                               :design_center => boston,
                                               :criticality   => low,
                                               :status        => not_started },
                            'Placement'   => { :designer      => rich_m,
                                               :design_center => boston,
                                               :criticality   => low,
                                               :status        => not_started },
                            'Routing'     => { :designer      => rich_m,
                                               :design_center => boston,
                                               :criticality   => low,
                                               :status        => not_started },
                            'Final'       => { :designer      => rich_m,
                                               :design_center => boston,
                                               :criticality   => low,
                                               :status        => not_started },
                            'Release'     => { :designer      => patrice_m,
                                               :design_center => boston,
                                               :criticality   => low,
                                               :status        => not_started } }
                                               
    # Put everything in a known state.
    update = { :designer      => rich_m,
               :peer          => scott_g,
               :criticality   => low,
               :design_center => boston }
               
    mx234c.admin_updates(update, "", jim_l)
 
    validate_design(gold_design, mx234c)
    validate_design_reviews(gold_design_reviews, mx234c.design_reviews)
    
    design_updates = DesignUpdate.find(:all) - existing_design_updates
    existing_design_updates += design_updates
    
    
    # Verify that the Pre-Art designer (PCB input) can be changed
    update = { :pcb_input_gate => jan_k }
    
    gold_design[:pcb_input_gate] = jan_k
    gold_design_reviews['Pre-Artwork'][:designer] = jan_k
    
    mx234c.admin_updates(update, "", jim_l)
 
    validate_design(gold_design, mx234c)
    validate_design_reviews(gold_design_reviews, mx234c.design_reviews)
    
    design_updates = DesignUpdate.find(:all) - existing_design_updates

    assert_equal(1, design_updates.size)
    assert_equal('Pre-Artwork',        design_updates[0].design_review.review_type.name)
    assert_equal(0,                    design_updates[0].design_id)
    assert_equal(jim_l.name,           design_updates[0].user.name)
    assert_equal('Pre-Artwork Poster', design_updates[0].what)
    assert_equal('Cathy McLaren',      design_updates[0].old_value)
    assert_equal('Jan Kasting',        design_updates[0].new_value)

 end
 
 
 def validate_design(gold, design)

   msg = "#{design.name} - design - "
   am  = msg + "DESIGNER"
   assert_equal(gold[:designer].name,       design.designer.name,   am)
   am = msg + "PEER"
   assert_equal(gold[:peer].name,           design.peer.name,       am)
   am = msg + "PCB INPUT ID"
   assert_equal(gold[:pcb_input_gate].name, design.input_gate.name, am)
   am = msg + "CRITICALITY"
   assert_equal(gold[:criticality].name,    design.priority.name,   am)
   
 end
 
 
 def validate_design_reviews(gold, design_reviews)
 
   design_reviews.each do |dr|
   
     review = dr.review_type.name
     msg    = "#{dr.design.name} - REVIEW: #{review}"

     check_val = gold[review]

     am = msg + "DESIGNER"
     assert_equal(check_val[:designer].name,      dr.designer.name,      am)
     am = msg + "DESIGN CITY"
     assert_equal(check_val[:design_center].name, dr.design_center.name, am)
     am = msg + 'CRITICALITY'
     assert_equal(check_val[:criticality].name,   dr.priority.name,      am)
     am = msg + 'STATUS'
     assert_equal(check_val[:status].name,        dr.review_status.name, am)
   
   end
 
 end
 
 
 def dump_all
 
   Design.find(:all).each { |d| dump(d) }
 
 end
 
 
 def dump(d, msg = '')
 
   puts("****************************************************************")
   puts("****************************************************************")
   puts(msg)
   puts("****************************************************************")
   puts("****************************************************************")
 
   puts("----------------------------------------------------------------")
   puts("NAME:     #{d.name}\t\tID:        #{d.id}")
   puts("DESIGNER: #{d.designer.name}\tPEER: #{d.peer.name}\tPCB INPUT: #{d.input_gate.name}")
   puts("CRITICALTY: #{d.priority.name}\tPHASE ID: #{d.phase_id}")
   puts("----------------------------------------------------------------")
 
   puts("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
   d.design_reviews.each do |dr|
     puts("\tID: #{dr.id}\tTYPE: #{dr.review_type.name}")
     puts("\t  @@@@ PLACMENT/ROUTING COMBINED") if dr.review_type_id_2 > 0
     puts("\t  STATUS:      #{dr.review_status.name}")
     begin
       puts("\t  DESIGNER:    #{dr.designer.name}")
     rescue 
       puts("\t  DESIGNER:    NOT FOUND FOR ID #{dr.designer_id}")
     end
     puts("\t  CRITICALITY: #{dr.priority.name}")
     puts("\t  DESIGN CTR:  #{dr.design_center.name}")
   end
 end


end
