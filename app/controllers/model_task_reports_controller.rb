class ModelTaskReportsController < ApplicationController


  # GET /model_tasks
  def index
    
    @start_date     = Time.now.beginning_of_month
    @end_date       = Date.today
    @model_tasks    = ModelTask.find_closed(@start_date, @end_date)
    @task_summary   = ModelTask.model_task_summary(@start_date, @end_date)

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
      order = 'created_at'
    end

    @model_tasks = ModelTask.find_closed(@start_date, @end_date, order)
    @task_summary = ModelTask.model_task_summary(@start_date, @end_date)
    
    render(:layout=>false)
    #render( :action => 'index')
    
  end
  
end
