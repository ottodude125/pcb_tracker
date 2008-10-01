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
  fixtures(:audits,
           :boards,
           :boards_users,
#           :board_designs,
           :board_design_entries,
           :board_design_entry_users,
           :board_reviewers,
           :checks,
           :designs,
           :design_centers,
           :design_checks,
           :design_reviews,
           :design_review_comments,
           :design_review_results,
           :design_updates,
           :fab_houses,
           :oi_assignment_reports,
           :oi_assignments,
           :oi_categories,
           :oi_category_sections,
           :oi_instructions,
           :part_numbers,
           :platforms,
           :priorities,
           :projects,
           :review_statuses,
           :review_types,
           :review_types_roles,
           :roles,
           :roles_users,
           :sections,
           :subsections,
           :users)


  ######################################################################
  def setup
    
    @design         = Design.find(1)
    @designs_027    = designs(:designs_027)
    @la453a1_design = designs(:la453a1)
    @mx234a_design  = designs(:mx234a)
    @mx600a_design  = designs(:mx600a)

    @mx234a_pre_art_dr   = design_reviews(:mx234a_pre_artwork)
    @mx234a_placement_dr = design_reviews(:mx234a_placement)
    @mx234a_routing_dr   = design_reviews(:mx234a_routing)
    @mx234a_final_dr     = design_reviews(:mx234a_final)
    @mx234a_release_dr   = design_reviews(:mx234a_release)
    
    @mx234a_pre_artwork_hw    = design_review_results(:mx234a_pre_artwork_hw)
    @mx234a_pre_artwork_valor = design_review_results(:mx234a_pre_artwork_valor)
    @mx234a_final_valor       = design_review_results(:mx234a_final_valor)


    @pre_artwork_review_type = review_types(:pre_artwork)
    @placement_review_type   = review_types(:placement)
    @routing_review_type     = review_types(:routing)
    @final_review_type       = review_types(:final)
    @release_review_type     = review_types(:release)
         
    @hweng_role = roles(:hweng)
    @valor      = roles(:valor)
         
    @rich_a    = users(:rich_a)
    @lisa_a    = users(:lisa_a)
    @ben_b     = users(:ben_b)
    @eileen_c  = users(:eileen_c)
    @art_d     = users(:art_d)
    @matt_d    = users(:matt_d)
    @espo      = users(:espo)
    @tom_f     = users(:tom_f)
    @anthony_g = users(:anthony_g)
    @scott_g   = users(:scott_g)
    @john_g    = users(:john_g)
    @bob_g     = users(:bob_g)
    @dan_g     = users(:dan_g)
    @jan_k     = users(:jan_k)
    @h_kit     = users(:heng_k)
    @jim_l     = users(:jim_l)
    @dave_m    = users(:dave_m)
    @cathy_m   = users(:cathy_m)
    @patrice_m = users(:patrice_m)
    @rich_m    = users(:rich_m)
    @lee_s     = users(:lee_s)
    
    @mx234a_expected_reviewers = [ @espo,    @h_kit,   @lee_s,     
                                   @dave_m,  @tom_f,   @anthony_g,
                                   @cathy_m, @john_g,  @matt_d,   
                                   @art_d,   @dan_g,   @rich_a,
                                   @lisa_a,  @jim_l,   @eileen_c ].sort_by { |u| u.last_name }

    
    @review_complete = ReviewStatus.find_by_name('Review Completed')
    @review_skipped  = ReviewStatus.find_by_name('Review Skipped')
    @in_review       = ReviewStatus.find_by_name('In Review')
        
    @emails     = ActionMailer::Base.deliveries
    @emails.clear
    
  end


  ######################################################################
  def test_people
  
    # Verify the behavior when the IDs are not set.
    new_design = Design.new
    assert_equal('Not Assigned', new_design.designer.name)
    assert_equal('Not Assigned', new_design.peer.name)
    assert_equal('Not Assigned', new_design.input_gate.name)
    
    # Verify the correct name when the designer_id is set.
    assert_equal('Robert Goldin', @mx600a_design.designer.name)
    assert_equal('Scott Glover',  @mx600a_design.peer.name)
    assert_equal('Cathy McLaren', @mx600a_design.input_gate.name)
    
  end
  
  
  ######################################################################
  def test_all_reviewers
  
    reviewers = @mx234a_design.all_reviewers
    
    assert_equal(@mx234a_expected_reviewers.size, reviewers.size)
    assert_equal(@mx234a_expected_reviewers,      @mx234a_design.all_reviewers)
    
    assert(!@mx234a_design.inactive_reviewers?)

    @tom_f.update_attribute(:active,  0)

    assert(@mx234a_design.inactive_reviewers?)
    
  end
  

  ######################################################################
  def test_update_valor_reviewer

    original_design_updates   = DesignUpdate.find(:all)
    final_design_review       = @mx234a_design.get_design_review('Final')
    valor_final_review_result = final_design_review.get_review_result('Valor')
    assert_equal(@lisa_a.id, valor_final_review_result.reviewer_id)    
    
    # Verify no updates if the new peer and the Valor reviewer
    # match
    assert(!@mx234a_design.update_valor_reviewer(@lisa_a, @cathy_m))
    assert_equal(original_design_updates, DesignUpdate.find(:all))
    
    # Verify the updates if the peer is not the same as the Valor 
    # reviewer
    assert(@mx234a_design.update_valor_reviewer(@scott_g, @cathy_m))
    design_updates = DesignUpdate.find(:all) - original_design_updates
    assert_equal(1, design_updates.size)
    valor_final_review_result.reload
    assert_equal(@scott_g.id, valor_final_review_result.reviewer_id)
    
    design_update = design_updates.pop
    original_design_updates << design_update
    
    # TODO Check the update
    
    # Verfiy no updates if the review is complete.
    final_design_review.review_status = @review_complete
    final_design_review.save
    @mx234a_design.reload
    
    assert(!@mx234a_design.update_valor_reviewer(@lisa_a, @cathy_m))
    valor_final_review_result.reload
    assert_equal(@scott_g.id,             valor_final_review_result.reviewer_id)
    assert_equal(original_design_updates, DesignUpdate.find(:all))
    
    # Verify no updates if the review was skipped
  
  end
  
  
  ######################################################################
  def test_role_open_review_count
    
    assert_equal(2, @mx234a_design.role_open_review_count(@valor))

    
    @mx234a_pre_art_dr.review_status = @review_skipped
    @mx234a_pre_art_dr.save
    @mx234a_design.reload
    assert_equal(1, @mx234a_design.role_open_review_count(@valor))
     
    
    @mx234a_final_dr.review_status = @review_complete
    @mx234a_final_dr.save
    @mx234a_design.reload
    assert_equal(0, @mx234a_design.role_open_review_count(@valor))

  end
  
  
  ######################################################################
  def test_role_reviewers
    
    assert_equal(2, @mx234a_design.role_review_count(@valor))
    assert_equal(5, @mx234a_design.role_review_count(@hweng_role))
    
    original_design_updates = DesignUpdate.find(:all)
    
    assert(@mx234a_design.is_role_reviewer?(@valor, @lisa_a))
    assert(!@mx234a_design.is_role_reviewer?(@valor, @scott_g))
    
    updated_role = @mx234a_design.set_role_reviewer(@valor, @scott_g, @cathy_m)
    
    assert_equal('Final', updated_role)
    assert(!@mx234a_design.is_role_reviewer?(@valor, @lisa_a))
    assert(@mx234a_design.is_role_reviewer?(@valor, @scott_g))
    
    recent_design_updates    = DesignUpdate.find(:all) - original_design_updates
    original_design_updates += recent_design_updates
    assert_equal(2, recent_design_updates.size)
    recent_design_updates.each do |update|
      assert_equal(@lisa_a.name,  update.old_value)
      assert_equal(@scott_g.name, update.new_value)
      assert_equal(@cathy_m,      update.user)
    end
    
    assert_equal(@mx234a_pre_art_dr, recent_design_updates[0].design_review)
    assert_equal(@mx234a_final_dr,   recent_design_updates[1].design_review)
           
    # Mail will only be sent for the design review that is in process.
    assert_equal(1, @emails.size)
    email = @emails.pop
    assert_equal('Catalyst/AC/(pcb252_234_a0_g): Valor reviewer changed for ' +
                 'the Pre-Artwork design review', 
                 email.subject)
    
    @mx234a_pre_art_dr.review_status = @review_complete
    @mx234a_pre_art_dr.save
    @mx234a_design.reload
    
    @mx234a_design.set_role_reviewer(@valor, @lisa_a, @cathy_m)
    
    assert_equal('Final', updated_role)
    assert(@mx234a_design.is_role_reviewer?(@valor, @lisa_a))
    assert(!@mx234a_design.is_role_reviewer?(@valor, @scott_g))
    
    recent_design_updates = DesignUpdate.find(:all) - original_design_updates
    original_design_updates += recent_design_updates
    assert_equal(1, recent_design_updates.size)
    recent_design_updates.each do |update|
      assert_equal(@scott_g.name, update.old_value)
      assert_equal(@lisa_a.name,  update.new_value)
      assert_equal(@cathy_m,      update.user)
    end
    
    assert_equal(@mx234a_final_dr, recent_design_updates[0].design_review)
       
    # The final review has not been started yet.  No mail will be generated. 
    assert_equal(0, @emails.size)
                 
                 
    @mx234a_placement_dr.review_status = @review_complete
    @mx234a_placement_dr.save
    @mx234a_routing_dr.review_status   = @review_complete
    @mx234a_routing_dr.save
    @mx234a_final_dr.review_status     = @in_review
    @mx234a_final_dr.save
    @mx234a_design.reload
    
    @mx234a_design.set_role_reviewer(@valor, @scott_g, @cathy_m)
    
    assert_equal('Final', updated_role)
    assert(!@mx234a_design.is_role_reviewer?(@valor, @lisa_a))
    assert(@mx234a_design.is_role_reviewer?(@valor, @scott_g))
    
    recent_design_updates = DesignUpdate.find(:all) - original_design_updates
    assert_equal(1, recent_design_updates.size)
    recent_design_updates.each do |update|
      assert_equal(@lisa_a.name,  update.old_value)
      assert_equal(@scott_g.name, update.new_value)
      assert_equal(@cathy_m,      update.user)
    end
    
    assert_equal(@mx234a_final_dr, recent_design_updates[0].design_review)
       
    assert_equal(1, @emails.size)
    email = @emails.pop
    assert_equal('Catalyst/AC/(pcb252_234_a0_g): Valor reviewer changed for ' +
                 'the Final design review', 
                 email.subject)

  end


  ######################################################################
  def test_reviewer_methods

    expected_reviewers = @mx234a_expected_reviewers.collect { |u| u.name }
    assert_equal(expected_reviewers, @mx234a_design.reviewers.collect { |u| u.name })
    
    assert_equal(expected_reviewers,
                 @mx234a_design.reviewers_remaining_reviews.collect { |u| u.name })
           
    expected_reviewers -= ['Arthur Davis', 'John Godin', 'Cathy McLaren', 'Dave Macioce']
    @mx234a_pre_art_dr.review_status = @review_complete
    @mx234a_pre_art_dr.save
    @mx234a_design.reload
    assert_equal(expected_reviewers,
                 @mx234a_design.reviewers_remaining_reviews.collect { |u| u.name })

    @mx234a_placement_dr.review_status = @review_complete
    @mx234a_placement_dr.save
    @mx234a_design.reload
    assert_equal(expected_reviewers,
                 @mx234a_design.reviewers_remaining_reviews.collect { |u| u.name })

    expected_reviewers -= ['Dan Gough']
    @mx234a_routing_dr.review_status = @review_complete
    @mx234a_routing_dr.save
    @mx234a_design.reload
    assert_equal(expected_reviewers,
                 @mx234a_design.reviewers_remaining_reviews.collect { |u| u.name })

    expected_reviewers -= ['Rich Ahamed',      'Lisa Austin',      'Matt Disanzo',
                           'Espo Espedicto',   'Tom Flack',        'Heng Kit Too',
                           'Anthony Gentile']
    @mx234a_final_dr.review_status = @review_complete
    @mx234a_final_dr.save
    @mx234a_design.reload
    assert_equal(expected_reviewers,
                 @mx234a_design.reviewers_remaining_reviews.collect { |u| u.name })

    expected_reviewers = []
    @mx234a_release_dr.review_status = @review_complete
    @mx234a_release_dr.save
    @mx234a_design.reload
    assert_equal(expected_reviewers,
                 @mx234a_design.reviewers_remaining_reviews.collect { |u| u.name })

  end
  
  
  ######################################################################
  def test_get_unique_pcb_numbers
    
    expected_unique_part_numbers = %w(252-232  252-234  252-600  252-700
                                      252-999  942-453  942-454  942-455)
    unique_part_numbers = Design.get_unique_pcb_numbers
    assert_equal(expected_unique_part_numbers, unique_part_numbers)
    
    Design.destroy_all
    unique_part_numbers = Design.get_unique_pcb_numbers
    assert_equal(0, unique_part_numbers.size)
    
  end
  
  
  ######################################################################
  def test_get_associated_users
  
    mx234a_users = @mx234a_design.get_associated_users
    
    assert_equal(@bob_g,   mx234a_users[:designer])
    assert_equal(@scott_g, mx234a_users[:peer])
    assert_equal(@cathy_m, mx234a_users[:pcb_input])
    
    reviewers = mx234a_users[:reviewers].sort_by{ |u| u.last_name }
    expected_reviewers = [ @rich_a,    @lisa_a,    @eileen_c,  @art_d,
                           @matt_d,    @espo,      @tom_f,     @anthony_g,
                           @john_g,    @dan_g,     @jim_l,     @dave_m,
                           @cathy_m,   @lee_s,     @h_kit ]
    assert_equal(expected_reviewers, reviewers)

  end
  

  ######################################################################
  def test_get_associated_users_by_role
  
    mx234a_users = @mx234a_design.get_associated_users_by_role
    expected_users = {
      :designer                      => @bob_g,
      :peer                          => @scott_g,
      :pcb_input                     => @cathy_m,
      'PCB_Mechanical'               => @john_g,
      'PCB Input Gate'               => @cathy_m,
      'DFM'                          => @h_kit,
      'SLM-Vendor'                   => @dan_g,
      'Operations Manager'           => @eileen_c,
      'PCB Design'                   => @jim_l,
      'HWENG'                        => @lee_s,
      'Planning'                     => @matt_d,
      'CE-DFT'                       => @espo,
      'Valor'                        => @lisa_a,
      'Mechanical'                   => @tom_f,
      'SLM BOM'                      => @art_d,
      'Mechanical-MFG'               => @anthony_g,
      'Library'                      => @dave_m,
      'TDE'                          => @rich_a,
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
  
    assert_equal(true,  @mx234a_design.new?)
    assert_equal(false, @mx234a_design.date_code?)
    assert_equal(false, @mx234a_design.dot_rev?)
    
    assert_equal(false, designs(:la453a1).new?)
    assert_equal(false, designs(:la453a1).date_code?)
    assert_equal(true,  designs(:la453a1).dot_rev?)
  
  end


  ######################################################################
  def test_get_design_review
    
    assert_equal(@mx234a_pre_art_dr,    
                 @mx234a_design.get_design_review('Pre-Artwork'))
    assert_equal(@mx234a_placement_dr,
                 @mx234a_design.get_design_review('Placement'))
    assert_equal(@mx234a_routing_dr, 
                 @mx234a_design.get_design_review('Routing'))
    assert_equal(@mx234a_final_dr, 
                 @mx234a_design.get_design_review('Final'))
    assert_equal(@mx234a_release_dr, 
                 @mx234a_design.get_design_review('Release'))
    
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
   
   
   assert_equal('252-234-a0 g', @mx234a_design.part_number.pcb_display_name)
   assert_equal('942-453-a2 y', designs(:la453a2).part_number.pcb_display_name)
   
   assert_equal('pcb252_234_a0_g - Catalyst / AC / ', 
                @mx234a_design.detailed_name)
   
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
    mx234a = @mx234a_design
    assert_equal(@pre_artwork_review_type.id, mx234a.phase_id)
    mx234a.increment_review
    mx234a.reload
    assert_equal(@placement_review_type.id,   mx234a.phase_id)
    mx234a.increment_review
    mx234a.reload
    assert_equal(@routing_review_type.id,     mx234a.phase_id)
    mx234a.increment_review
    mx234a.reload
    assert_equal(@final_review_type.id,       mx234a.phase_id)
    mx234a.increment_review
    mx234a.reload
    assert_equal(@release_review_type.id,     mx234a.phase_id)
    mx234a.increment_review
    mx234a.reload
    assert_equal(Design::COMPLETE,            mx234a.phase_id)
  
    # Reset and try with the Placement and Routing reviews set to skipped.
    mx234a.phase_id  = @pre_artwork_review_type.id
    review_skipped   = ReviewStatus.find_by_name("Review Skipped")
    placement_review = mx234a.design_reviews.detect { |dr| dr.review_type_id == @placement_review_type.id }
    routing_review   = mx234a.design_reviews.detect { |dr| dr.review_type_id == @routing_review_type.id }
    placement_review.review_status = review_skipped
    placement_review.save
    routing_review.review_status = review_skipped
    routing_review.save
  
    assert_equal(@pre_artwork_review_type.id, mx234a.phase_id)
    mx234a.increment_review
    mx234a.reload
    assert_equal(@final_review_type.id,       mx234a.phase_id)
    mx234a.increment_review
    mx234a.reload
    assert_equal(@release_review_type.id,     mx234a.phase_id)
    mx234a.increment_review
    mx234a.reload
    assert_equal(Design::COMPLETE,              mx234a.phase_id)

    # Reset and try with all of the reviews set to skipped.
    mx234a.phase_id  = @pre_artwork_review_type.id
    mx234a.design_reviews.each do |dr|
      dr.review_status = review_skipped
      dr.save
    end
  
    assert_equal(@pre_artwork_review_type.id, mx234a.phase_id)
    mx234a.increment_review
    mx234a.reload
    assert_equal(Design::COMPLETE,            mx234a.phase_id)

  end
 
 
  ######################################################################
  def test_next_review
 
    # Verify a design where no reviews are skipped.
    mx234a = @mx234a_design
    assert_equal(@pre_artwork_review_type.id, mx234a.phase_id)
  
    next_review_id = mx234a.next_review
    assert_equal(@placement_review_type.id,   next_review_id)
    mx234a.phase_id = next_review_id

    next_review_id  = mx234a.next_review
    assert_equal(@routing_review_type.id,     next_review_id)
    mx234a.phase_id = next_review_id
  
    next_review_id  = mx234a.next_review
    assert_equal(@final_review_type.id,       next_review_id)
    mx234a.phase_id = next_review_id
  
    next_review_id  = mx234a.next_review
    assert_equal(@release_review_type.id,     next_review_id)
    mx234a.phase_id = next_review_id
  
    next_review_id  = mx234a.next_review
    assert_equal(Design::COMPLETE,            next_review_id)
  
    # Reset and try with the Placement and Routing reviews set to skipped.
    mx234a.phase_id  = @pre_artwork_review_type.id
    review_skipped   = ReviewStatus.find_by_name("Review Skipped")
    placement_review = mx234a.design_reviews.detect { |dr| dr.review_type_id == @placement_review_type.id }
    routing_review   = mx234a.design_reviews.detect { |dr| dr.review_type_id == @routing_review_type.id }
    placement_review.review_status = review_skipped
    placement_review.save
    routing_review.review_status = review_skipped
    routing_review.save
  
    assert_equal(@pre_artwork_review_type.id, mx234a.phase_id)
  
    next_review_id = mx234a.next_review
    assert_equal(@final_review_type.id,       next_review_id)
    mx234a.phase_id = next_review_id
  
    next_review_id = mx234a.next_review
    assert_equal(@release_review_type.id,     next_review_id)
    mx234a.phase_id = next_review_id
  
    next_review_id = mx234a.next_review
    assert_equal(Design::COMPLETE,            next_review_id)

    # Reset and try with all of the reviews set to skipped.
    mx234a.phase_id  = @pre_artwork_review_type.id
    mx234a.design_reviews.each do |dr|
      dr.review_status = review_skipped
      dr.save
    end
  
    assert_equal(@pre_artwork_review_type.id, mx234a.phase_id)
  
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
                  { :role     => @hweng_role,
                    :comments => [] },
                  { :role     => @valor,
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
def test_design_setup
  
  DesignReview.destroy_all
  DesignReviewResult.destroy_all
  
  active_review_types = ReviewType.get_active_review_types
  not_started    = ReviewStatus.find_by_name('Not Started')
  review_skipped = ReviewStatus.find_by_name('Review Skipped')
  
  test_design = Design.new
  test_design.save
  
  test_design.setup_design_reviews({}, [])
  
  assert_equal(0, DesignReview.count)
  assert_equal(0, DesignReviewResult.count)
  
  mx234a_bde = board_design_entries(:mx234a)
  reviews = { 'Pre-Artwork' => '1',   'Placement' => '1',     'Routing'     => '1',
              'Final'     => '1',     'Release'     => '1'}
  
  @mx234a_design.setup_design_reviews(reviews, mx234a_bde.board_design_entry_users)
  assert_equal(active_review_types.size,   DesignReview.count)
  assert_equal(35,                         DesignReviewResult.count)
  
  active_review_types.each do |review_type|
    design_review = @mx234a_design.design_reviews.detect { |dr| dr.review_type == review_type }
    assert_not_nil(design_review)
    assert_equal(@mx234a_design.id,         design_review.design_id)
    assert_equal(@mx234a_design.created_by, design_review.creator_id)
    assert_equal(@mx234a_design.priority,   design_review.priority)
    assert_equal(not_started,               design_review.review_status)
  end
  
  DesignReview.destroy_all
  DesignReviewResult.destroy_all
  
  @mx234a_design.design_type = 'Dot Rev'
  @mx234a_design.save

  reviews = { 'Pre-Artwork' => '1',   'Placement' => '0',     'Routing'     => '0',
              'Final'     => '1',     'Release'     => '1'}

  @mx234a_design.setup_design_reviews(reviews, mx234a_bde.board_design_entry_users)
  @mx234a_design.reload
  assert_equal(active_review_types.size,   DesignReview.count)
  assert_equal(30,                         DesignReviewResult.count)
  
  active_review_types.each do |review_type|
    design_review = @mx234a_design.design_reviews.detect { |dr| dr.review_type == review_type }
    assert_not_nil(design_review)
    assert_equal(@mx234a_design.id,         design_review.design_id)
    assert_equal(@mx234a_design.created_by, design_review.creator_id)
    assert_equal(@mx234a_design.priority,   design_review.priority)
    if reviews[design_review.review_type.name] == '1'
      assert_equal(not_started, design_review.review_status)
    else
      assert_equal(review_skipped, design_review.review_status)
    end
  end

end


######################################################################
 def test_work_assignment_data
   
   design = designs(:designs_027)
   assert_equal(0, design.assignment_count)
   assert_equal(0, design.completed_assignment_count)
   assert_equal(0, design.report_card_count)
   assert(design.assignments_complete?)
   assert(design.report_cards_complete?)
   assert(design.work_assignments_complete?)
   
   design = @mx234a_design
   assert_equal(2, design.assignment_count)
   assert_equal(1, design.completed_assignment_count)
   assert_equal(2, design.report_card_count)
   assert(!design.assignments_complete?)
   assert(design.report_cards_complete?)
   assert(!design.work_assignments_complete?)
   
   assignment = oi_assignments(:first)
   assignment.complete = 1
   assignment.save
   
   design.reload
   assert_equal(2, design.assignment_count)
   assert_equal(2, design.completed_assignment_count)
   assert_equal(2, design.report_card_count)
   assert(design.assignments_complete?)
   assert(design.report_cards_complete?)
   assert(design.work_assignments_complete?)
   
   OiAssignmentReport.destroy_all
   design.reload
   assert_equal(2, design.assignment_count)
   assert_equal(2, design.completed_assignment_count)
   assert_equal(0, design.report_card_count)
   assert(design.assignments_complete?)
   assert(!design.report_cards_complete?)
   assert(!design.work_assignments_complete?)
 
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
 def test_outsource_methods

   siva_e = users(:siva_e)
   assert(!@mx234a_design.have_assignments(@cathy_m))
   assert(@mx234a_design.have_assignments(siva_e))
   
   assert_equal(0, @mx234a_design.my_assignments(@cathy_m.id).size)
   
   siva_assignments = @mx234a_design.my_assignments(siva_e.id)
   
   assert_equal(1,                      siva_assignments.size)
   assert_equal(oi_assignments(:first), siva_assignments[0])
   
   assert_equal(0, @designs_027.all_assignments.size)
   
   all_assignments = @mx234a_design.all_assignments
   assert_equal(2, all_assignments.size)
   assert_equal(oi_assignments(:first),  all_assignments[0])
   assert_equal(oi_assignments(:second), all_assignments[1])
   
   assembly_drawing = oi_categories(:placement)
   assert_equal(all_assignments, @mx234a_design.all_assignments(assembly_drawing.id))
   
   routing = oi_categories(:routing)
   assert_equal(0, @mx234a_design.all_assignments(routing.id).size)
   
 end

 
 ######################################################################
 def test_audit_methods
 
   assert_equal('Full',    @mx234a_design.audit_type)
   
   checks_removed_count = @mx234a_design.flip_design_type
   assert_equal('Partial', @mx234a_design.audit_type)

   @mx234a_design.reload
   checks_added_count = @mx234a_design.flip_design_type
   assert_equal('Full',                      @mx234a_design.audit_type)
   assert_equal((checks_removed_count * -1), checks_added_count)
 
   @mx234a_design.reload
   assert_equal(checks_removed_count, @mx234a_design.flip_design_type)
 
 
   assert_equal('Partial', @la453a1_design.audit_type)
   
   checks_added_count = @la453a1_design.flip_design_type
   assert_equal('Full', @la453a1_design.audit_type)
   
   @la453a1_design.reload
   checks_removed_count = @la453a1_design.flip_design_type
   assert_equal('Partial',                   @la453a1_design.audit_type)
   assert_equal((checks_removed_count * -1), checks_added_count)
   
   @la453a1_design.reload
   assert_equal(checks_added_count, @la453a1_design.flip_design_type)
   
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
 
 
 ######################################################################
 def test_admin_updates
 
 
    la455b = designs(:la455b)
    mx234c = designs(:mx234c)
      
    high = priorities(:high)
    low  = priorities(:low)
    
    boston = design_centers(:boston_harrison)
    oregon = design_centers(:oregon)
   
    in_review       = review_statuses(:in_review)
    not_started     = review_statuses(:not_started)
    review_skipped  = review_statuses(:review_skipped)
    pending_repost  = review_statuses(:pending_repost)
    on_hold         = review_statuses(:on_hold)
   
    existing_design_updates = DesignUpdate.find(:all)
   
    gold_design = { :designer       => @scott_g,
                    :peer           => @rich_m,
                    :pcb_input_gate => @cathy_m,
                    :criticality    => high }
   
    gold_design_reviews = { 'Pre-Artwork' => { :designer      => @cathy_m,
                                               :design_center => boston,
                                               :criticality   => high,
                                               :status        => @review_complete },
                            'Placement'   => { :designer      => @scott_g,
                                               :design_center => boston,
                                               :criticality   => high,
                                               :status        => in_review },
                            'Routing'     => { :designer      => @scott_g,
                                               :design_center => boston,
                                               :criticality   => high,
                                               :status        => not_started },
                            'Final'       => { :designer      => @scott_g,
                                               :design_center => boston,
                                               :criticality   => high,
                                               :status        => not_started },
                            'Release'     => { :designer      => @patrice_m,
                                               :design_center => boston,
                                               :criticality   => high,
                                               :status        => not_started } }
   
    # The Pre-Art review is complete.  This should not change the design or the 
    # Pre-Art design review.
    update = { :pcb_input_gate => @jan_k }
    la455b.admin_updates(update, "", @jim_l)
 
    validate_design(gold_design, la455b)
    validate_design_reviews(gold_design_reviews, la455b.design_reviews)
   
    design_updates = DesignUpdate.find(:all) - existing_design_updates
    assert_equal(0, design_updates.size)
    existing_design_updates += design_updates

   
    # Update the designer
    update = { :designer => @bob_g }
   
    # The design and design reviews will be changed as described below.
    gold_design[:designer] = @bob_g
    gold_design_reviews['Placement'][:designer] = @bob_g
    gold_design_reviews['Routing'][:designer]   = @bob_g
    gold_design_reviews['Final'][:designer]     = @bob_g
 
    la455b.admin_updates(update, "", @jim_l)
 
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
      assert_equal(la455b.name,      dru.design_review.design.name)
      assert_equal(0,                dru.design_id)
      assert_equal(@jim_l.name,      dru.user.name)
      assert_equal('Designer',       dru.what)
      assert_equal(@scott_g.name,    dru.old_value)
      assert_equal(@bob_g.name,      dru.new_value)
      assert(design_review_id_list.include?(dru.design_review_id))
      design_review_id_list.delete_if { |drid| drid == dru.design_review_id }
    end
    
    design_update_list = design_updates - design_review_updates
    assert_equal(1, design_update_list.size)
    design_update = design_update_list[0]
    assert_equal(la455b.name,   design_update.design.name)
    assert_equal(0,             design_update.design_review_id)
    assert_equal(@jim_l.name,   design_update.user.name)
    assert_equal('Designer',    design_update.what)
    assert_equal(@scott_g.name, design_update.old_value)
    assert_equal(@bob_g.name,   design_update.new_value)
    existing_design_updates += design_updates

    # Update the peer
    update = { :peer => @scott_g }
   
    # The design will be changed as described below.
    gold_design[:peer] = @scott_g

    # Verify that the valor reviewer is not scott prior to the update.
    valor_design_review_result =
      la455b.get_design_review('Final').get_review_result('Valor')
    assert_not_equal(@scott_g.name, valor_design_review_result.reviewer.name)

    la455b.admin_updates(update, "", @jim_l)
 
    validate_design(gold_design, la455b)
    validate_design_reviews(gold_design_reviews, la455b.design_reviews)
    # Verify that the valor reviewer is scott after the update.
    valor_design_review_result.reload
    assert_equal(@scott_g.name, valor_design_review_result.reviewer.name)
    
    valor_design_review_result.reload
    assert_equal(@scott_g.name, valor_design_review_result.reviewer.name)

    design_updates = DesignUpdate.find(:all) - existing_design_updates

    assert_equal(2, design_updates.size)
    design_update = design_updates[1]
    assert_equal(la455b.name,     design_update.design.name)
    assert_equal(@jim_l.name,     design_update.user.name)
    assert_equal('Peer Auditor',  design_update.what)
    assert_equal(@rich_m.name,    design_update.old_value)
    assert_equal(@scott_g.name,   design_update.new_value)
    design_update = design_updates[0]
    assert_equal(la455b.name,        design_update.design_review.design.name)
    assert_equal(@jim_l.name,        design_update.user.name)
    assert_equal('Valor Reviewer',   design_update.what)
    assert_equal(@lisa_a.name,       design_update.old_value)
    assert_equal(@scott_g.name,      design_update.new_value)
    existing_design_updates += design_updates

    # Update the release poster
    update = { :release_poster => @cathy_m}
    gold_design_reviews['Release'][:designer] = @cathy_m
    
    la455b.admin_updates(update, "", @jim_l)
 
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

    la455b.admin_updates(update, "", @jim_l)
 
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
    design_updates.each { |update| assert_equal(@jim_l.name, update.user.name) }
    existing_design_updates += design_updates

    # Update the design center
    update = { :design_center => oregon }
    gold_design[:design_center] = oregon
    gold_design_reviews['Pre-Artwork'][:design_center] = oregon
    gold_design_reviews['Placement'][:design_center]   = oregon
    gold_design_reviews['Routing'][:design_center]     = oregon
    gold_design_reviews['Final'][:design_center]       = oregon
    gold_design_reviews['Release'][:design_center]     = oregon

    la455b.admin_updates(update, "", @jim_l)
  
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
      assert_equal(@jim_l.name, design_updates[i].user.name)
      assert_equal(0,           design_updates[i].design_id)
    end

    # Update the status
    update = { :status => on_hold 
    }
    gold_design_reviews['Placement'][:status] = on_hold

    la455b.admin_updates(update, "", @jim_l)
 
    validate_design(gold_design, la455b)
    validate_design_reviews(gold_design_reviews, la455b.design_reviews)

    design_updates = DesignUpdate.find(:all) - existing_design_updates
    assert_equal(1, design_updates.size)
    design_update = design_updates[0]
    assert_equal(0,                design_update.design_id)
    assert_equal('Placement',      design_update.design_review.review_type.name)
    assert_equal(@jim_l.name,      design_update.user.name)
    assert_equal('Review Status',  design_update.what)
    assert_equal('In Review',      design_update.old_value)
    assert_equal('Review On-Hold', design_update.new_value)
    existing_design_updates += design_updates


    # Verify that the PCB Input Gate can be updated
    gold_design = { :designer       => @rich_m,
                    :peer           => @scott_g,
                    :pcb_input_gate => @cathy_m,
                    :criticality    => low }
   
    gold_design_reviews = { 'Pre-Artwork' => { :designer      => @cathy_m,
                                               :design_center => boston,
                                               :criticality   => low,
                                               :status        => not_started },
                            'Placement'   => { :designer      => @rich_m,
                                               :design_center => boston,
                                               :criticality   => low,
                                               :status        => not_started },
                            'Routing'     => { :designer      => @rich_m,
                                               :design_center => boston,
                                               :criticality   => low,
                                               :status        => not_started },
                            'Final'       => { :designer      => @rich_m,
                                               :design_center => boston,
                                               :criticality   => low,
                                               :status        => not_started },
                            'Release'     => { :designer      => @patrice_m,
                                               :design_center => boston,
                                               :criticality   => low,
                                               :status        => not_started } }
                                               
    # Put everything in a known state.
    update = { :designer      => @rich_m,
               :peer          => @scott_g,
               :criticality   => low,
               :design_center => boston }
               
    mx234c.admin_updates(update, "", @jim_l)
 
    validate_design(gold_design, mx234c)
    validate_design_reviews(gold_design_reviews, mx234c.design_reviews)
    
    design_updates = DesignUpdate.find(:all) - existing_design_updates
    existing_design_updates += design_updates
    
    
    # Verify that the Pre-Art designer (PCB input) can be changed
    update = { :pcb_input_gate => @jan_k }
    
    gold_design[:pcb_input_gate] = @jan_k
    gold_design_reviews['Pre-Artwork'][:designer] = @jan_k
    
    mx234c.admin_updates(update, "", @jim_l)
 
    validate_design(gold_design, mx234c)
    validate_design_reviews(gold_design_reviews, mx234c.design_reviews)
    
    design_updates = DesignUpdate.find(:all) - existing_design_updates

    assert_equal(1, design_updates.size)
    assert_equal('Pre-Artwork',        design_updates[0].design_review.review_type.name)
    assert_equal(0,                    design_updates[0].design_id)
    assert_equal(@jim_l.name,          design_updates[0].user.name)
    assert_equal('Pre-Artwork Poster', design_updates[0].what)
    assert_equal('Cathy McLaren',      design_updates[0].old_value)
    assert_equal('Jan Kasting',        design_updates[0].new_value)

 end
 
 
 ######################################################################
 def test_directory_name
   
   assert_equal('pcb252_600_a0_o', @mx600a_design.directory_name)
   
   mx999c = designs(:mx999c)
   assert_equal('mx999c', mx999c.directory_name)
   
 end


 ######################################################################
 def test_pnemonic_based_name
   
   assert_equal('mx600a', @mx600a_design.pnemonic_based_name)
   
   mx999c = designs(:mx999c)
   assert_equal('mx999c', mx999c.pnemonic_based_name)
   
 end

 
  ###################################################################
  def test_set_all_reviewer_for_role_used_in_a_select_design_reviews
    
    @mx234a_design.design_reviews.each do |design_review|
      if valor_result = design_review.get_review_result(@valor.name)
        assert_equal(@lisa_a.name, valor_result.reviewer.name)
      end
    end
    
    @mx234a_design.set_reviewer(@valor, @scott_g)
    
    @mx234a_design.reload
    @mx234a_design.design_reviews.each do |design_review|
      if valor_result = design_review.get_review_result(@valor.name)
        assert_equal(@scott_g.name, valor_result.reviewer.name)
      end
    end
    
  end


 ###################################################################
  def test_set_incomplete_reviewer_for_role_used_in_a_select_design_reviews
    
    @mx234a_pre_artwork_valor.result = 'APPROVED'
    @mx234a_pre_artwork_valor.save
    
    @mx234a_design.reload
    @mx234a_design.design_reviews.each do |design_review|
      if valor_result = design_review.get_review_result(@valor.name)
        assert_equal(@lisa_a.name, valor_result.reviewer.name)
      end
    end
    
    @mx234a_design.set_reviewer(@valor, @scott_g)
    
    @mx234a_design.reload
    @mx234a_design.design_reviews.each do |design_review|
      if valor_result = design_review.get_review_result(@valor.name)
        if design_review.review_type.name == 'Pre-Artwork'
            assert_equal(@lisa_a.name + '/' + design_review.review_type.name,
                         valor_result.reviewer.name + '/' + design_review.review_type.name)
        else
            assert_equal(@scott_g.name + '/' + design_review.review_type.name,
                         valor_result.reviewer.name + '/' + design_review.review_type.name)
        end
      end
    end
    
  end


  ###################################################################
  def test_no_set_reviewer_result_already_recorded
    
    @mx234a_design.design_reviews.each do |design_review|
      hw_result = design_review.get_review_result(@hweng_role.name)
      assert_equal(@lee_s.name, hw_result.reviewer.name)
    end

    @mx234a_pre_artwork_hw.result = "WAIVED"
    @mx234a_pre_artwork_hw.save
    @mx234a_design.reload
    @mx234a_design.set_reviewer(@hweng_role, @ben_b)
    
    @mx234a_design.reload
    @mx234a_design.design_reviews.each do |design_review|
      hw_result = design_review.get_review_result(@hweng_role.name)
      if design_review.review_type.name == 'Pre-Artwork'
        assert_equal(@lee_s.name + '/' + design_review.review_type.name,
                     hw_result.reviewer.name + '/' + design_review.review_type.name)
      else
        assert_equal(@ben_b.name + '/' + design_review.review_type.name, 
                     hw_result.reviewer.name + '/' + design_review.review_type.name)
      end
    end
    
  end
  
  
  ###################################################################
  def test_set_reviewer_non_role_member_exception
    
    @mx234a_design.design_reviews.each do |design_review|
      hw_result = design_review.get_review_result(@hweng_role.name)
      assert_equal(@lee_s.name, hw_result.reviewer.name)
    end

    assert_raise(ArgumentError) { @mx234a_design.set_reviewer(@hweng_role, @scott_g) }
    
    @mx234a_design.reload
    @mx234a_design.design_reviews.each do |design_review|
      hw_result = design_review.get_review_result(@hweng_role.name)
      assert_equal(@lee_s.name, hw_result.reviewer.name)
    end
    
  end
  
  
  ###################################################################
 def test_set_reviewer_non_role_member

    @mx234a_design.design_reviews.each do |design_review|
      hw_result = design_review.get_review_result(@hweng_role.name)
      assert_equal(@lee_s.name, hw_result.reviewer.name)
    end

    @mx234a_design.set_reviewer(@hweng_role, @scott_g)

  rescue => err
    assert_equal('Scott Glover is not a member of the Hardware Engineer (EE) group.', 
                 err.message)
    @mx234a_design.reload
    @mx234a_design.design_reviews.each do |design_review|
      hw_result = design_review.get_review_result(@hweng_role.name)
      assert_equal(@lee_s.name, hw_result.reviewer.name)
    end

  end
  

  ###################################################################
  def test_set_reviewer_role_member
    
    @mx234a_design.design_reviews.each do |design_review|
      hw_result = design_review.get_review_result(@hweng_role.name)
      assert_equal(@lee_s.name, hw_result.reviewer.name)
    end

    @mx234a_design.set_reviewer(@hweng_role, @ben_b)
    
    @mx234a_design.design_reviews.each do |design_review|
      hw_result = design_review.get_review_result(@hweng_role.name)
      assert_equal(@ben_b.name, hw_result.reviewer.name)
    end
    
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
