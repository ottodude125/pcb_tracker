########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: oi_assignment_report.rb
#
# This file maintains the state for oi_assignment_reports.
#
# $Id$
#
########################################################################

class OiAssignmentReport < ActiveRecord::Base

  belongs_to :oi_assignment
  belongs_to :user


#
# Constants
# 
NOT_SCORED = 256

REPORT_CARD_SCORING_TABLE = [ [   0, '0% Rework' ],
                              [  20, 'Approximately 20% Rework' ],
                              [  40, 'Approximately 40% Rework' ],
                              [  60, 'Approximately 60% Rework' ],
                              [  80, 'Approximately 80% Rework' ],
                              [ 100, '100% Rework'] ]
                              
                              
  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


  ######################################################################
  #
  # report_card_scoring
  #
  # Description:
  # This method returns the REPORT_CARD_SCORING_TABLE.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def OiAssignmentReport.report_card_scoring
    REPORT_CARD_SCORING_TABLE
  end


  ######################################################################
  #
  # min_score
  #
  # Description:
  # This method returns minimum score in the REPORT_CARD_SCORING_TABLE.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def OiAssignmentReport.min_score
    REPORT_CARD_SCORING_TABLE.collect { |score| score[0] }.min
  end


  ######################################################################
  #
  # max_score
  #
  # Description:
  # This method returns maximum score in the REPORT_CARD_SCORING_TABLE.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def OiAssignmentReport.max_score
    REPORT_CARD_SCORING_TABLE.collect { |score| score[0] }.max
  end
  
  
  #
  # Generate the report cart rollup reports
  # 
  # :call-seq:
  #   OiAssignmentReport.report_card_rollup(designer_id,
  #                                         start_date,
  #                                         end_date,
  #                                         rework_filename,
  #                                         report_count_filename,
  #                                         download)
  #
  # Retrieves the report cards for the date range provided.  If the download
  # flag indicates 'none' then the reports are returned.  Otherwise the graph
  # specified by download is returned.
  #
  def self.report_card_rollup(designer_id, 
                              start_date, 
                              end_date,
                              rework_filename,
                              report_count_filename,
                              download = 'none')
  
    query_end_date = (end_date.to_time + 1.day).to_date
    conditions = "created_on >= '#{start_date}' and created_on < '#{query_end_date}'"

    # Gather all of the report cards that were created in the quarter and toss 
    # out the assignments that are not complete.
    report_cards = OiAssignmentReport.find(:all,
                                           :conditions => conditions,
                                           :order      => 'created_on')
    report_cards.delete_if { |rc| !rc.oi_assignment.complete? }

    # If the report is for a specific designer, toss out the assignments 
    # that do not apply for the designer.
    if designer_id > 0
      report_cards.delete_if { |rc| rc.oi_assignment.user_id != designer_id }
      idc_designer = User.find(designer_id).name
    else
      idc_designer = ''
    end
    
    category_count = OiCategory.count
    score_summary = { 'High'   => { :count => Array.new(category_count, 0), 
                                    :total => Array.new(category_count, 0) },
                      'Medium' => { :count => Array.new(category_count, 0), 
                                    :total => Array.new(category_count, 0) },
                      'Low'    => { :count => Array.new(category_count, 0), 
                                    :total => Array.new(category_count, 0) } }

    @total_score = 0
    report_cards.each do |report_card| 
      @total_score += report_card.score
      
      i = report_card.oi_assignment.oi_instruction.oi_category_section.oi_category.id - 1
      
      summary = score_summary[report_card.oi_assignment.complexity_name]
      summary[:count][i] += 1
      summary[:total][i] += report_card.score

    end
    
    # Create the graphs.
    start_date = start_date.to_s
    end_date   = end_date.to_s    
    rework_graph = create_rework_graph(score_summary, 
                                       start_date, 
                                       end_date, 
                                       idc_designer, 
                                       rework_filename)
    count_graph  = create_assignment_count_graph(score_summary, 
                                                 start_date,
                                                 end_date, 
                                                 idc_designer, 
                                                 report_count_filename)

    # Return the report cards to the caller.
    if download == 'none'
      return report_cards
    elsif download == 'rework'
      return rework_graph
    elsif download == 'assignment_count'
      return count_graph
    end
    
  end
  
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################


  ######################################################################
  #
  # score_value
  #
  # Description:
  # This method returns the textual value for the score.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def score_value
    REPORT_CARD_SCORING_TABLE[self.score/20][1]
  end


  ##############################################################################
  #
  # Private Methods
  # 
  ##############################################################################
private



  # Create rework percentage graph.
  # 
  # :call-seq:
  #   create_rework_graph(score_summary, start_date, end_date, idc_designer, graph_filename)
  #
  # Given the graph data (score summary) and the start and end dates this method 
  # generates the rework percentage graph.  If the idc_designer is not an empty string then
  # the name is included in the graph title.
  def self.create_rework_graph(score_summary, 
                               start_date, 
                               end_date, 
                               idc_designer,
                               graph_filename)
  
    title = 'LCR Process Step Evaluation: Percent Rework Roll Up -'
    date  = start_date + '-' + end_date
    graph = Gruff::Bar.new

    if idc_designer == ''
      graph.title = "#{date} #{title} All Designers"
    else
      graph.title = "#{date} #{title} #{idc_designer}"
    end

    # Adjust the font according to the length of the title
    graph.title_font_size  = graph.title.size < 50 ? 24 : 18

    #graph.theme_37signals
    
    graph.minimum_value    = 0
    graph.maximum_value    = 100
    graph.marker_count     = 5
    
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
    # bars are not all bunched around the bottom.
    while graph.maximum_value > max_value + 5
      graph.maximum_value -= 5
    end
    
    idc_designer = 'all' if idc_designer == ''
    idc_designer.gsub!(/ /, '_')
    graph.write("public/images/graphs/#{graph_filename}")

    return graph
  
  end
  
  
  # Create the report count graph.
  # 
  # :call-seq:
  #   create_assignment_count_graph(score_summary, start_date, end_date, idc_designer, graph_filename)
  #
  # Given the graph data (score summary) and the start and end dates this method generates 
  # the report card count graph.  If the idc_designer is not an empty string then
  # the name is included in the graph title.
  def self.create_assignment_count_graph(score_summary, 
                                         start_date, 
                                         end_date, 
                                         idc_designer,
                                         graph_filename)
  
    title = 'LCR Process Step Evaluation: Report Count Roll Up -'
    date  = start_date + '-' + end_date
    graph = Gruff::Bar.new

    if idc_designer == ''
      graph.title = "#{date} #{title} All Designers"
    else
      graph.title = "#{date} #{title} #{idc_designer}"
    end

    # Adjust the font according to the length of the title
    graph.title_font_size  = graph.title.size < 50 ? 24 : 18

    #graph.theme_37signals
    
    graph.minimum_value    = 0
    graph.maximum_value    = 0
    graph.marker_count     = 5
    
    graph.sort             = false
    graph.y_axis_label     = 'Completed Report Cards'
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
        graph_data[i] = data[:count][i] 
        max_value = graph_data[i] if graph_data[i] > max_value
      end
      graph.data("#{complexity} Complexity", graph_data)
    
    end
    
    # Adjust the max y value on the graph so that
    # the bars are not all bunched around the bottom
    while graph.maximum_value < max_value + 10
      graph.maximum_value += 10
    end 

    idc_designer = 'all' if idc_designer == ''
    idc_designer.gsub!(/ /, '_')
    graph.write("public/images/graphs/#{graph_filename}")

    return graph
  
  end
  
  
end
