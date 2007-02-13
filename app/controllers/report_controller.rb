########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: report_controller.rb
#
# This contains the logic to manage reports.
#
# $Id$
#
########################################################################

class ReportController < ApplicationController


  def cycle_time_select
  
    @review_roles = Role.review_roles()

  end
  
  
  def generate_cycle_time_report
  
    role_id = params[:role][:id]
    
    @all_designs = Design.find_all
    @all_designs.delete_if { |d| d.phase_id != Design::COMPLETE }
    
    @all_results         = []
    @design_review_stats = {}
    @all_designs.each do |design|
      design.design_reviews.each do |design_review|
        design_review.design_review_results.each do |drr|
          @all_results << drr  if drr.role_id == role_id
        end
      end
    end
  
  end
  
  
  ######################################################################
  #
  # report_card_rollup
  #
  # Description:
  # This method retrieves the information to display the report card
  # rollup
  #
  # Parameters:
  # lead_designer - If 0 then all lead designers should be included in
  #                 the results.  Otherwise, it is the identifier of the
  #                 lead designer to include in the results.
  # team_member   - If 0 then all team members should be included in
  #                 the results.  Otherwise, it is the identifier of the 
  #                 team member to include in the results.
  # category      - If 0 then all categories should be included in the
  #                 results.  Otherwise, it is the identifier of the 
  #                 category to include in the results.
  # start_date    - Contains the start date in the date range for the
  #                 query condition
  # end_date      - Contains the end date in the date range for the
  #                 query condition
  #
  ######################################################################
  #
  def report_card_rollup
  
    @ter_designers = []
    @lcr_designers = []
    Role.find_by_name("Designer").users.sort_by { |u| u.last_name}.each do |designer|
      if designer.employee?
        @ter_designers << designer
      else
        @lcr_designers << designer
      end
    end
    
    @categories = OiCategory.find_all.sort_by { |c| c.id }


    @lead_designer_id = params[:lead_designer] ? params[:lead_designer][:id].to_i : 0
    @team_member_id   = params[:team_member]   ? params[:team_member][:id].to_i   : 0
    @category_id      = params[:category]      ? params[:category][:id].to_i      : 0
    
    if !params[:start_date]
      @start_date = start_of_quarter()
    else
      date = params[:start_date]
      @start_date = Time.local(date[:year], date[:month], date[:day]).to_date
    end
    
    if !params[:end_date]
      @end_date   = Date.today
    else
      date = params[:end_date]
      @end_date = Time.local(date[:year], date[:month], date[:day]).to_date
    end
    
    end_date = (@end_date.to_time + 1.day).to_date
    query_conditions = "created_on >= '#{@start_date}'" +
                       " and created_on <= '#{end_date}'"
    if @lead_designer_id > 0
      query_conditions += " and user_id = '#{@lead_designer_id}'"
    end
    
    if @end_date < @start_date
      flash['notice'] = "Warning: the end date preceeds the start date - no reports retrieved"
    else
      flash['notice'] = nil
    end


    report_cards = OiAssignmentReport.find_all(query_conditions)
    
    if @team_member_id > 0
      report_cards.delete_if { |rc| rc.oi_assignment.user_id != @team_member_id }
    end

    if @category_id > 0
      report_cards.delete_if do |rc| 
        rc.oi_assignment.oi_instruction.oi_category_section.oi_category_id != @category_id
      end
    end
    
    @report_cards = report_cards.sort_by { |rc| rc.created_on }

    @total_score = 0
    @score_distribution = {}
    @score_distribution.default= 0
    @report_cards.each do |report_card| 
      @total_score                           += report_card.score
      @score_distribution[report_card.score] += 1 
    end
  end
  
  
  ######################################################################
  #
  # reviewer_workload
  #
  # Description:
  # This method retrieves the information for the reviewer workload 
  # view.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def reviewer_workload
  
    status_list = ReviewStatus.find_all
  
    # Get all of the design reviews that have not been completed
    review_completed = status_list.detect { |rs| rs.name == 'Review Completed' }
    review_skipped   = status_list.detect { |rs| rs.name == 'Review Skipped' }
    not_started      = status_list.detect { |rs| rs.name == 'Not Started' }
    condition        = "review_status_id != '#{review_completed.id}' AND " +
                       "review_status_id != '#{not_started.id}' AND " +
                       "review_status_id != '#{review_skipped.id}'"
 
    design_reviews = DesignReview.find_all(condition)
    
    if params[:id]
      @design_review = DesignReview.find(params[:id])
      reviewer_ids  = @design_review.design_review_results.collect { |drr| drr.reviewer_id } 
    end

    reviewer_list = {}
    design_reviews.each do |design_review|
      design_review.design_review_results.each do |drr|
        if !reviewer_ids ||
           (reviewer_ids && reviewer_ids.include?(drr.reviewer_id) )
          if !reviewer_list[drr.reviewer_id]
            reviewer_list[drr.reviewer_id] = { :user    => User.find(drr.reviewer_id), 
                                               :results => [] }
          end
          reviewer_list[drr.reviewer_id][:results] << drr
        end
      end
    end
    
    #Sort each of the review results by result and criticality
    reviewer_list.each do |reviewer_id, user_results| 
      user_results[:results] = user_results[:results].sort_by { |drr| [drr.result, drr.design_review.priority.value] }
    end
    
    reviewer_list  = reviewer_list.to_a.sort_by { |e| e[1][:user].last_name }
    @reviewer_list = reviewer_list.collect { |e| e[1] }
    
  rescue
    flash['notice'] = "Error: design review id not found in the database"
    redirect_to(:controller => 'tracker', :action => 'index') 
  end
  
  
end
