class FabDeliverablesController < ApplicationController
  # GET /fab_deliverables
  # GET /fab_deliverables.json
  def index
    @fab_deliverables = FabDeliverable.order('name').all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @fab_deliverables }
    end
  end

  # GET /fab_deliverables/1
  # GET /fab_deliverables/1.json
  def show
    @fab_deliverable = FabDeliverable.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @fab_deliverable }
    end
  end

  # GET /fab_deliverables/new
  # GET /fab_deliverables/new.json
  def new
    @fab_deliverable = FabDeliverable.new
    @fab_deliverables = FabDeliverable.order('name').all

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @fab_deliverable }
    end
  end

  # GET /fab_deliverables/1/edit
  def edit
    @fab_deliverable = FabDeliverable.find(params[:id])
    @fab_deliverables = FabDeliverable.order('name').find(:all, :conditions => ["id != ?", @fab_deliverable.id])
  end

  # POST /fab_deliverables
  # POST /fab_deliverables.json
  def create
    @fab_deliverable = FabDeliverable.new(params[:fab_deliverable])

    respond_to do |format|
      if @fab_deliverable.save
        flash['notice'] = 'Fab Deliverable was successfully created.'
        format.html { redirect_to action: "index" }
        format.json { render json: @fab_deliverable, status: :created, location: @fab_deliverable }
      else
        flash['notice'] = @fab_deliverable.errors.full_messages.pop
        format.html { render action: "new" }
        format.json { render json: @fab_deliverable.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /fab_deliverables/1
  # PUT /fab_deliverables/1.json
  def update
    @fab_deliverable = FabDeliverable.find(params[:fab_deliverable][:id])

    respond_to do |format|
      if @fab_deliverable.update_attributes(params[:fab_deliverable])
        flash['notice'] = 'Fab Deliverable was successfully updated.'
        format.html { redirect_to action: "index"  }
        format.json { head :no_content }
      else
        flash['notice'] = @fab_deliverable.errors.full_messages.pop
        format.html { render action: "edit" }
        format.json { render json: @fab_deliverable.errors, status: :unprocessable_entity }
      end
    end
  end           
                
  # DELETE /fab_deliverables/1
  # DELETE /fab_deliverables/1.json
  def destroy
    @fab_deliverable = FabDeliverable.find(params[:id])
    @fab_deliverable.destroy

    respond_to do |format|
      format.html { redirect_to fab_deliverables_url }
      format.json { head :no_content }
    end
  end
end
