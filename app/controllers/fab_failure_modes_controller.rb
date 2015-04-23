class FabFailureModesController < ApplicationController
  # GET /fab_failure_modes
  # GET /fab_failure_modes.json
  def index
    @fab_failure_modes = FabFailureMode.order('name').all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @fab_failure_modes }
    end
  end

  # GET /fab_failure_modes/1
  # GET /fab_failure_modes/1.json
  def show
    @fab_failure_mode = FabFailureMode.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @fab_failure_mode }
    end
  end

  # GET /fab_failure_modes/new
  # GET /fab_failure_modes/new.json
  def new
    @fab_failure_mode = FabFailureMode.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @fab_failure_mode }
    end
  end

  # GET /fab_failure_modes/1/edit
  def edit
    @fab_failure_mode = FabFailureMode.find(params[:id])
  end

  # POST /fab_failure_modes
  # POST /fab_failure_modes.json
  def create
    @fab_failure_mode = FabFailureMode.new(params[:fab_failure_mode])

    respond_to do |format|
      if @fab_failure_mode.save
        flash['notice'] = 'Fab Failure Mode was successfully created.'
        format.html { redirect_to action: "index" }
        format.json { render json: @fab_failure_mode, status: :created, location: @fab_failure_mode }
      else
        flash['notice'] = @fab_failure_mode.errors.full_messages.pop
        format.html { render action: "new" }
        format.json { render json: @fab_failure_mode.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /fab_failure_modes/1
  # PUT /fab_failure_modes/1.json
  def update
    @fab_failure_mode = FabFailureMode.find(params[:fab_failure_mode][:id])

    respond_to do |format|
      if @fab_failure_mode.update_attributes(params[:fab_failure_mode])
        flash['notice'] = 'Fab Failure Mode was successfully updated.'
        format.html { redirect_to action: "index" }
        format.json { head :no_content }
      else
        flash['notice'] = @fab_failure_mode.errors.full_messages.pop
        format.html { render action: "edit" }
        format.json { render json: @fab_failure_mode.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fab_failure_modes/1
  # DELETE /fab_failure_modes/1.json
  def destroy
    @fab_failure_mode = FabFailureMode.find(params[:id])
    @fab_failure_mode.destroy

    respond_to do |format|
      format.html { redirect_to fab_failure_modes_url }
      format.json { head :no_content }
    end
  end
end
