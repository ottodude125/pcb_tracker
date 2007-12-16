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

    start_month = (@quarter - 1) * 3 + 1
    end_month   = start_month < 10 ? start_month + 3 : 1
    end_year    = start_month < 10 ? @year           : @year + 1
    
    start_date = Date.new(@year,    start_month, 1)
    end_date   = Date.new(end_year, end_month,   1)
    conditions = "created_on >= '#{start_date}' and created_on < '#{end_date}'"
    @report_cards = OiAssignmentReport.find(:all,
                                            :conditions => conditions,
                                            :order      => 'created_on')
    @report_cards.delete_if { |rc| !rc.oi_assignment.complete? }
    
    if @team_member_id > 0
      @report_cards.delete_if { |rc| rc.oi_assignment.user_id != @team_member_id }
    end
    
    category_count = OiCategory.count
    score_summary = { 'High'   => { :count => Array.new(category_count, 0), 
                                    :total => Array.new(category_count, 0) },
                      'Medium' => { :count => Array.new(category_count, 0), 
                                    :total => Array.new(category_count, 0) },
                      'Low'    => { :count => Array.new(category_count, 0), 
                                    :total => Array.new(category_count, 0) } }

    @total_score = 0
    @report_cards.each do |report_card| 
      @total_score += report_card.score
      
      i = report_card.oi_assignment.oi_instruction.oi_category_section.oi_category.id - 1
      
      summary = score_summary[report_card.oi_assignment.complexity_name]
      summary[:count][i] += 1
      summary[:total][i] += report_card.score

    end
    
    ##################################################
    score_summary.each do |complexity, data|
      logger.info("#### COMPLEXITY: #{complexity}")
      data.each do |label, arr|
        logger.info(" ---- #{label}")
        arr.each { |av| logger.info("      #{av}") }
      end
    end
    ##################################################
    
    download = params[:download] && params[:download][:yes] == '1'
    
    designer = @lcr_designers.detect { |d| d.id == @team_member_id }
    idc_designer = designer ? designer.name : ''
    create_graph(score_summary,
                 @quarter,
                 @year,
                 idc_designer,
                 download)
    
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
  
  
private

  def create_graph(score_summary,
                   quarter, 
                   year,
                   idc_designer,
                   download)
  
    title = 'LCR Process Step Evaluation'
    date  = "Q#{quarter}-#{year}"
    graph = Gruff::Bar.new

    if idc_designer == ''
      graph.title = "#{date} #{title} Roll Up"
    else
      graph.title = "#{date} #{title} - #{idc_designer}"
    end

    # Adjust the font according to the length of the title
    graph.title_font_size  = graph.title.size < 50 ? 26 : 22

    #graph.theme_37signals
    
    graph.minimum_value    = 0
    graph.maximum_value    = 100
    graph.marker_count     = 10
    
    graph.sort             = false
    graph.y_axis_label     = 'Percentage of Rework'
    graph.x_axis_label     = 'Categories'
    graph.legend_font_size = 14
    graph.legend_box_size  = 12
    graph.marker_font_size = 14
    
    graph.no_data_message  = "\n\nNo Report\nCards\nRetrieved"
    
    categories = OiCategory.list
    categories.each { |c| graph.labels[c.id-1] = c.label }
    
    max_value = 0
    score_summary.each do |complexity, data|
    
      graph_data = []
      0.upto(data[:count].size - 1) do |i|
        graph_data[i] = data[:count][i] == 0 ? 0 : data[:total][i].to_f / data[:count][i]
        max_value = graph_data[i] if graph_data[i] > max_value
      end
      graph.data("#{complexity} Complexity", graph_data)
    
    end
    
    # Adjust the max y value on the graph so that 
    # bars are not all bunched around the buttom.
    while graph.maximum_value > max_value * 2
      graph.maximum_value /= 2
    end
    
    if download
      send_data(graph.to_blob,
                :disposition => 'attachment',
                :type        => 'image/png',
                :filename    => "#{graph.title}.png")
    else
      graph.write('public/images/graphs/lcr_process_report.png')
    end
  
  end
  
  
end
