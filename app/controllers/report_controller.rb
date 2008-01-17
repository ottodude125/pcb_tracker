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


require 'gruff'


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
  # date          - Indicates the quarter that the user wants to gather
  #                 reports for
  # end_date      - Indicates the year that the user wants to gather
  #                 reports for
  # download      - a check box that indicates that the user want to
  #                 download the graph
  #
  ######################################################################
  #
  def report_card_rollup

    @lcr_designers = Role.lcr_designers
    
    @team_member_id   = params[:team_member]   ? params[:team_member][:id].to_i   : 0
    @quarter = !params[:quarter] ? current_quarter()  : params[:quarter][:number].to_i
    @year    = !params[:date]    ? Time.now.year      : params[:date][:year].to_i

    report_cards = OiAssignmentReport.report_card_rollup(@team_member_id, @quarter, @year)

    @total_report_cards = report_cards.size
    @high_report_cards = report_cards.collect { |rc| rc if rc.oi_assignment.complexity_name == 'High' }
    @med_report_cards  = report_cards.collect { |rc| rc if rc.oi_assignment.complexity_name == 'Medium' }
    @low_report_cards  = report_cards.collect { |rc| rc if rc.oi_assignment.complexity_name == 'Low' }
    @high_report_cards.compact!
    @med_report_cards.compact!
    @low_report_cards.compact!

    idc_designer = @team_member_id > 0 ? User.find(@team_member_id).name : 'all'
    idc_designer.gsub!(/ /, '_')
    common = "graphs/Q#{@quarter}_#{@year}_#{idc_designer}"
    @rework_graph_filename       = common + '_rework_graph.png'
    @report_count_graph_filename = common + '_report_count_graph.png'

    if @total_report_cards == 0
      
      @no_reports_msg = "No Report Cards for Q#{@quarter} #{@year}"
    end

  end


  # Download the rework percentage graph to the user's computer.
  # 
  # :call-seq:
  #   download_rework_graph() -> graph
  #
  # Returns a copy of the rework graph displayed on the report
  # card rollup screen.
  def download_rework_graph

    graph = OiAssignmentReport.report_card_rollup(params[:team_member_id].to_i,
                                                  params[:quarter].to_i,
                                                  params[:year].to_i,
                                                  "rework")

    send_data(graph.to_blob,
              :disposition => 'attachment',
              :type        => 'image/png',
              :filename    => "lcr_rework_graph.png")     

  end
  
  
  # Download the report count graph to the user's computer.
  # 
  # :call-seq:
  #   download_report_count_graph() -> graph
  #
  # Returns a copy of the report count graph displayed on the report
  # card rollup screen.
  def download_report_count_graph

    graph = OiAssignmentReport.report_card_rollup(params[:team_member_id].to_i,
                                                  params[:quarter].to_i,
                                                  params[:year].to_i,
                                                  "assignment_count")

    send_data(graph.to_blob,
              :disposition => 'attachment',
              :type        => 'image/png',
              :filename    => "lcr_assignment_count_graph.png")     

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
  
    status_list = ReviewStatus.find(:all)
  
    # Get all of the design reviews that have not been completed
    review_completed = status_list.detect { |rs| rs.name == 'Review Completed' }
    review_skipped   = status_list.detect { |rs| rs.name == 'Review Skipped' }
    not_started      = status_list.detect { |rs| rs.name == 'Not Started' }
    terminated       = status_list.detect { |rs| rs.name == 'Review Terminate'}
    condition        = "review_status_id != '#{review_completed.id}' AND " +
                       "review_status_id != '#{not_started.id}'      AND " +
                       "review_status_id != '#{review_skipped.id}'   AND " +
                       "review_status_id != '#{terminated.id}'"
 
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
