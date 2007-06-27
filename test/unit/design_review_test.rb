########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_review_test.rb
#
# This file contains the unit tests for the design review model
#
# Revision History:
#   $Id$
#
########################################################################

require File.dirname(__FILE__) + '/../test_helper'

class DesignReviewTest < Test::Unit::TestCase

  fixtures(:designs,
           :design_centers,
           :design_reviews,
           :design_review_comments,
           :design_review_results,
           :priorities,
           :review_statuses,
           :review_types,
           :roles,
           :roles_users,
           :users)


  ######################################################################
  def setup
    @mx234a_pre_art_review   = design_reviews(:mx234a_pre_artwork)
    @mx234a_placement_review = design_reviews(:mx234a_placement)
    @mx234a_routing_review   = design_reviews(:mx234a_routing)
    @mx234a_final_review     = design_reviews(:mx234a_final)
    @mx234a_release_review   = design_reviews(:mx234a_release)
    
    @cathy_m = users(:cathy_m)
  end


  ######################################################################
  def test_role_functions

    test_data = [ { :role     => roles(:admin),
                    :reviewer => nil,
                    :comments => [design_review_comments(:comment_four),
                                  design_review_comments(:comment_one)] },
                  { :role     => roles(:designer),
                    :reviewer => nil,
                    :comments => [design_review_comments(:comment_three)] },
                  { :role     => roles(:manager),
                    :reviewer => nil,
                    :comments => [design_review_comments(:comment_two)] },
                  { :role     => roles(:hweng),
                    :reviewer => users(:lee_s),
                    :comments => [] },
                  { :role     => roles(:valor),
                    :reviewer => users(:lisa_a),
                    :comments => [design_review_comments(:comment_three)] },
                  { :role     => roles(:ce_dft),
                    :reviewer => users(:espo),
                    :comments => [] },
                  { :role     => roles(:dfm),
                    :reviewer => users(:heng_k),
                    :comments => [] },
                  { :role     => roles(:tde),
                    :reviewer => users(:rich_a),
                    :comments => [] },
                  { :role     => roles(:mechanical),
                    :reviewer => users(:tom_f),
                    :comments => [] },
                  { :role     => roles(:pcb_design),
                    :reviewer => users(:jim_l),
                    :comments => [design_review_comments(:comment_two)] },
                  { :role     => roles(:planning),
                    :reviewer => users(:matt_d),
                    :comments => [] },
                  { :role     => roles(:pcb_input_gate),
                    :reviewer => users(:cathy_m),
                    :comments => [design_review_comments(:comment_four),
                                  design_review_comments(:comment_one)] },
                  { :role     => roles(:library),
                    :reviewer => users(:dave_m),
                    :comments => [] },
                  { :role     => roles(:pcb_mechanical),
                    :reviewer => users(:john_g),
                    :comments => [] },
                  { :role     => roles(:slm_bom),
                    :reviewer => users(:art_d),
                    :comments => [] },
                  { :role     => roles(:slm_vendor),
                    :reviewer => users(:dan_g),
                    :comments => [] },
                  { :role     => roles(:operations_manager),
                    :reviewer => nil,
                    :comments => [] },
                  { :role     => roles(:pcb_admin),
                    :reviewer => nil,
                    :comments => [] },
                  { :role     => roles(:program_manager),
                    :reviewer => nil,
                    :comments => [] },
                  { :role     => roles(:compliance_emc),
                    :reviewer => nil,
                    :comments => [] },
                  { :role     => roles(:compliance_safety),
                    :reviewer => nil,
                    :comments => [] },
                  { :role     => roles(:hweng_manager),
                    :reviewer => nil,
                    :comments => [] },
                  { :role     => roles(:mechanical_manufacturing),
                    :reviewer => users(:anthony_g),
                    :comments => [] } ]
  
    test_data.each do |test|
      assert_equal(test[:reviewer], @mx234a_pre_art_review.role_reviewer(test[:role]))
      assert_equal(test[:comments], @mx234a_pre_art_review.comments_by_role(test[:role].name))
    end
    
    assert_equal([design_review_comments(:comment_four),
                  design_review_comments(:comment_three),
                  design_review_comments(:comment_one)],
                 @mx234a_pre_art_review.comments_by_role(['Designer',           'Valor', 
                                                          'Operations Manager', 'PCB Input Gate']))

    assert_equal([design_review_comments(:comment_four),
                  design_review_comments(:comment_one)],
                 @mx234a_pre_art_review.comments_by_role(['PCB Admin',          'Operations Manager',
                                                          'PCB Input Gate']))
  
  end
  
  
  ######################################################################
  def test_review_name
    assert_equal('Pre-Artwork',       @mx234a_pre_art_review.review_name)
    assert_equal('Routing',           @mx234a_routing_review.review_name)
    assert_equal('Placement/Routing',  
                 design_reviews(:la453a2_placement).review_name)
  end
  
  
  ######################################################################
  def test_review_results_by_role_name
    review_results   = @mx234a_pre_art_review.review_results_by_role_name
    expected_results = @mx234a_pre_art_review.design_review_results
    review_results   = review_results.sort_by   { |rr| rr.role.name }
    expected_results = expected_results.sort_by { |er| er.role.name }

    assert_equal(expected_results, review_results)
    assert_equal(14,               review_results.size)
  end


  ######################################################################
  def test_designer

    board_designer    = User.find(@mx234a_pre_art_review.designer_id)
    designer          = @mx234a_pre_art_review.designer
    assert_kind_of(User,              designer)
    assert_equal(board_designer.name, designer.name)

    new_design_review = DesignReview.new
    designer          = new_design_review.designer
    assert_kind_of(User,         designer)
    assert_equal("Not Assigned", designer.name)

  end


  ######################################################################
  def test_generate_reviewer_lists
    
    keys = [:group, :group_id, :reviewers, :reviewer_id]
    gold_list = [{ :group       => roles(:dfm).display_name,
                   :group_id    => roles(:dfm).id,
                   :reviewers   => [users(:pat_a),
                                    users(:john_ju),
                                    users(:heng_k)],
                   :reviewer_id => users(:heng_k).id},
                 { :group       => roles(:ce_dft).display_name,
                   :group_id    => roles(:ce_dft).id,
                   :reviewers   => [users(:espo),
                                    users(:ted_p)],
                   :reviewer_id => users(:espo).id},
                 { :group       => roles(:library).display_name,
                   :group_id    => roles(:library).id,
                   :reviewers   => [users(:dave_m),
                                    users(:sheela_p)],
                   :reviewer_id => users(:dave_m).id},
                 { :group       => roles(:hweng).display_name,
                   :group_id    => roles(:hweng).id,
                   :reviewers   => [users(:rich_a),
                                    users(:ben_b),
                                    users(:john_j),
                                    users(:lee_s)],
                   :reviewer_id => users(:lee_s).id},
                 { :group       => roles(:mechanical).display_name,
                   :group_id    => roles(:mechanical).id,
                   :reviewers   => [users(:tom_f),
                                    users(:dave_l)],
                   :reviewer_id => users(:tom_f).id},
                 { :group       => roles(:mechanical_manufacturing).display_name,
                   :group_id    => roles(:mechanical_manufacturing).id,
                   :reviewers   => [users(:anthony_g),
                                    users(:tony_p)],
                   :reviewer_id => users(:anthony_g).id},
                 { :group       => roles(:planning).display_name,
                   :group_id    => roles(:planning).id,
                   :reviewers   => [users(:tina_d),
                                    users(:matt_d)],
                   :reviewer_id => users(:matt_d).id},
                 { :group       => roles(:pcb_input_gate).display_name,
                   :group_id    => roles(:pcb_input_gate).id,
                   :reviewers   => [users(:jan_k),
                                    users(:cathy_m)],
                   :reviewer_id => users(:cathy_m).id},
                 { :group       => roles(:pcb_design).display_name,
                   :group_id    => roles(:pcb_design).id,
                   :reviewers   => [users(:jim_l)],
                   :reviewer_id => users(:jim_l).id},
                 { :group       => roles(:pcb_mechanical).display_name,
                   :group_id    => roles(:pcb_mechanical).id,
                   :reviewers   => [users(:john_g),
                                    users(:mary_t)],
                   :reviewer_id => users(:john_g).id},
                 { :group       => roles(:slm_bom).display_name,
                   :group_id    => roles(:slm_bom).id,
                   :reviewers   => [users(:art_d)],
                   :reviewer_id => users(:art_d).id},
                 { :group       => roles(:slm_vendor).display_name,
                   :group_id    => roles(:slm_vendor).id,
                   :reviewers   => [users(:dan_g)],
                   :reviewer_id => users(:dan_g).id},
                 { :group       => roles(:tde).display_name,
                   :group_id    => roles(:tde).id,
                   :reviewers   => [users(:rich_a),
                                    users(:man_c)],
                   :reviewer_id => users(:rich_a).id},
                 { :group       => roles(:valor).display_name,
                   :group_id    => roles(:valor).id,
                   :reviewers   => [users(:lisa_a),
                                    users(:scott_g),
                                    users(:bob_g),
                                    users(:rich_m)],
                   :reviewer_id => users(:lisa_a).id}
                ]
           
    reviewer_list = @mx234a_pre_art_review.generate_reviewer_selection_list
    assert_equal(gold_list.size, reviewer_list.size)
    
    reviewer_list.each_with_index do |reviewer, i|
    
      gold = gold_list[i]

      keys.each do |key|
        case key
        when :group
          assert_equal(gold[key], reviewer.role.display_name)
        when :group_id
          assert_equal(gold[key], reviewer.role_id)
        when :reviewer_id
          assert_equal(gold[key], reviewer.reviewer_id)
        when :reviewers
          assert_equal(gold[key].size, reviewer.role.active_users.size)
          0.upto(gold[key].size-1) do |j|
            assert_equal(gold[key][j].name, reviewer.role.active_users[j].name)
          end
        end

      end

    end


    gold_reviewers = gold_list.collect { |rg| User.find(rg[:reviewer_id]) }
    gold_reviewers = gold_reviewers.sort_by { |u| u.last_name}
    
    reviewer_list = @mx234a_pre_art_review.reviewers([], true)
    assert_equal(gold_list.size, reviewer_list.size)
    
    reviewer_list.each_with_index do |reviewer, i|
      assert_equal(gold_reviewers[i].name, reviewer_list[i].name)
    end

    # Verify the list is the same size - reviewers() removes duplicates.
    reviewer_list = @mx234a_pre_art_review.reviewers(reviewer_list)
    assert_equal(gold_list.size, reviewer_list.size)
    
    reviewer_list.each_with_index do |reviewer, i|
      assert_equal(gold_reviewers[i].name, reviewer_list[i].name)
    end
    

  end
  
  
  ######################################################################
  def test_age_functions
  
    design_review = @mx234a_pre_art_review
    
    # The design was created on Tuesday, Jan 10, 2006 @ midnight
    #
    #                                         year   mon   day hour minute second
    assert_equal(0, 
                 design_review.age(Time.local(2006, "jan",   3,  0,   0,     0)))
    assert_equal(' 0.0',
                 design_review.age_in_days(Time.local(2006, "jan", 3,  0,   0,     0)))
    assert_equal(10.hours,
                 design_review.age(Time.local(2006, "jan",  3, 10,   0,     0)))
    assert_equal(11.hours + 59.minutes + 59, 
                 design_review.age(Time.local(2006, "jan",  3, 11,  59,    59)))
    
    #                                         year   mon   day hour minute second
    assert_equal(12.hours, 
                 design_review.age(Time.local(2006, "jan",  3, 12,   0,     0)))
    assert_equal(' 0.5',
                 design_review.age_in_days(Time.local(2006, "jan", 3, 12,   0,     0)))
    assert_equal(12.hours + 1, 
                 design_review.age(Time.local(2006, "jan",  3, 12,   0,     1)))
    assert_equal(1.day,
                 design_review.age(Time.local(2006, "jan",  4,  0,   0,     0)))
    assert_equal(1.day + 11.hours + 59.minutes + 59, 
                 design_review.age(Time.local(2006, "jan",  4, 11,  59,    59)))
    assert_equal(1.day + 12.hours + 1, 
                 design_review.age(Time.local(2006, "jan",  4, 12,   0,     1)))
    assert_equal(2.days, 
                 design_review.age(Time.local(2006, "jan",  5,  0,   0,     0)))
    assert_equal(2.days + 12.hours + 1, 
                 design_review.age(Time.local(2006, "jan",  5, 12,   0,     1)))
    assert_equal(3.days + 12.hours + 1, 
                 design_review.age(Time.local(2006, "jan",  6, 12,   0,     1)))
    assert_equal(4.days, 
                 design_review.age(Time.local(2006, "jan",  7, 12,   0,     1)))
    assert_equal(4.days, 
                 design_review.age(Time.local(2006, "jan",  8, 12,   0,     1)))
    assert_equal(4.days + 12.hours + 1, 
                 design_review.age(Time.local(2006, "jan",  9, 12,   0,     1)))
    assert_equal(5.days + 12.hours + 1, 
                 design_review.age(Time.local(2006, "jan", 10, 12,   0,     1)))

  end


  ######################################################################
  def test_hold_functions
  
    on_hold   = ReviewStatus.find_by_name('Review On-Hold')
    in_review = ReviewStatus.find_by_name('In Review')
    design_review = @mx234a_pre_art_review
    
    assert_equal(0, design_review.time_on_hold)
    assert_equal(0, design_review.time_on_hold_total)

    sat_jan_6_noon     = Time.local(2007, "jan", 6, 12, 0, 0)
    sun_jan_7_noon     = sat_jan_6_noon + 1.day
    mon_jan_8_noon     = sun_jan_7_noon + 1.day
    mon_jan_8_8_am     = mon_jan_8_noon - 4.hours
    tue_jan_9_10_am    = mon_jan_8_8_am + 26.hours
    tue_jan_9_noon     = mon_jan_8_noon + 1.day
    tue_jan_9_1_pm     = tue_jan_9_noon + 1.hour
    tue_jan_9_330_pm   = tue_jan_9_1_pm + 150.minutes
    tue_jan_9_430_pm   = tue_jan_9_330_pm + 1.hour
    tue_jan_9_5_pm     = tue_jan_9_430_pm + 30.minutes
    tue_jan_9_10_pm    = tue_jan_9_5_pm + 5.hours
    tue_jan_9_1130_pm  = tue_jan_9_10_pm + 90.minutes
    fri_jan_12_1130_pm = tue_jan_9_1130_pm + 3.days
    sat_jan_13_130_am  = fri_jan_12_1130_pm + 2.hours
    sun_jan_14_noon    = sun_jan_7_noon + 1.week
    mon_jan_15_noon    = mon_jan_8_noon + 1.week
    mon_jan_15_5_pm    = mon_jan_15_noon + 5.hours
    
    design_review.place_on_hold(sat_jan_6_noon)

    assert_equal(on_hold.id, design_review.review_status_id)
    assert_equal(0,          design_review.time_on_hold(sun_jan_7_noon))
    assert_equal(0,          design_review.time_on_hold_total(sun_jan_7_noon))
    assert_equal(12.hours,   design_review.time_on_hold(mon_jan_8_noon))
    assert_equal(12.hours,   design_review.time_on_hold_total(mon_jan_8_noon))
    assert_equal(5.days + 12.hours, design_review.time_on_hold(mon_jan_15_noon))
    assert_equal(5.days + 12.hours, design_review.time_on_hold_total(mon_jan_15_noon))
                 
    design_review.remove_from_hold(in_review.id, sun_jan_7_noon)
    assert_equal(0, design_review.time_on_hold)
    assert_equal(0, design_review.time_on_hold_total)
    
    
    design_review.place_on_hold(mon_jan_8_8_am)
    
    assert_equal(1.day + 2.hours, design_review.time_on_hold(tue_jan_9_10_am))
    assert_equal(1.day + 4.hours, design_review.time_on_hold_total(tue_jan_9_noon))

    design_review.remove_from_hold(in_review.id, tue_jan_9_1_pm)

    assert_equal(0,               design_review.time_on_hold(sun_jan_14_noon))
    assert_equal(1.day + 5.hours, design_review.time_on_hold_total(sun_jan_14_noon))


    design_review.place_on_hold(tue_jan_9_330_pm)
    
    assert_equal(1.hours,         design_review.time_on_hold(tue_jan_9_430_pm))
    assert_equal(1.day + 6.hours, design_review.time_on_hold_total(tue_jan_9_430_pm))

    design_review.remove_from_hold(in_review.id, tue_jan_9_5_pm)

    assert_equal(0, design_review.time_on_hold(tue_jan_9_10_pm))
    assert_equal(1.day + 6.hours + 30.minutes, 
                 design_review.time_on_hold_total(tue_jan_9_10_pm))

    design_review.place_on_hold(fri_jan_12_1130_pm)
    assert_equal(30.minutes, design_review.time_on_hold(sat_jan_13_130_am))
    assert_equal(1.day + 7.hours,
                 design_review.time_on_hold_total(sat_jan_13_130_am))

    design_review.remove_from_hold(in_review.id, mon_jan_15_noon)

    assert_equal(0, design_review.time_on_hold(mon_jan_15_5_pm))
    assert_equal(1.day + 19.hours, 
                 design_review.time_on_hold_total(mon_jan_15_5_pm))

  end
  
  
  ######################################################################
  def test_review_locked
  
    final_review_type = ReviewType.find_by_name("Final")
    release_review_type = ReviewType.find_by_name("Release")
    
    design_review = DesignReview.new(:review_type_id => release_review_type.id)
    assert(!design_review.review_locked?)
    
    
    # audit complete, audit not skipped, no outstanding work assignments - not locked
    design = Design.new
    design.save
    
    design_review.review_type_id = final_review_type.id
    design_review.design_id      = design.id
    design_review.save
    design_review.reload

    audit = Audit.new(:skip => 0, :auditor_complete => 1, :design_id => design.id)
    audit.save
    
    assert_equal('Final', design_review.review_type.name)
    assert(!design_review.design.audit.skip?)
    assert(design_review.design.audit.auditor_complete?)
    assert(design_review.design.work_assignments_complete?)
    assert(!design_review.review_locked?)
    
    # audit not complete, audit skipped, no outstanding work assignments - not locked
    audit.skip             = 1
    audit.auditor_complete = 0
    audit.save
    design_review.reload
    
    assert_equal('Final', design_review.review_type.name)
    assert(design_review.design.audit.skip?)
    assert(!design_review.design.audit.auditor_complete?)
    assert(design_review.design.work_assignments_complete?)
    assert(!design_review.review_locked?)

    # audit not complete, audit not skipped, no outstanding work assignments - locked
    audit.skip             = 0
    audit.save
    design_review.reload
    
    assert_equal('Final', design_review.review_type.name)
    assert(!design_review.design.audit.skip?)
    assert(!design_review.design.audit.auditor_complete?)
    assert(design_review.design.work_assignments_complete?)
    assert(design_review.review_locked?)

    # audit complete, audit not skipped, outstanding work assignments - locked
    audit.auditor_complete = 1
    audit.save
    
    instruction = OiInstruction.new(:design_id => design.id)
    instruction.save
    
    assignment = OiAssignment.new(:oi_instruction_id => instruction.id)
    assignment.save
    
    design_review.reload

    assert_equal('Final', design_review.review_type.name)
    assert(!design_review.design.audit.skip?)
    assert(design_review.design.audit.auditor_complete?)
    assert(!design_review.design.work_assignments_complete?)
    assert(design_review.review_locked?)
    
    # audit not complete, audit skipped, outstanding work assignments - locked
    audit.skip             = 1
    audit.auditor_complete = 0
    audit.save
    design_review.reload
    
    assert_equal('Final', design_review.review_type.name)
    assert(design_review.design.audit.skip?)
    assert(!design_review.design.audit.auditor_complete?)
    assert(!design_review.design.work_assignments_complete?)
    assert(design_review.review_locked?)

    # audit not complete, audit not skipped, outstanding work assignments - locked
    audit.skip             = 0
    audit.save
    design_review.reload
    
    assert_equal('Final', design_review.review_type.name)
    assert(!design_review.design.audit.skip?)
    assert(!design_review.design.audit.auditor_complete?)
    assert(!design_review.design.work_assignments_complete?)
    assert(design_review.review_locked?)
    
  end


  ######################################################################
  def test_post_review
 
    release_review_type = ReviewType.find_by_name("Release")

    design = Design.new(:phase_id => release_review_type.id)
    design.save

    final_review_type = ReviewType.find_by_name("Final")
    design_review = DesignReview.new(:review_type_id => final_review_type.id,
                                     :design_id      => design.id)
    design_review.save
    design_review.reload

    audit = Audit.new(:skip => 0, :auditor_complete => 1, :design_id => design.id)
    audit.save
    
    assert_equal('Final', design_review.review_type.name)
    assert(!design_review.design.audit.skip?)
    assert(design_review.design.audit.auditor_complete?)
    assert(design_review.design.work_assignments_complete?)
    assert(!design_review.review_locked?)
    
  
    scott_g      = users(:scott_g)
    scott_glover = scott_g.name
    next_review  = DesignReview.new(:designer_id    => scott_g.id,
                                    :review_type_id => release_review_type.id,
                                    :design_id      => design.id)
    next_review.save
    design_review.reload
    
    # TRUE
    #   review not locked, 
    #   current user is designer, 
    #   next review same as design phase
    assert_equal(scott_glover,           User.find(next_review.designer_id).name)
    assert_equal(release_review_type.id, design.phase_id)
    assert_equal(release_review_type.id, next_review.review_type_id)
    assert(design_review.post_review?(next_review, scott_g))

    # FALSE
    #   review not locked, 
    #   current user is designer, 
    #   next review not same as design phase
    design.phase_id = final_review_type.id
    design.update
    design_review.reload
    next_review.reload

    assert_equal(scott_glover,           User.find(next_review.designer_id).name)
    assert_equal(final_review_type.id,   design.phase_id)
    assert_equal(release_review_type.id, next_review.review_type_id)
    assert(!design_review.post_review?(next_review, scott_g))

    # FALSE
    #   review not locked, 
    #   current user not designer, 
    #   next review not same as design phase
    assert(!design_review.post_review?(next_review, users(:ben_b)))
    
    # FALSE
    #   review not locked, 
    #   current user not designer, 
    #   next review same as design phase
    design.phase_id = release_review_type.id
    design.update
    design_review.reload
    next_review.reload

    assert_equal(release_review_type.id, design.phase_id)
    assert_equal(release_review_type.id, next_review.review_type_id)
    assert(!design_review.post_review?(next_review, users(:ben_b)))

    # FALSE
    #   review locked, 
    #   current user is designer, 
    #   next review same as design phase
    design_review.design.audit.auditor_complete = 0
    design_review.design.audit.update
    design_review.reload

    assert_equal(scott_glover,           User.find(next_review.designer_id).name)
    assert_equal(release_review_type.id, design.phase_id)
    assert_equal(release_review_type.id, next_review.review_type_id)
    assert(!design_review.post_review?(next_review, scott_g))
 
    # FALSE
    #   review locked, 
    #   current user is designer, 
    #   next review not same as design phase
    design.phase_id = final_review_type.id
    design.update
    design_review.reload
    next_review.reload

    assert_equal(scott_glover,           User.find(next_review.designer_id).name)
    assert_equal(final_review_type.id,   design.phase_id)
    assert_equal(release_review_type.id, next_review.review_type_id)
    assert(!design_review.post_review?(next_review, scott_g))

    # FALSE
    #   review locked, 
    #   current user not designer, 
    #   next review not same as design phase
    assert(!design_review.post_review?(next_review, users(:ben_b)))
    
    # FALSE
    #   review locked, 
    #   current user not designer, 
    #   next reiew same as design phase
    design.phase_id = release_review_type.id
    design.update
    design_review.reload
    next_review.reload

    assert_equal(release_review_type.id, design.phase_id)
    assert_equal(release_review_type.id, next_review.review_type_id)
    assert(!design_review.post_review?(next_review, users(:ben_b)))
  
  end
  
  
  ######################################################################
  def test_set_valor_reviewer
  
    valor_role = Role.find_by_name("Valor")
    lisa_a     = users(:lisa_a)
    scott_g    = users(:scott_g)
    final_dr   = design_reviews(:mx234a_final)
    assert_equal(scott_g.name, User.find(final_dr.design.peer_id).name)
    
    valor_rr = final_dr.design_review_results.detect { |rr| rr.role_id == valor_role.id }
    assert_equal(lisa_a.name, User.find(valor_rr.reviewer_id).name)
    
    final_dr.set_valor_reviewer
    assert_equal(scott_g.name, User.find(valor_rr.reviewer_id).name)
  
  end
  
  
  ######################################################################
  def test_review_status_methods
  
    in_review       = ReviewStatus.find_by_name('In Review')
    on_hold         = ReviewStatus.find_by_name('Review On-Hold')
    pending_repost  = ReviewStatus.find_by_name('Pending Repost')
    review_complete = ReviewStatus.find_by_name('Review Completed')
    
    design_review = DesignReview.new
    
    assert(!design_review.in_review?)
    assert(!design_review.on_hold?)
    assert(!design_review.pending_repost?)
    assert(!design_review.review_complete?)
    
    design_review.review_status_id = in_review.id
    assert(design_review.in_review?)
    assert(!design_review.on_hold?)
    assert(!design_review.pending_repost?)
    assert(!design_review.review_complete?)

    design_review.review_status_id = on_hold.id
    assert(!design_review.in_review?)
    assert(design_review.on_hold?)
    assert(!design_review.pending_repost?)
    assert(!design_review.review_complete?)
  
    design_review.review_status_id = pending_repost.id
    assert(!design_review.in_review?)
    assert(!design_review.on_hold?)
    assert(design_review.pending_repost?)
    assert(!design_review.review_complete?)

    design_review.review_status_id = review_complete.id
    assert(!design_review.in_review?)
    assert(!design_review.on_hold?)
    assert(!design_review.pending_repost?)
    assert(design_review.review_complete?)

  end


  ######################################################################
  def test_update_methods
  
    oregon = design_centers(:oregon)
    boston = design_centers(:boston_harrison)

    reviews = { 
      :pre_artwork => { :review  => @mx234a_pre_art_review,
                        :updates => @mx234a_pre_art_review.design_updates },
      :placement   => { :review  => @mx234a_placement_review,
                        :updates => @mx234a_placement_review.design_updates },
      :routing     => { :review  => @mx234a_routing_review,
                        :updates => @mx234a_routing_review.design_updates },
      :final       => { :review  => @mx234a_final_review,
                        :updates => @mx234a_final_review.design_updates },
      :release     => { :review  => @mx234a_release_review,
                        :updates => @mx234a_release_review.design_updates } }
         
    ###
    ###  Test update_design_center(design_center, user)
    ###

    reviews.each { |key, dr_data| assert_equal(boston, dr_data[:review].design_center) }
    
    reviews.each do |key, dr_data|
    
      dr_data[:review].design_updates.clear
    
      assert(!dr_data[:review].update_design_center(nil, @cathy_m))
      
      assert_equal(boston, dr_data[:review].design_center) 
      dr_data[:review].reload
      assert_equal(boston, dr_data[:review].design_center)
      
      assert_equal(0, dr_data[:review].design_updates.size)

    end

    reviews.each do |key, dr_data| 
      assert(!dr_data[:review].update_design_center(boston, @cathy_m))
      
      assert_equal(boston, dr_data[:review].design_center)
      dr_data[:review].reload
      assert_equal(boston, dr_data[:review].design_center)
      
      assert_equal(0, dr_data[:review].design_updates.size)

    end

    reviews.each do |key, dr_data| 
      assert(dr_data[:review].update_design_center(oregon, @cathy_m))
      
      assert_equal(oregon, dr_data[:review].design_center)
      dr_data[:review].reload
      assert_equal(oregon, dr_data[:review].design_center)
      assert_equal(1, dr_data[:review].design_updates.size)
      update_list = dr_data[:review].design_updates

      update = update_list[0]
      assert_equal(dr_data[:review], update.design_review)
      assert_equal('Design Center',  update.what)
      assert_equal(boston.name,      update.old_value)
      assert_equal(oregon.name,      update.new_value)
      assert_equal(@cathy_m,         update.user)
    end

    ###
    ###  Test update_criticality(criticality, user)
    ###

    high   = priorities(:high)
    medium = priorities(:medium)

    # At this point, none of the review status values is "Review Completed".
    # Go through all of the design reviews and verify that the criticality
    # is not updated if a new one is not supplied.
    reviews.each do |key, dr_data| 
    
      dr_data[:review].design_updates.clear
    
      assert(!dr_data[:review].update_criticality(nil, @cathy_m))
      
      assert_equal(high, dr_data[:review].priority) 
      dr_data[:review].reload
      assert_equal(high, dr_data[:review].priority)
      assert_equal(0, dr_data[:review].design_updates.size)
    end
    
    # Go through all of the design reviews and verify that the criticality
    # is not updated if the new value is the same as the existing value.
    reviews.each do |key, dr_data| 
      assert(!dr_data[:review].update_criticality(high, @cathy_m))
      
      assert_equal(high, dr_data[:review].priority) 
      dr_data[:review].reload
      assert_equal(high, dr_data[:review].priority)
      assert_equal(0, dr_data[:review].design_updates.size)
    end
    
    # Go through all of the design reviews and verify that the criticality
    # is updated if the new value is different from the existing value.
    reviews.each do |key, dr_data| 
      assert(dr_data[:review].update_criticality(medium, @cathy_m))
      
      assert_equal(medium, dr_data[:review].priority)
      dr_data[:review].reload
      assert_equal(medium, dr_data[:review].priority)
      assert_equal(1, dr_data[:review].design_updates.size)
      update_list = dr_data[:review].design_updates

      update = update_list[0]
      assert_equal(dr_data[:review], update.design_review)
      assert_equal('Criticality',    update.what)
      assert_equal(high.name,        update.old_value)
      assert_equal(medium.name,      update.new_value)
      assert_equal(@cathy_m,         update.user)
    end
    
    # Go through all of the design reviews and set the review status
    # to 'Review Completed' and verify that the design review does
    # not get reset.
    original_review_status = {}
    review_completed       = ReviewStatus.find_by_name('Review Completed')
    reviews.each do |key, dr_data| 
    
      dr_data[:review].design_updates.clear
    
      original_review_status[key] = dr_data[:review].review_status.id
      dr_data[:review].review_status = review_completed
      
      assert(!dr_data[:review].update_criticality(high, @cathy_m))
      
      assert_equal(medium, dr_data[:review].priority) 
      dr_data[:review].reload
      assert_equal(medium, dr_data[:review].priority)
      assert_equal(0,      dr_data[:review].design_updates.size)

      
      dr_data[:review].review_status_id = original_review_status[key]
      
    end
  
    ###
    ###  Test update_review_status(..., user)
    ###

    on_hold           = ReviewStatus.find_by_name('Review On-Hold')
    in_review         = ReviewStatus.find_by_name('In Review')
    
    # Attempt to update a design review that is not started and
    # verify that there are no changes.
    assert_equal('Not Started', @mx234a_placement_review.review_status.name)
    
    assert(!@mx234a_placement_review.update_review_status(on_hold, @cathy_m))
    
    assert_equal('Not Started', @mx234a_placement_review.review_status.name)
    assert_equal(0,             @mx234a_placement_review.design_updates.size)
    
    # Attempt to update a design review that is 'In Review' to 'In Review' and 
    # verify that nothing happens
    assert_equal(in_review.name, @mx234a_pre_art_review.review_status.name)
    
    assert(!@mx234a_pre_art_review.update_review_status(in_review, @cathy_m))
    assert_equal(in_review.name, @mx234a_pre_art_review.review_status.name)
    assert_equal(0,              @mx234a_pre_art_review.design_updates.size)
    
    # Attempt to update a design review that is 'In Review' to 'On Hold' and 
    # verify the review status is updated and the change is recorded.
    assert(@mx234a_pre_art_review.update_review_status(on_hold, @cathy_m))
    assert_equal(on_hold.name, @mx234a_pre_art_review.review_status.name)
    assert_equal(1,            @mx234a_pre_art_review.design_updates.size)
    
    update_list = @mx234a_pre_art_review.design_updates

    update = update_list[0]
    assert_equal(@mx234a_pre_art_review, update.design_review)
    assert_equal('Review Status',        update.what)
    assert_equal(in_review.name,         update.old_value)
    assert_equal(on_hold.name,           update.new_value)
    assert_equal(@cathy_m,               update.user)

    # Attempt to update a design review that is 'On Hold' to 'In Review' and 
    # verify the review status is updated and the change is recorded.
    @mx234a_pre_art_review.design_updates.clear
    
    assert(@mx234a_pre_art_review.update_review_status(in_review, @cathy_m))
    assert_equal(in_review.name, @mx234a_pre_art_review.review_status.name)
    assert_equal(1,              @mx234a_pre_art_review.design_updates.size)
    
    update_list = @mx234a_pre_art_review.design_updates

    update = update_list[0]
    assert_equal(@mx234a_pre_art_review, update.design_review)
    assert_equal('Review Status',        update.what)
    assert_equal(on_hold.name,           update.old_value)
    assert_equal(in_review.name,         update.new_value)
    assert_equal(@cathy_m,               update.user)

    @mx234a_pre_art_review.design_updates.clear

  
    ###
    ###  Test update_pcb_input_gate(pcb_input_gate, user)
    ###

    jan_k = users(:jan_k)
    bob_g = users(:bob_g)
    # Attempt to update a design review that is not a Pre-Artwork design
    assert_equal(bob_g.name,    @mx234a_placement_review.designer.name)
    
    assert(!@mx234a_placement_review.update_pcb_input_gate(@cathy_m, @cathy_m))
    
    assert_equal(bob_g.name, @mx234a_placement_review.designer.name)
    assert_equal(0,          @mx234a_placement_review.design_updates.size)
    
    # Attempt to update the pre-art review with the person who is already
    # the input gate.
    assert_equal(@cathy_m.name, @mx234a_pre_art_review.designer.name)
    
    assert(!@mx234a_pre_art_review.update_pcb_input_gate(@cathy_m, @cathy_m))
    assert_equal(@cathy_m.name, @mx234a_pre_art_review.designer.name)
    assert_equal(0,             @mx234a_pre_art_review.design_updates.size)
    
    # Attempt to update a pre-art review with a new pcb input gate.
    assert(@mx234a_pre_art_review.update_pcb_input_gate(jan_k, @cathy_m))
    assert_equal(jan_k.name, @mx234a_pre_art_review.designer.name)
    assert_equal(1,           @mx234a_pre_art_review.design_updates.size)
    
    update_list = @mx234a_pre_art_review.design_updates

    update = update_list[0]
    assert_equal(@mx234a_pre_art_review, update.design_review)
    assert_equal('Pre-Artwork Poster',   update.what)
    assert_equal(@cathy_m.name,          update.old_value)
    assert_equal(jan_k.name,             update.new_value)
    assert_equal(@cathy_m,               update.user)

    # Attempt to update a pre-art review that is complete with a new pcb input gate.
    @mx234a_pre_art_review.design_updates.clear
    @mx234a_pre_art_review.review_status = review_completed
    
    assert(!@mx234a_pre_art_review.update_pcb_input_gate(@cathy_m, @cathy_m))
    assert_equal(jan_k.name, @mx234a_pre_art_review.designer.name)
    assert_equal(0,          @mx234a_pre_art_review.design_updates.size)
    
    ###
    ###  Test update_release_review_poster(release_reviewer, user)
    ###
    patrice_m = users(:patrice_m)

    # Attempt to update a design review that is not a Release design review
    assert(!@mx234a_placement_review.update_release_review_poster(@cathy_m, @cathy_m))
    
    assert_equal(bob_g.name, @mx234a_placement_review.designer.name)
    assert_equal(0,          @mx234a_placement_review.design_updates.size)
    
    # Attempt to update the release review with the person who is already
    # the poster.
    assert_equal(patrice_m.name, @mx234a_release_review.designer.name)
    
    assert(!@mx234a_release_review.update_release_review_poster(patrice_m, @cathy_m))
    assert_equal(patrice_m.name, @mx234a_release_review.designer.name)
    assert_equal(0,              @mx234a_release_review.design_updates.size)
    
    # Attempt to update a release review with a new pcb input gate.
    assert(@mx234a_release_review.update_release_review_poster(jan_k, @cathy_m))
    assert_equal(jan_k.name, @mx234a_release_review.designer.name)
    assert_equal(1,          @mx234a_release_review.design_updates.size)
    
    update_list = @mx234a_release_review.design_updates

    update = update_list[0]
    assert_equal(@mx234a_release_review, update.design_review)
    assert_equal('Release Poster',       update.what)
    assert_equal(patrice_m.name,         update.old_value)
    assert_equal(jan_k.name,             update.new_value)
    assert_equal(@cathy_m,               update.user)

    # Attempt to update a pre-art review that is complete with a new pcb input gate.
    @mx234a_release_review.design_updates.clear
    @mx234a_release_review.review_status = review_completed
    
    assert(!@mx234a_release_review.update_release_review_poster(@cathy_m, @cathy_m))
    assert_equal(jan_k.name, @mx234a_release_review.designer.name)
    assert_equal(0,          @mx234a_release_review.design_updates.size)

    ###
    ###  update_reviews_designer_poster(designer, user)
    ###

    # Attempt to update the pre-art review
    assert_equal(jan_k.name, @mx234a_pre_art_review.designer.name)
    
    assert(!@mx234a_pre_art_review.update_reviews_designer_poster(@cathy_m, @cathy_m))
    assert_equal(jan_k.name, @mx234a_pre_art_review.designer.name)
    assert_equal(0,          @mx234a_pre_art_review.design_updates.size)
    
    # Attempt to update the Release design review
    assert_equal(jan_k.name, @mx234a_release_review.designer.name)
    assert(!@mx234a_release_review.update_reviews_designer_poster(@cathy_m, @cathy_m))
    
    assert_equal(jan_k.name, @mx234a_release_review.designer.name)
    assert_equal(0,          @mx234a_release_review.design_updates.size)
    
    # Attempt to update the placement review with the person who is already
    # the poster.
    assert_equal(bob_g.name, @mx234a_placement_review.designer.name)
    
    assert(!@mx234a_placement_review.update_reviews_designer_poster(bob_g, @cathy_m))
    assert_equal(bob_g.name, @mx234a_placement_review.designer.name)
    assert_equal(0,          @mx234a_placement_review.design_updates.size)
    
    # Attempt to update the placement review with nil value for the designer
    assert(!@mx234a_placement_review.update_reviews_designer_poster(nil, @cathy_m))
    assert_equal(bob_g.name, @mx234a_placement_review.designer.name)
    assert_equal(0,          @mx234a_placement_review.design_updates.size)
    
    # Attempt to update a placement review with a new designer.
    assert(@mx234a_placement_review.update_reviews_designer_poster(jan_k, @cathy_m))
    assert_equal(jan_k.name, @mx234a_placement_review.designer.name)
    assert_equal(1,          @mx234a_placement_review.design_updates.size)
    
    update_list = @mx234a_placement_review.design_updates

    update = update_list[0]
    assert_equal(@mx234a_placement_review, update.design_review)
    assert_equal('Designer',               update.what)
    assert_equal(bob_g.name,               update.old_value)
    assert_equal(jan_k.name,               update.new_value)
    assert_equal(@cathy_m,                 update.user)

    # Attempt to update a pre-art review that is complete with a new pcb input gate.
    @mx234a_placement_review.design_updates.clear
    @mx234a_placement_review.review_status = review_completed
    
    assert(!@mx234a_placement_review.update_reviews_designer_poster(@cathy_m, @cathy_m))
    assert_equal(jan_k.name, @mx234a_placement_review.designer.name)
    assert_equal(0,          @mx234a_placement_review.design_updates.size)

  end

end
