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


#require 'gruff'


class ReportController < ApplicationController


  def cycle_time_select
  
    @review_roles = Role.review_roles()

  end
  
  
  def generate_cycle_time_report
  
    role_id = params[:role][:id]
    
    @all_designs = Design.find(:all)
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
    
    if !params[:start_date]
      @start_date = Time.now.start_of_quarter
    else
      date        = params[:start_date]
      @start_date = Time.local(date[:year], date[:month], date[:day]).to_date
    end
    
    if !params[:end_date]
      @end_date = Date.today
    else
      date      = params[:end_date]
      @end_date = Time.local(date[:year], date[:month], date[:day]).to_date
    end

    team_member                  = team_member(@team_member_id)
    team_member_file_name        = team_member_file_name(team_member)
    
    @ticks  = OiCategory.find(:all, :select => :label).map { |l| l.label }.join("|")
    @labels = OiAssignment.complexity_list.map { |c| "{label:\'#{c[0]}\'}" }.join(",")
    
    if @end_date >= @start_date
      
      @range = @start_date.to_s + ' - ' + @end_date.to_s
      @designer  = team_member ? team_member.name : "All Designers" 
      
      data = OiAssignmentReport.report_card_rollup(@team_member_id, 
                                                   @start_date,
                                                   @end_date)
                                                           
      report_cards = data[:report_cards]
      percents = data[:percents]
      @pct_series_vars = ""
      @pct_series_list = []
      percents.each_with_index do | pcts, i |
      #create javascript code for the series
        @pct_series_vars += "var pct#{i} = [" + pcts.join(",") + "];\n"
        @pct_series_list.push("pct#{i}")
      end
      counts   = data[:counts]
      @cnt_series_vars = ""
      @cnt_series_list = []
      counts.each_with_index do | cnts, i |
      #create javascript code for the series
        @cnt_series_vars += "var cnt#{i} = [" + cnts.join(",") + "];\n"
        @cnt_series_list.push("cnt#{i}")
      end
      
      
      @total_report_cards = report_cards.size
      if @total_report_cards > 0
        @high_report_cards = report_cards.collect { |rc| rc if rc.oi_assignment.complexity_name == 'High' }
        @med_report_cards  = report_cards.collect { |rc| rc if rc.oi_assignment.complexity_name == 'Medium' }
        @low_report_cards  = report_cards.collect { |rc| rc if rc.oi_assignment.complexity_name == 'Low' }
        @high_report_cards.compact!
        @med_report_cards.compact!
        @low_report_cards.compact!
      else     
        @no_reports_msg = "No Report Cards for #{@start_date.to_s} through #{@end_date.to_s}"
      end
      flash['notice'] = nil
    else
      @total_report_cards = 0
      flash['notice'] = "WARNING: the end date preceeds the start date - no reports retrieved"
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
                                                  params[:start_date],
                                                  params[:end_date],
                                                  params[:rework_graph_filename],
                                                  params[:rework_graph_title],
                                                  '',
                                                  '',
                                                  "rework")

    send_data(graph.to_blob,
              :disposition => 'attachment',
              :type        => 'image/png',
              :filename    => params[:rework_graph_filename])     

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
                                                  params[:start_date],
                                                  params[:end_date],
                                                  '',
                                                  '',
                                                  params[:report_count_graph_filename],
                                                  params[:report_count_graph_title],
                                                  "assignment_count")

    send_data(graph.to_blob,
              :disposition => 'attachment',
              :type        => 'image/png',
              :filename    => params[:report_count_graph_filename])     

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

    if params[:id]
      @design_review            = DesignReview.find(params[:id])
      incomplete_design_reviews = [@design_review]
    else
      incomplete_design_reviews = DesignReview.in_process_design_reviews
    end

    result_hash = {}
    incomplete_design_reviews.each do |design_review|
      design_review.unprocessed_results.each do |review_result|
        result_hash[review_result.reviewer] = [] unless result_hash[review_result.reviewer]
        result_hash[review_result.reviewer] << review_result
      end
    end

    @reviewer_result_list = result_hash.to_a.sort_by { |r| r[0].last_name }


  end
  
  
  def summary_data
    @board_design_entries = BoardDesignEntry.summary_data
    @design_reviews       = DesignReview.summary_data
  end
  
  
private


  def team_member_file_name(team_member)
    team_member ? team_member.name.gsub(/ /, '_') : 'all'
  end
  
  
  def team_member(team_member_id)
    User.find(team_member_id) if team_member_id.to_i > 0
  end
  
  
  def common_part(start_date, end_date, designer)
    "#{start_date.to_s}_#{end_date.to_s}_#{designer}"
  end
  
  
  def rework_graph_filename(common_part)
    common_part + '_rework_graph.png'
  end
  
  
  def report_count_graph_filename(common_part)
    common_part + '_report_count_graph.png'
  end
 
  
end
