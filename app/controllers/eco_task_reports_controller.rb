########################################################################
#
# Copyright 2005, by Teradyne, Inc., North Reading MA
#
# File: eco_tasks_controller.rb
#
# This contains the logic that handles events from the outside world
# (user input), interacts with the eco task model, and displays the 
# appropriate view to the user.
#
# $Id$
#
########################################################################

class EcoTaskReportsController < ApplicationController

  
  #auto_complete_for :eco_task, :number
  #auto_complete_for :eco_task, :pcba_part_number
  

  # GET /eco_tasks
  def index
    
    @start_date   = Time.now.beginning_of_month
    @end_date     = Date.today
    @eco_tasks    = EcoTask.find_closed(@start_date, @end_date)
    @task_summary = EcoTask.eco_task_summary(@start_date, @end_date)

    set_stored()
  end
  
  
  def reindex
    
    @start_date = Date.new(params[:startdate][:year].to_i, params[:startdate][:month].to_i, 1)
    if params[:enddate][:month] == '12'
      year = params[:enddate][:year].to_i + 1
      @end_date = Date.new(year, 1, 1)
    else
      month = params[:enddate][:month].to_i + 1
      @end_date = Date.new(params[:enddate][:year].to_i, month, 1)    
    end
    
    if params[:sort]
      order  = params[:sort][:field] ? params[:sort][:field] : 'created_at'
      order += ' '
      order += params[:sort][:order] ? params[:sort][:order] : 'ASC'
    else
      order = 'started_at'
    end

    @eco_tasks = EcoTask.find_closed(@start_date, @end_date, order)
    @task_summary = EcoTask.eco_task_summary(@start_date, @end_date)
    
    render(:layout=>false)
    #render( :action => 'index')
    
  end
  
  
  def search_form
    
  end
  
end
