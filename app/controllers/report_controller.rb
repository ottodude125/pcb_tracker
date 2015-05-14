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
  
  def user_review_history
    Date::DATE_FORMATS[:mmddyyyy] = "%m/%d/%Y"
    @max_date    = Date.today.to_s(:mmddyyyy)
    @min_date = "1/1/2006"
    @from = params[:from].blank? ? @min_date : params[:from]
    @to   = params[:to].blank?   ? @max_date : params[:to]
    #convert m/d/y to y-m-d for database
    fromX   = @from.split("/")
    fromDB  = fromX[2] + "-" + fromX[0] + "-" + fromX[1]
    toX     = @to.split("/")
    toDB    = toX[2] + "-" + toX[0] + "-" + toX[1]

    @data = Array.new
    #review_results = DesignReviewResult.find_all_by_reviewer_id(@logged_in_user)
    review_results = DesignReviewResult.find(:all, :conditions => [
      "reviewer_id = #{@logged_in_user.id} AND " +
      "reviewed_on >= '#{fromDB}' AND " +
      "reviewed_on <= '#{toDB}'"
    ])
    
    @heads = [ "PCB #",
      "DESCRIPTION",
      "TYPE",
      "POSTED",
      "REVIEWED"] 
      
    review_results.group_by(&:design_review_id).each { | review_id, results |
      result = results.sort_by{ |r| r.reviewed_on}.reverse.first
      next if result.reviewed_on.blank?
      if result.design_review 
        design = result.design_review.design
        part_num = PartNum.find_by_design_id_and_use(result.design_review.design_id, "pcb")
        postdate = result.design_review.reposted_on.blank? ? 
          result.design_review.created_on : result.design_review.reposted_on
  
        item = [ part_num.name_string,
          part_num.description || "(Description not found)",
          result.design_review.review_name,
          postdate.format_dd_mon_yy,
	  result.reviewed_on.format_dd_mon_yy ]
      else
        item = [ "ERROR", "Review Result = #{result.id}" , "", "", ""]
      end
      @data << item
    }
    
    respond_to do | format | 
      format.html
      format.csv { send_data reviewer_to_csv(@heads,@data) }
    end
  end
    
  def reviewer_approval_time
    Date::DATE_FORMATS[:mmddyyyy] = "%m/%d/%Y"
    @max_date    = Date.today.to_s(:mmddyyyy)
    @min_date = (Date.today - 3.months).beginning_of_month.to_s(:mmddyyyy)
    @from = params[:from].blank? ? @min_date : params[:from]
    @to   = params[:to].blank?   ? @max_date : params[:to]
    #convert m/d/y to y-m-d for database
    fromX   = @from.split("/")
    fromDB  = fromX[2] + "-" + fromX[0] + "-" + fromX[1]
    toX     = @to.split("/")
    toDB    = toX[2] + "-" + toX[0] + "-" + toX[1]

    @data = Hash.new
    #review_results = DesignReviewResult.find_all_by_reviewer_id(@logged_in_user)
    review_results = DesignReviewResult.find(:all, :conditions => [
      "reviewed_on >= '#{fromDB}' AND " +
      "reviewed_on <= '#{toDB}'"
    ])
    
    @heads = [ "PCB","Description","Reviewer"]
    @types = ReviewType.select(:name).order(:sort_order).map(&:name)
      
    review_results.each { | result |
      next if result.reviewed_on.blank?
      if result.design_review 
        design     = result.design_review.design
        part_num   = PartNum.find_by_design_id_and_use(result.design_review.design_id, "pcb")
        pnum_str   = part_num.name_string
        pnum_sym   = pnum_str.to_sym
        postdate   = result.design_review.reposted_on.blank? ? 
          result.design_review.created_on : result.design_review.reposted_on
        reviewdate  = result.reviewed_on
        description = part_num.description || "(Description not found)"
        type        = result.design_review.review_name
        role        = result.role.display_name
        reviewer    = result.reviewer.name
        time        = business_days_between(postdate,reviewdate)
        rr_id       = result.design_review.id
        
        unless @data.has_key?(pnum_str) # Make a new board key
          @data[pnum_str] = Hash.new
          @data[pnum_str]["Description"] = description
        end
        unless @data[pnum_str].has_key?(reviewer)
          @data[pnum_str][reviewer] = Hash.new
        end
        @data[pnum_str][reviewer]["#{type}_time"] = time
        @data[pnum_str][reviewer]["#{type}_rr_id"] = rr_id
        @data[pnum_str][reviewer]["#{type}_role"] = role
      else
        #TODO: should put something here
      end
    }

    respond_to do | format | 
      format.html
      format.csv { send_data time_to_csv(@heads,@types,@data)}
    end

  end

  ######################################################################
  #
  # fir_metrics
  #
  # Description:
  # This method retrieves the information for the fir_metrics view 
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def fir_metrics

    ##### Data to aquire for each quarter #####
    # 1) Documentation Issues/Pins
    # 1a) Need get unique list of designs with ftp date within quarter with scheduler design_class != [P1 || P2] && design_process = standard
    # 1b) Need to sum pins for all designs 1a
    # 1c) Need to sum documentation issues for 1a
    # 1d) 1c/1b is solution
    # 2) Clarification Issues/Pins
    # 2a) Need to sum documentation issues for 1a
    # 2b) 2a/1b is solution
    # 3) Designs FTPd
    # 3a) 1a.count is solution
    # 4) Designs w/Documentation Issues
    # 4a) For each in 1a check if any doc issues and add to total
    # 5) Designs w/Clarification Issues
    # 5a) For each in 1a check if any clar issues and add to total
    
    @fir_quarterly_history = [] # Values for Top Sheet Graph
    @prod_des_wo_doc_changes = [] # Values for Top Sheet Table One
    @des_wo_doc_changes = [] # Values for Top Sheet Table Two
    @fir_pins_brds = [] # Values for Issues/Pins by Board Graph
    @fab_iss_deliverable = [] # Values for Fab Issues Sorted by Deliverable
    @fab_iss_drawing = [] # Values for Fab Drawing Issues Sorted by Drawing
    @fab_iss_mode = [] # Values for Fab Issues Sorted by Failure Mode
    ldxs, ldys, lcxs, lcys = [], [], [], [] # arrays for linear regression x/y values
    
    # Initialize FabDeliverable and Fab Drawing Value Arrays
    FabDeliverable.all.each do |fd|
      if fd.parent_id.nil?
        @fab_iss_deliverable << {"Deliverable" => fd.name, "Documentation Issue" => 0, "Vendor Clarification" => 0}
      else
        @fab_iss_drawing << {"Drawing" => fd.name, "Documentation Issue" => 0, "Vendor Clarification" => 0}
      end
    end
    # Initialize FabFailureMode Value Array
    FabFailureMode.all.each do |fm|
      @fab_iss_mode << {"Mode" => fm.name, "Documentation Issue" => 0}
    end      

    # Reverse step through each "OFFSET" to build data for that quarter for Top Sheet
    # On last quarter (most recent) generate values for all other graphs
    numQuarters = 5
    endQuarter = 1
    numQuarters.step(endQuarter,-1).each do |offset|
      # Initialize "offset" quarter vals for Top Sheet
      fir_quart = {}
      fir_quart["Documentation Issues/Pins"] = -1
      fir_quart["Clarification Issues/Pins"] = -1      
      fir_quart["Designs FTPd"] = -1
      fir_quart["Designs w/Documentation Issues"] = -1
      fir_quart["Designs w/Clarification Issues"] = -1
      fir_quart["Linear (Documentation Issues/Pins)"] = 0
      fir_quart["Linear (Clarification Issues/Pins)"] = 0
      fir_quart["Date"] = ""
      pincount = 0.00001
      
      # Get start/end date of offset quarter 
      quart_date = Date.today << (offset * 3)
      begin_date = quart_date.beginning_of_quarter
      end_date = quart_date.end_of_quarter
      
      # Get Quarter/Year string for graph and page title
      quarter = ((quart_date.beginning_of_quarter.month - 1) / 3) + 1
      fir_quart["Date"] = quarter.to_s + "Q" + quart_date.beginning_of_quarter.strftime("%y") 
      case quarter
      when 1 then @quarter = "first" 
      when 2 then @quarter = "second"
      when 3 then @quarter = "third"
      when 4 then @quarter = "fourth"
      else @quarter = ""
      end
      
      # Get unique design ids with ftp date in "offset" quarter
      ftps = FtpNotification.find(:all, :conditions => ["created_at > ? AND created_at < ?", begin_date, end_date] )     
      designs = ftps.map(&:design_id).uniq
      fir_quart["Designs FTPd"] = designs.count rescue 0

      # Get all fir doc/clarification issues for ftp'd designs
      @doc_firs = FabIssue.find(:all, :conditions => ["design_id IN (?) AND documentation_issue = ?", designs, true])
      @clr_firs = FabIssue.find(:all, :conditions => ["design_id IN (?) AND documentation_issue = ?", designs, false])
      fir_quart["Designs w/Documentation Issues"] = @doc_firs.map(&:design_id).uniq.count rescue 0
      fir_quart["Designs w/Clarification Issues"] = @clr_firs.map(&:design_id).uniq.count rescue 0
      
      # Get all Non P1/P2 board classes w/ standard design process and add up pins
      production_design_ids = []
      prod_design_pins = {}
      designs.each do |d|
        part_num = PartNum.get_design_pcb_part_number(d).name_string
        sched_part = PcbSchedulerPartNum.find_by_number_and_pcba(part_num+"A", false)
        sched_brd = PcbSchedulerBoard.find(sched_part.board_id)  rescue "Error"
        sched_brd_class = PcbSchedulerBoardClass.find(sched_brd.board_class_id) rescue "Error"
        sched_brd_des_proc = PcbSchedulerDesignProcess.find(sched_brd.design_process_id) rescue "Error"
        # if design found in scheduler and its brd_class is not P1/P2 and its brd_process is standard then add to list of designs
        if sched_brd_class != "Error" && sched_brd_class.name != "P1" && sched_brd_class.name != "P2" && sched_brd_des_proc.short_name == "SF"
          production_design_ids << d
          pincount += sched_brd.actual_ending_pin_count          
          
          # If last quarter to process then calculate issues/pins by board for single quarter graph
          if endQuarter == offset
            doc_iss_pins = (FabIssue.find_all_by_design_id_and_documentation_issue(d, true).count*1.0000/sched_brd.actual_ending_pin_count).round(5) rescue 0
            cla_iss_pins = (FabIssue.find_all_by_design_id_and_documentation_issue(d, false).count*1.0000/sched_brd.actual_ending_pin_count).round(5) rescue 0
            @fir_pins_brds << {"Part Number" => part_num + " w/" + sched_brd.actual_ending_pin_count.to_s + " Pins",
                                "Documentation Issues/Pins" => doc_iss_pins, 
                                "Clarification Issues/Pins" => cla_iss_pins}
          end
        end
      end

      # Get sum of fir doc/clarification issues for ftp'd designs Non P1/P2 board classes w/ standard design process
      prod_doc_firs = FabIssue.find(:all, :conditions => ["design_id IN (?) AND documentation_issue = ?", production_design_ids, true])
      prod_clr_firs = FabIssue.find(:all, :conditions => ["design_id IN (?) AND documentation_issue = ?", production_design_ids, false])      
      fir_quart["Documentation Issues/Pins"] = (prod_doc_firs.count/pincount).round(5) rescue 0
      fir_quart["Clarification Issues/Pins"] = (prod_clr_firs.count/pincount).round(5) rescue 0
      ldxs << offset
      ldys << fir_quart["Documentation Issues/Pins"]
      lcxs << offset
      lcys << fir_quart["Clarification Issues/Pins"]
      
      @fir_quarterly_history << fir_quart
      
      # If this is the last quarter to process the calculate values for single quarter graphs
      if endQuarter == offset
        @fab_quarterly_status = FabQuarterlyStatus.find_by_quarter_and_year(quarter, quart_date.beginning_of_quarter.strftime("%Y"))

        # Build data for Quarterly History Table 1
        prod_des_id_wo_doc_changes = production_design_ids - prod_doc_firs.map(&:design_id).uniq
        prod_des_id_wo_doc_changes.each do |p|
          part_num = PartNum.get_design_pcb_part_number(p).name_string
          
          designer = Design.find(p).designer.last_name
          designer = DesignReview.find_by_design_id_and_review_type_id(p, 1).designer.last_name
          
          project = Design.find(p).board.project.name
          sched_part = PcbSchedulerPartNum.find_by_number_and_pcba(part_num+"A", false)
          sched_brd = PcbSchedulerBoard.find(sched_part.board_id)  rescue "Error"
          pins = sched_brd.actual_ending_pin_count rescue "Error"
          @prod_des_wo_doc_changes << {:part_number => part_num, 
                                        :designer => designer,
                                        :project => project, 
                                        :pins => pins}
        end
        
        # Build data for Quarterly History Table 2
        des_id_wo_doc_changes = designs - production_design_ids
        des_id_wo_doc_changes.each do |p|
          part_num = PartNum.get_design_pcb_part_number(p).name_string
          
          designer = Design.find(p).designer.last_name
          designer = DesignReview.find_by_design_id_and_review_type_id(p, 1).designer.last_name
          
          project = Design.find(p).board.project.name
          sched_part = PcbSchedulerPartNum.find_by_number_and_pcba(part_num+"A", false)
          sched_brd = PcbSchedulerBoard.find(sched_part.board_id)  rescue "Error"
          @des_wo_doc_changes << {:part_number => part_num, 
                                  :designer => designer,
                                  :project => project}
        end
        
        
        @doc_firs.each do |f|          
          # Add to Mode count          
          @fab_iss_mode.find {|fim| fim["Mode"] == f.fab_failure_mode.name }["Documentation Issue"] += 1 unless f.fab_failure_mode.nil?
              
          # Add to Deliverable/Drawing count     
          if f.fab_deliverable.parent_id.nil?
            @fab_iss_deliverable.find {|fid| fid["Deliverable"] == f.fab_deliverable.name }["Documentation Issue"] += 1
          else
            # Get find the root deliverable cycling through parents. Add issue to the root count
            deliverable_root = FabDeliverable.find(f.fab_deliverable.parent_id)
            while !deliverable_root.parent_id.nil?
              deliverable_root = FabDeliverable.find(deliverable_root.parent_id)
            end
            @fab_iss_deliverable.find {|fid| fid["Deliverable"] == deliverable_root.name }["Documentation Issue"] += 1
            @fab_iss_drawing.find {|fid| fid["Drawing"] == f.fab_deliverable.name }["Documentation Issue"] += 1
          end
        end
        @clr_firs.each do |f|
          # Add to Deliverable/Drawing count     
          if f.fab_deliverable.parent_id.nil?
            @fab_iss_deliverable.find {|fid| fid["Deliverable"] == f.fab_deliverable.name }["Vendor Clarification"] += 1
          else
            deliverable_root = FabDeliverable.find(f.fab_deliverable.parent_id)
            while !deliverable_root.parent_id.nil?
              deliverable_root = FabDeliverable.find(deliverable_root.parent_id)
            end
            @fab_iss_deliverable.find {|fid| fid["Deliverable"] == deliverable_root.name }["Vendor Clarification"] += 1
            @fab_iss_drawing.find {|fid| fid["Drawing"] == f.fab_deliverable.name }["Vendor Clarification"] += 1
          end
        end
        
        # Build array of data for "Board Data" Table
        @ftps = []
        pintotal = 0.0000001
        doctotal = 0
        clartotal = 0
        ftps.each do |ftp|
          design = {}
          design[:doc_iss_pins] = "N/A"
          design[:clar_iss_pins] = "N/A"
           
          design[:part_num] = PartNum.get_design_pcb_part_number(ftp.design_id).name_string
          design[:ftp_date] = ftp.created_at.format_dd_mon_yy
          
          #issues = FabIssue.find_all_by_design_id(ftp.design_id).order("resolved_on DESC")
          issues = FabIssue.find(:all, :conditions => ["design_id = ?", ftp.design_id], :order => "resolved_on")
          isscount = issues.count
          if isscount > 0            
            design[:vend_iss_rcvd] = "Yes"
            design[:date_vend_iss_rcvd] = issues.first.received_on.strftime("%d-%b-%y")
            design[:date_vend_iss_closed] = issues.first.resolved_on.nil? ? "" : issues.last.resolved_on.strftime("%d-%b-%y")
          else
            design[:vend_iss_rcvd] = "No"
            design[:date_vend_iss_rcvd] = "N/A"
            design[:date_vend_iss_closed] = "N/A"            
          end

          #dociss = FabIssue.find_all_by_design_id_and_documentation_issue(ftp.design_id, true)
          dociss = FabIssue.find(:all, :conditions => ["design_id = ? AND documentation_issue = ? ", ftp.design_id, true], :order => "clean_up_complete_on")
          docisscount = dociss.count
          design[:num_doc_issues] = docisscount
          if docisscount > 0
            design[:cleanup_reqd] = "Yes"
            design[:date_cleanup_comp] = dociss.first.clean_up_complete_on.nil? ? "" : dociss.last.clean_up_complete_on.strftime("%d-%b-%y")
          else
            design[:cleanup_reqd] = "No"
            design[:date_cleanup_comp] = "N/A"
          end
          
          clarisscount = FabIssue.find_all_by_design_id_and_documentation_issue(ftp.design_id, false).count
          design[:num_clar_issues] = clarisscount
          
          sched_part = PcbSchedulerPartNum.find_by_number_and_pcba(design[:part_num]+"A", false)
          sched_brd = PcbSchedulerBoard.find(sched_part.board_id)  rescue "Error"
          sched_brd_class = PcbSchedulerBoardClass.find(sched_brd.board_class_id) rescue "Error"
          sched_brd_des_proc = PcbSchedulerDesignProcess.find(sched_brd.design_process_id) rescue "Error"

          if sched_brd_class != "Error" && (sched_brd_class.name == "P1" || sched_brd_class.name == "P2")
            design[:pins] = "N/A"
            design[:brd_type] = "Engineering"
          elsif sched_brd_des_proc != "Error" && sched_brd_des_proc.short_name == "BF"
            design[:pins] = "N/A"
            design[:brd_type] = "Bareboard Only"
          elsif sched_brd_des_proc != "Error" && sched_brd_des_proc.short_name == "RF"
            design[:pins] = "N/A"
            design[:brd_type] = "Revision"
          elsif sched_brd != "Error"
            design[:pins] = sched_brd.actual_ending_pin_count rescue "Error"
            design[:brd_type] = "Production (New)"
            design[:doc_iss_pins] = (docisscount*100.000/design[:pins]).round(3).to_s + "%"
            design[:clar_iss_pins] = (clarisscount*100.000/design[:pins]).round(3).to_s + "%"
            pintotal += design[:pins]
            doctotal += design[:num_doc_issues]
            clartotal += design[:num_clar_issues]
          else
            design[:pins] = "Error"
            design[:brd_type] = "Error"
            design[:doc_iss_pins] = "Error"
            design[:clar_iss_pins] = "Error"           
          end
          @ftps << design
        end
        @design_sum = {}
        @design_sum[:total] = "Total"
        @design_sum[:pintotal] = pintotal.round(0)
        @design_sum[:doctotal] = doctotal
        @design_sum[:doc_iss_pins_total] = (doctotal*100/pintotal).round(5).to_s + "%"
        @design_sum[:clartotal] = clartotal
        @design_sum[:clar_iss_pins_total] = (clartotal*100/pintotal).round(5).to_s + "%"
      end
      
    end
    
    # Calculate linear regression values and update quarterly_history hash
    d_linear_model = SimpleLinearRegression.new(ldxs.reverse, ldys)
    d_slope = d_linear_model.slope
    d_y_intercept = d_linear_model.y_intercept
    c_linear_model = SimpleLinearRegression.new(lcxs.reverse, lcys)
    c_slope = c_linear_model.slope
    c_y_intercept = c_linear_model.y_intercept     
    count = 0
    numQuarters.step(endQuarter,-1).each do |offset|
      count += 1
      # Get Quarter/Year string for graph and page title
      quart_date = Date.today << (offset * 3)
      quarter = ((quart_date.beginning_of_quarter.month - 1) / 3) + 1
      fir_quart_date = quarter.to_s + "Q" + quart_date.beginning_of_quarter.strftime("%y") 

      d_quart_val = d_y_intercept + d_slope * count
      @fir_quarterly_history.find{|fqh| fqh["Date"] == fir_quart_date}["Linear (Documentation Issues/Pins)"] = d_quart_val.round(7) rescue 0
      c_quart_val = c_y_intercept + c_slope * count
      @fir_quarterly_history.find{|fqh| fqh["Date"] == fir_quart_date}["Linear (Clarification Issues/Pins)"] = c_quart_val.round(7) rescue 0
    end

    @fir_quarterly_history = @fir_quarterly_history.to_json
    @fir_pins_brds = @fir_pins_brds.to_json
    @fab_iss_deliverable = @fab_iss_deliverable.to_json
    @fab_iss_drawing = @fab_iss_drawing.to_json
    @fab_iss_mode = @fab_iss_mode.to_json
    
    respond_to do | format | 
      format.html
      format.csv { send_data reviewer_to_csv(@heads,@data) }
    end  
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

  def reviewer_to_csv(heads, data)
    CSV.generate() do |csv|
      csv << heads
      data.each do |row|
        csv << row
      end
    end
  end
  
  def time_to_csv(heads, types, data)
    CSV.generate() do |csv|
      line = Array.new
      line.concat(heads)
      types.each do | type |
        line << type 
        line << "Days"
      end
      csv << line

      data.each do | board,brd_data |
        description = "Unknown"
        brd_data.each do | reviewer, revr_data | 
          if reviewer == "Description" 
            description = revr_data
            next
          end         
          line = []
          line << board
          line << description
          line << reviewer
          types.each do | type |
            role = revr_data["#{type}_role"]
            if role.blank?
              line << "" #role
              line << "" #time
            else
              time = revr_data["#{type}_time"] || ""
              line << role
              line << time
            end
          end #each type
          csv << line
        end  #each brd_data
      end #each data
    end
  end

  def business_days_between(date1,date2)
    business_days = 0
    date = date2
    while date > date1
      business_days = business_days + 1 unless date.saturday? or date.sunday?
      date = date - 1.day
    end
    business_days
  end

end
