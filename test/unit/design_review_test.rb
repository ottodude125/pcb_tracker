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

  fixtures(:boards,
           :designs,
           :design_centers,
           :design_reviews,
           :design_review_comments,
           :design_review_results,
           :design_updates,
           :part_numbers,
           :posting_timestamps,
           :prefixes,
           :priorities,
           :review_statuses,
           :review_types,
           :revisions,
           :roles,
           :roles_users,
           :users)


  ######################################################################
  def setup
    
    @mx234a_pre_art_review     = design_reviews(:mx234a_pre_artwork)
    @mx234a_placement_review   = design_reviews(:mx234a_placement)
    @mx234a_routing_review     = design_reviews(:mx234a_routing)
    @mx234a_final_review       = design_reviews(:mx234a_final)
    @mx234a_release_review     = design_reviews(:mx234a_release)
    @la455b_placement_review   = design_reviews(:la455b_placement)
    @mx600a_pre_artwork_review = design_reviews(:mx600a_pre_artwork)

    
    @mx234a_pre_artwork_hw = design_review_results(:mx234a_pre_artwork_hw)

    @rich_a    = users(:rich_a)
    @lisa_a    = users(:lisa_a)
    @ben_b     = users(:ben_b)
    @art_d     = users(:art_d)
    @matt_d    = users(:matt_d)
    @espo      = users(:espo)
    @tom_f     = users(:tom_f)
    @anthony_g = users(:anthony_g)
    @scott_g   = users(:scott_g)
    @john_g    = users(:john_g)
    @dan_g     = users(:dan_g)
    @heng_k    = users(:heng_k)
    @jim_l     = users(:jim_l)
    @dave_m    = users(:dave_m)
    @cathy_m   = users(:cathy_m)
    @lee_s     = users(:lee_s)
    
    @admin           = roles(:admin)
    @ce_dft          = roles(:ce_dft)
    @designer        = roles(:designer)
    @dfm             = roles(:dfm)
    @hweng           = roles(:hweng)
    @library         = roles(:library)
    @manager         = roles(:manager)
    @mechanical      = roles(:mechanical)
    @ops_manager     = roles(:operations_manager)
    @pcb_admin       = roles(:pcb_admin)
    @pcb_design      = roles(:pcb_design)
    @pcb_input_gate  = roles(:pcb_input_gate)
    @pcb_mechanical  = roles(:pcb_mechanical)
    @planning        = roles(:planning)
    @program_manager = roles(:program_manager)
    @slm_bom         = roles(:slm_bom)
    @slm_vendor      = roles(:slm_vendor)
    @tde             = roles(:tde)
    @valor           = roles(:valor)
    
  end


  ######################################################################
  def test_role_functions

    test_data = [ { :role     => @admin,
                    :reviewer => nil,
                    :comments => [design_review_comments(:comment_four),
                                  design_review_comments(:comment_one)] },
                  { :role     => @designer,
                    :reviewer => nil,
                    :comments => [design_review_comments(:comment_three)] },
                  { :role     => @manager,
                    :reviewer => nil,
                    :comments => [design_review_comments(:comment_two)] },
                  { :role     => @hweng,
                    :reviewer => @lee_s,
                    :comments => [] },
                  { :role     => @valor,
                    :reviewer => @lisa_a,
                    :comments => [design_review_comments(:comment_three)] },
                  { :role     => @ce_dft,
                    :reviewer => @espo,
                    :comments => [] },
                  { :role     => @dfm,
                    :reviewer => @heng_k,
                    :comments => [] },
                  { :role     => @tde,
                    :reviewer => @rich_a,
                    :comments => [] },
                  { :role     => @mechanical,
                    :reviewer => @tom_f,
                    :comments => [] },
                  { :role     => @pcb_design,
                    :reviewer => @jim_l,
                    :comments => [design_review_comments(:comment_two)] },
                  { :role     => @planning,
                    :reviewer => @matt_d,
                    :comments => [] },
                  { :role     => @pcb_input_gate,
                    :reviewer => @cathy_m,
                    :comments => [design_review_comments(:comment_four),
                                  design_review_comments(:comment_one)] },
                  { :role     => @library,
                    :reviewer => @dave_m,
                    :comments => [] },
                  { :role     => @pcb_mechanical,
                    :reviewer => @john_g,
                    :comments => [] },
                  { :role     => @slm_bom,
                    :reviewer => @art_d,
                    :comments => [] },
                  { :role     => @slm_vendor,
                    :reviewer => @dan_g,
                    :comments => [] },
                  { :role     => @ops_manager,
                    :reviewer => nil,
                    :comments => [] },
                  { :role     => @pcb_admin,
                    :reviewer => nil,
                    :comments => [] },
                  { :role     => @program_manager,
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
                    :reviewer => @anthony_g,
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
    gold_list = [{ :group       => @dfm.display_name,
                   :group_id    => @dfm.id,
                   :reviewers   => [users(:pat_a),
                                    users(:john_ju),
                                    @heng_k],
                   :reviewer_id => @heng_k.id},
                 { :group       => @ce_dft.display_name,
                   :group_id    => @ce_dft.id,
                   :reviewers   => [@espo,
                                    users(:ted_p)],
                   :reviewer_id => @espo.id},
                 { :group       => @library.display_name,
                   :group_id    => @library.id,
                   :reviewers   => [@dave_m,
                                    users(:sheela_p)],
                   :reviewer_id => @dave_m.id},
                 { :group       => roles(:hweng).display_name,
                   :group_id    => roles(:hweng).id,
                   :reviewers   => [@rich_a,
                                    @ben_b,
                                    users(:john_j),
                                    @lee_s],
                   :reviewer_id => @lee_s.id},
                 { :group       => @mechanical.display_name,
                   :group_id    => @mechanical.id,
                   :reviewers   => [@tom_f,
                                    users(:dave_l)],
                   :reviewer_id => @tom_f.id},
                 { :group       => roles(:mechanical_manufacturing).display_name,
                   :group_id    => roles(:mechanical_manufacturing).id,
                   :reviewers   => [@anthony_g,
                                    users(:tony_p)],
                   :reviewer_id => @anthony_g.id},
                 { :group       => @planning.display_name,
                   :group_id    => @planning.id,
                   :reviewers   => [users(:tina_d),
                                    @matt_d],
                   :reviewer_id => @matt_d.id},
                 { :group       => @pcb_input_gate.display_name,
                   :group_id    => @pcb_input_gate.id,
                   :reviewers   => [users(:jan_k),
                                    @cathy_m],
                   :reviewer_id => @cathy_m.id},
                 { :group       => @pcb_design.display_name,
                   :group_id    => @pcb_design.id,
                   :reviewers   => [@jim_l],
                   :reviewer_id => @jim_l.id},
                 { :group       => @pcb_mechanical.display_name,
                   :group_id    => @pcb_mechanical.id,
                   :reviewers   => [@john_g,
                                    users(:mary_t)],
                   :reviewer_id => @john_g.id},
                 { :group       => @slm_bom.display_name,
                   :group_id    => @slm_bom.id,
                   :reviewers   => [users(:art_d)],
                   :reviewer_id => users(:art_d).id},
                 { :group       => @slm_vendor.display_name,
                   :group_id    => @slm_vendor.id,
                   :reviewers   => [@dan_g],
                   :reviewer_id => @dan_g.id},
                 { :group       => @tde.display_name,
                   :group_id    => @tde.id,
                   :reviewers   => [@rich_a,
                                    users(:man_c)],
                   :reviewer_id => @rich_a.id},
                 { :group       => @valor.display_name,
                   :group_id    => @valor.id,
                   :reviewers   => [@lisa_a,
                                    @scott_g,
                                    users(:bob_g),
                                    users(:rich_m)],
                   :reviewer_id => @lisa_a.id}
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
    assert_equal(0, design_review.time_on_hold(sun_jan_7_noon))
    assert_equal(0, design_review.time_on_hold_total(sun_jan_7_noon))
    
    
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
  
    final_review_type = ReviewType.get_final
    release_review_type = ReviewType.get_release
    
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
 
    release_review_type = ReviewType.get_release

    design = Design.new(:phase_id => release_review_type.id)
    design.save

    final_review_type = ReviewType.get_final
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
    
  
    scott_g      = @scott_g
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
    design.save
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
    assert(!design_review.post_review?(next_review, @ben_b))
    
    # FALSE
    #   review not locked, 
    #   current user not designer, 
    #   next review same as design phase
    design.phase_id = release_review_type.id
    design.save
    design_review.reload
    next_review.reload

    assert_equal(release_review_type.id, design.phase_id)
    assert_equal(release_review_type.id, next_review.review_type_id)
    assert(!design_review.post_review?(next_review, @ben_b))

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
    design.save
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
    assert(!design_review.post_review?(next_review, @ben_b))
    
    # FALSE
    #   review locked, 
    #   current user not designer, 
    #   next reiew same as design phase
    design.phase_id = release_review_type.id
    design.save
    design_review.reload
    next_review.reload

    assert_equal(release_review_type.id, design.phase_id)
    assert_equal(release_review_type.id, next_review.review_type_id)
    assert(!design_review.post_review?(next_review, @ben_b))
  
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


  ###################################################################
  def test_no_set_reviewer_result_already_recorded
    
    assert_equal(@lee_s.name, @mx234a_pre_artwork_hw.reviewer.name)

    @mx234a_pre_artwork_hw.result = "WAIVED"
    @mx234a_pre_artwork_hw.save
    @mx234a_pre_art_review.reload
    @mx234a_pre_art_review.set_reviewer(@hweng, @ben_b)
    
    @mx234a_pre_artwork_hw.reload
    assert_equal(@lee_s.name, @mx234a_pre_artwork_hw.reviewer.name)
    
  end
  
  
  ###################################################################
  def test_set_reviewer_non_role_member_exception
    
    assert_equal(@lee_s.name, @mx234a_pre_artwork_hw.reviewer.name)

    assert_raise(ArgumentError) { @mx234a_pre_art_review.set_reviewer(@hweng, @scott_g) }
    @mx234a_pre_art_review.reload
    
    @mx234a_pre_artwork_hw.reload
    assert_equal(@lee_s.name, @mx234a_pre_artwork_hw.reviewer.name)
    
  end
  
  
  ###################################################################
 def test_set_reviewer_non_role_member

    assert_equal(@lee_s.name, @mx234a_pre_artwork_hw.reviewer.name)

    @mx234a_pre_art_review.set_reviewer(@hweng, @scott_g)
    @mx234a_pre_art_review.reload
  rescue => err
    assert_equal('Scott Glover is not a member of the Hardware Engineer (EE) group.', 
                 err.message)
    assert_equal(@lee_s.name, @mx234a_pre_artwork_hw.reviewer.name)

  end
  

  ###################################################################
  def test_set_reviewer_role_member
    
    assert_equal(@lee_s.name, @mx234a_pre_artwork_hw.reviewer.name)

    @mx234a_pre_art_review.set_reviewer(@hweng, @ben_b)
    @mx234a_pre_art_review.reload
    
    @mx234a_pre_artwork_hw.reload
    assert_equal(@ben_b.name, @mx234a_pre_artwork_hw.reviewer.name)
    
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


  ######################################################################
  def test_summary_data

    summary_data = DesignReview.summary_data
    summary_data.each do |key, design_reviews|
      design_reviews.each do |design_review|
        quarter      = 'Q' + design_review.created_on.current_quarter.to_s
        year         = design_review.created_on.strftime("%Y")
        year_quarter = year + quarter

        assert(design_review.posting_count > 0)
        assert_equal(key, year_quarter)
      end
    end
  end


  ######################################################################
  def test_in_process_design_reviews

    all_design_reviews       = DesignReview.find(:all)
    in_process_design_reviews = DesignReview.in_process_design_reviews
    in_process_design_reviews.each do |design_review|
      assert(design_review.posting_count > 0)
      assert(design_review.review_status.name == 'In Review')
    end

    (all_design_reviews - in_process_design_reviews).each do |dr|
      assert(dr.review_status.name != 'In Review')
    end

  end


  ######################################################################
  def test_inactive_reviewers_all_active
    assert(!@mx234a_pre_art_review.inactive_reviewers?)
  end


  ######################################################################
  def test_inactive_reviewers_all_inactive
    @mx234a_pre_art_review.design_review_results.each do |drr|
       drr.reviewer.password = ''
       drr.reviewer.update_attribute(:active, false)
    end

    assert(@mx234a_pre_art_review.inactive_reviewers?)
  end


  ######################################################################
  def test_inactive_reviewers_one_inactive
    @cathy_m.password = ''
    @cathy_m.update_attribute(:active, false)
    assert(@mx234a_pre_art_review.inactive_reviewers?)
  end


  ######################################################################
  def test_inactive_reviewers_list_all_active
    assert_equal([], @mx234a_pre_art_review.inactive_reviewers)
  end


  ######################################################################
  def test_inactive_reviewers_list_all_inactive
    @mx234a_pre_art_review.design_review_results.each do |drr|
      drr.reviewer.password = ''
      drr.reviewer.update_attribute(:active, false)
    end

    expected_reviewers = [@rich_a,    @lisa_a,    @lee_s,   @espo,
                          @jim_l,     @dan_g,     @art_d,   @matt_d,
                          @heng_k,    @john_g,    @cathy_m, @anthony_g,
                          @tom_f,     @dave_m].sort_by { |r| r.last_name}
    assert_equal(expected_reviewers,
                 @mx234a_pre_art_review.inactive_reviewers.sort_by { |r| r.last_name})
  end


  ######################################################################
  def test_inactive_reviewers_list_one_inactive
    @cathy_m.password = ''
    @cathy_m.update_attribute(:active, false)
    assert_equal([@cathy_m], @mx234a_pre_art_review.inactive_reviewers)
  end


  ######################################################################
  def test_results_with_inactive_users_list_all_active
    assert_equal([], @mx234a_pre_art_review.results_with_inactive_users)
  end


  ######################################################################
  def test_results_with_inactive_users_list_all_inactive
    @mx234a_pre_art_review.design_review_results.each do |drr|
      drr.reviewer.password = ''
      drr.reviewer.update_attribute(:active, false)
    end

    expected_results = @mx234a_pre_art_review.design_review_results.sort_by { |result| result.role_id }
    results_with_inactive_users = @mx234a_pre_art_review.results_with_inactive_users.sort_by do |result|
      result.role_id
    end.collect { |r| r.role.display_name}
    
    assert_equal(expected_results.size, results_with_inactive_users.size)
    assert_equal(expected_results.collect { |r| r.role.display_name}, results_with_inactive_users)
  end


  ######################################################################
  def test_results_with_inactive_users_list_one_inactive
    @cathy_m.password = ''
    @cathy_m.update_attribute(:active, false)
    assert_equal([design_review_results(:mx234a_pre_artwork_pcb_ig)],
                 @mx234a_pre_art_review.results_with_inactive_users)
  end


  ######################################################################
  def test_unprocessed_results_list_all_processed
    @mx234a_pre_art_review.design_review_results.each do |drr|
      drr.result = 'APPROVED'
    end
    assert_equal([], @mx234a_pre_art_review.unprocessed_results)
  end


  ######################################################################
  def test_unprocessed_results_list_all_unprocessed
    expected_results = @mx234a_pre_art_review.design_review_results.sort_by { |result| result.role_id }
    unprocessed_results = @mx234a_pre_art_review.unprocessed_results.sort_by do |result|
      result.role_id
    end.collect { |r| r.role.display_name}

    assert_equal(expected_results.size, unprocessed_results.size)
    assert_equal(expected_results.collect { |r| r.role.display_name}, unprocessed_results)
  end


  ######################################################################
  def test_unprocessed_results_list_one_unprocessed
    @mx234a_pre_art_review.design_review_results.each do |drr|
      next if drr.id == design_review_results(:mx234a_pre_artwork_pcb_ig).id
      drr.result = 'APPROVED'
    end
    assert_equal([design_review_results(:mx234a_pre_artwork_pcb_ig)],
                 @mx234a_pre_art_review.unprocessed_results)
  end


  ######################################################################
  def test_no_comments_expected
    assert_equal([], @mx234a_pre_art_review.comments(@john_g))
  end


  ######################################################################
  def test_comments_expected
    assert_equal([design_review_comments(:comment_four),
                  design_review_comments(:comment_one)],
                @mx234a_pre_art_review.comments(@cathy_m))
  end


  ######################################################################
  def test_no_active_design_reviews
    DesignReview.delete_all
    assert_equal([], DesignReview.active_design_reviews)
  end


  ######################################################################
  def test_active_design_reviews_only_returns_active_reviews
    DesignReview.active_design_reviews.each do |dr|
      assert(dr.in_review? || dr.pending_repost? || dr.on_hold?)
    end
  end


  ######################################################################
  def test_active_design_reviews_only_skips_nonactive_reviews
    active_design_reviews = DesignReview.active_design_reviews
    all_design_reviews    = DesignReview.find(:all)
    (all_design_reviews - active_design_reviews).each do |dr|
      assert(!(dr.in_review? || dr.pending_repost? || dr.on_hold?))
    end
  end


  ######################################################################
  def test_active
    design_review              = DesignReview.new
    active_review_status_names = ['In Review', 'Pending Repost', 'Review On-Hold']

    ReviewStatus.find(:all).each do |review_status|
      design_review.review_status = review_status
      if active_review_status_names.detect { |name| name == design_review.review_status.name }
        assert(design_review.active?)
      else
        assert(!design_review.active?)
      end
    end
    
  end


  ######################################################################
  def notest_dump
    active_design_reviews = DesignReview.active_design_reviews
    active_design_reviews.each do |design_review|
      puts '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'
      puts 'Design Review:  ' + design_review.id.to_s
      puts 'Name:           ' + design_review.design.directory_name
      puts 'Status:         ' + design_review.review_status.name
      puts 'Type:           ' + design_review.review_type.name
      puts 'Review Results: ' + design_review.design_review_results.size.to_s
      design_review.design_review_results.each do |drr|
        puts '  --------------------------------------------------------'
        puts '  DRR:      ' + drr.id.to_s
        puts '  Result:   ' + drr.result
        puts '  Reviewer: ' + drr.reviewer.name
        puts '  Role:     ' + drr.role.name
      end
    end
  end


  ######################################################################
  def test_my_processed_reviews

    my_processed_design_reviews = DesignReview.my_processed_reviews(@espo)
    my_processed_design_reviews.each do |dr|
      dr.design_review_results.each do |drr|
        assert(drr.result == 'APPROVED' || drr.result == 'WAIVED') if drr.reviewer == @espo
      end
      dr.design_review_results.delete_if { |drr| drr.reviewer == @espo }
    end

    # Look through the other results and make sure that either the review was not
    # assigned to espo, or if it was then espo has not processed the review.
    (DesignReview.active_design_reviews - my_processed_design_reviews).each do |dr|
      dr.design_review_results.each do |drr|
        assert((drr.reviewer != @espo) ||
               ( (drr.reviewer == @espo) &&
                !(drr.result == 'APPROVED' || drr.result == 'WAIVED')) )
      end
    end

  end


  ######################################################################
  def test_my_unprocessed_reviews

    my_unprocessed_design_reviews = DesignReview.my_unprocessed_reviews(@espo)
    my_unprocessed_design_reviews.each do |dr|
      dr.design_review_results.each do |drr|
        assert(drr.result != 'APPROVED' && drr.result != 'WAIVED') if drr.reviewer == @espo
      end
      dr.design_review_results.delete_if { |drr| drr.reviewer == @espo }
    end

    # Look through the other results and make sure that either the review was not
    # assigned to espo, or if it was then espo has processed the review.
    (DesignReview.active_design_reviews - my_unprocessed_design_reviews).each do |dr|
      dr.design_review_results.each do |drr|
        assert((drr.reviewer != @espo) ||
               ( (drr.reviewer == @espo) &&
                (drr.result == 'APPROVED' || drr.result == 'WAIVED')) )
      end
    end

  end


  ######################################################################
  def test_aaa_reviews_assigned_to_peers_role_in_all_reviews

  #
  #  Named test_aaa_reviews_assigned_to_peers_role_in_all_reviews to force
  #  the test to run before test_no_active_design_reviews.  There is not
  #  obvious reason why this fails when that test is run first.
  #  TODO: Figure it out.
  #

    reviews_assigned_to_peers = DesignReview.reviews_assigned_to_peers(@lee_s)
    reviews_assigned_to_peers.each do |dr|
      assert(!dr.design_review_results.detect { |drr| drr.reviewer == @lee_s })
    end

    # Look through the other results and make sure that if the user has a role
    # in the review that the user is assigned.
    (DesignReview.active_design_reviews - reviews_assigned_to_peers).each do |dr|
      review_roles   = dr.design_review_results.collect { |drr| drr.role }
      roles_assigned = review_roles & @lee_s.roles != []
      assert(!roles_assigned || (roles_assigned && dr.is_reviewer?(@lee_s)))
    end

  end


  ######################################################################
  def test_reviews_assigned_to_peers_role_not_in_all_reviews

    reviews_assigned_to_peers = DesignReview.reviews_assigned_to_peers(@lisa_a)
    reviews_assigned_to_peers.each do |dr|
      assert(!dr.design_review_results.detect { |drr| drr.reviewer == @lisa_a })
    end

    # Look through the other results and make sure that if the user has a role
    # in the review that the user is assigned.
    (DesignReview.active_design_reviews - reviews_assigned_to_peers).each do |dr|
      review_roles = dr.design_review_results.collect { |drr| drr.role }
      roles_assigned = review_roles & @lisa_a.roles != []
      assert(!roles_assigned || (roles_assigned && dr.is_reviewer?(@lisa_a)))
    end

  end


  ######################################################################
  def test_my_roles_no_roles
    assert_equal([], @la455b_placement_review.my_roles(@matt_d))
  end


  ######################################################################
  def test_my_roles_one_role
    assert_equal([@ce_dft], @la455b_placement_review.my_roles(@espo))
  end


  ######################################################################
  def test_my_roles_multiple_roles
    assert_equal([@hweng, @tde], @mx600a_pre_artwork_review.my_roles(@rich_a))
  end


  ######################################################################
  def test_complete_no_roles
    assert(@la455b_placement_review.reviewer_is_complete?(@matt_d))
  end


  ######################################################################
  def test_complete_one_role
    assert(@la455b_placement_review.reviewer_is_complete?(@espo))
  end


  ######################################################################
  def test_incomplete_one_role
    assert(!@la455b_placement_review.reviewer_is_complete?(@tom_f))
  end


  ######################################################################
  def test_complete_multiple_roles
    assert(@mx600a_pre_artwork_review.reviewer_is_complete?(@rich_a))
  end


  ######################################################################
  def test_incomplete_multiple_roles_hw_role_incomplete
    hw_result = design_review_results(:pcb252_600_a0_o_pre_artwork_hw)
    hw_result.result = 'No Response'
    hw_result.save
    @mx600a_pre_artwork_review.reload
    assert(!@mx600a_pre_artwork_review.reviewer_is_complete?(@rich_a))
  end


  ######################################################################
  def test_incomplete_multiple_roles_tde_role_incomplete
    tde_result = design_review_results(:pcb252_600_a0_o_pre_artwork_tde)
    tde_result.result = 'No Response'
    tde_result.save
    @mx600a_pre_artwork_review.reload
    assert(!@mx600a_pre_artwork_review.reviewer_is_complete?(@rich_a))
  end


  ######################################################################
  def test_incomplete_multiple_roles_both_roles_incomplete
    hw_result = design_review_results(:pcb252_600_a0_o_pre_artwork_hw)
    hw_result.result = 'No Response'
    hw_result.save
    tde_result = design_review_results(:pcb252_600_a0_o_pre_artwork_tde)
    tde_result.result = 'No Response'
    tde_result.save
    @mx600a_pre_artwork_review.reload
    assert(!@mx600a_pre_artwork_review.reviewer_is_complete?(@rich_a))
  end


  ######################################################################
  def test_my_peer_results_no_peers
    assert_equal([], @mx234a_release_review.my_peer_results(@lee_s))
  end


  ######################################################################
  def test_my_peer_results_peers
    assert_equal([design_review_results(:pcb252_600_a0_o_pre_artwork_hw)],
                 @mx600a_pre_artwork_review.my_peer_results(@lee_s))
  end


  ######################################################################
  def test_design_review_with_no_posting_timestamps
    assert_equal([], @mx234a_release_review.posting_timestamps)
  end


  ######################################################################
  def test_design_review_with_posting_timestamps

    assert_equal(3, @mx234a_pre_art_review.posting_timestamps.size)

    time = @mx234a_pre_art_review.posting_timestamps.first.posted_at
    @mx234a_pre_art_review.posting_timestamps.each do |timestamp|
      assert(time <= timestamp.posted_at)
      time = timestamp.posted_at
    end


  end


  ######################################################################
  def test_set_posting_timestamps_time_specified

    time = Time.now
    @mx234a_pre_art_review.set_posting_timestamp(time)
    last_timestamp = @mx234a_pre_art_review.posting_timestamps.last

    assert(time.to_i == last_timestamp.posted_at.to_i)

  end


  ######################################################################
  def test_set_posting_timestamps_time_not_specified

    start_time = Time.now
    sleep 1
    @mx234a_pre_art_review.set_posting_timestamp
    sleep 1
    last_timestamp = @mx234a_pre_art_review.posting_timestamps.last

    assert(start_time < last_timestamp.posted_at &&
           Time.now   > last_timestamp.posted_at)

  end


end
