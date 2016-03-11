class ModelTypesController < ApplicationController
  # GET /model_types
  # GET /model_types.json
  def index
    @model_types = ModelType.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @model_types }
    end
  end

  # GET /model_types/1
  # GET /model_types/1.json
  def show
    @model_type = ModelType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @model_type }
    end
  end

  # GET /model_types/new
  # GET /model_types/new.json
  def new
    @model_type = ModelType.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @model_type }
    end
  end

  # GET /model_types/1/edit
  def edit
    @model_type = ModelType.find(params[:id])
  end

  # POST /model_types
  # POST /model_types.json
  def create
    @model_type = ModelType.new(params[:model_type])

    respond_to do |format|
      if @model_type.save
        format.html { redirect_to @model_type, notice: 'Model type was successfully created.' }
        format.json { render json: @model_type, status: :created, location: @model_type }
      else
        format.html { render action: "new" }
        format.json { render json: @model_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /model_types/1
  # PUT /model_types/1.json
  def update
    @model_type = ModelType.find(params[:id])

    respond_to do |format|
      if @model_type.update_attributes(params[:model_type])
        format.html { redirect_to @model_type, notice: 'Model type was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @model_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /model_types/1
  # DELETE /model_types/1.json
  def destroy
    @model_type = ModelType.find(params[:id])
    @model_type.destroy

    respond_to do |format|
      format.html { redirect_to model_types_url }
      format.json { head :no_content }
    end
  end
end
