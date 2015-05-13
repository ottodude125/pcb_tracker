class FabQuarterlyStatusesController < ApplicationController
  # GET /fab_quarterly_statuses
  # GET /fab_quarterly_statuses.json
  def index
    @fab_quarterly_statuses = FabQuarterlyStatus.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @fab_quarterly_statuses }
    end
  end

  # GET /fab_quarterly_statuses/1
  # GET /fab_quarterly_statuses/1.json
  def show
    @fab_quarterly_status = FabQuarterlyStatus.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @fab_quarterly_status }
    end
  end

  # GET /fab_quarterly_statuses/new
  # GET /fab_quarterly_statuses/new.json
  def new
    @fab_quarterly_status = FabQuarterlyStatus.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @fab_quarterly_status }
    end
  end

  # GET /fab_quarterly_statuses/1/edit
  def edit
    @fab_quarterly_status = FabQuarterlyStatus.find(params[:id])
  end

  # POST /fab_quarterly_statuses
  # POST /fab_quarterly_statuses.json
  def create
    already_exists = FabQuarterlyStatus.find_all_by_quarter_and_year(params[:fab_quarterly_status][:quarter], params[:fab_quarterly_status][:year]).count
    @fab_quarterly_status = FabQuarterlyStatus.new(params[:fab_quarterly_status])

    respond_to do |format|
      if already_exists > 0
        flash[:error]='ERROR: Fab quarterly status already exists for selected year and quarter. Please update accordingly.'
        format.html { render action: "new" }
        format.json { render json: @fab_quarterly_status.errors, status: :unprocessable_entity }
      elsif @fab_quarterly_status.save
        format.html { redirect_to fab_quarterly_statuses_url, notice: 'Fab quarterly status was successfully created.' }
        format.json { render json: @fab_quarterly_status, status: :created, location: @fab_quarterly_status }
      else
        format.html { render action: "new" }
        format.json { render json: @fab_quarterly_status.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /fab_quarterly_statuses/1
  # PUT /fab_quarterly_statuses/1.json
  def update
    @fab_quarterly_status = FabQuarterlyStatus.find(params[:id])

    respond_to do |format|
      if @fab_quarterly_status.update_attributes(params[:fab_quarterly_status])
        format.html { redirect_to fab_quarterly_statuses_url, notice: 'Fab quarterly status was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @fab_quarterly_status.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fab_quarterly_statuses/1
  # DELETE /fab_quarterly_statuses/1.json
  def destroy
    @fab_quarterly_status = FabQuarterlyStatus.find(params[:id])
    @fab_quarterly_status.destroy

    respond_to do |format|
      format.html { redirect_to fab_quarterly_statuses_url }
      format.json { head :no_content }
    end
  end
end
