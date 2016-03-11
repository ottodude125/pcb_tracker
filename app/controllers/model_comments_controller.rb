class ModelCommentsController < ApplicationController
  # GET /model_comments
  # GET /model_comments.json
  def index
    @model_comments = ModelComment.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @model_comments }
    end
  end

  # GET /model_comments/1
  # GET /model_comments/1.json
  def show
    @model_comment = ModelComment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @model_comment }
    end
  end

  # GET /model_comments/new
  # GET /model_comments/new.json
  def new
    @model_comment = ModelComment.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @model_comment }
    end
  end

  # GET /model_comments/1/edit
  def edit
    @model_comment = ModelComment.find(params[:id])
  end

  # POST /model_comments
  # POST /model_comments.json
  def create
    @model_comment = ModelComment.new(params[:model_comment])

    respond_to do |format|
      if @model_comment.save
        format.html { redirect_to @model_comment, notice: 'Model comment was successfully created.' }
        format.json { render json: @model_comment, status: :created, location: @model_comment }
      else
        format.html { render action: "new" }
        format.json { render json: @model_comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /model_comments/1
  # PUT /model_comments/1.json
  def update
    @model_comment = ModelComment.find(params[:id])

    respond_to do |format|
      if @model_comment.update_attributes(params[:model_comment])
        format.html { redirect_to @model_comment, notice: 'Model comment was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @model_comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /model_comments/1
  # DELETE /model_comments/1.json
  def destroy
    @model_comment = ModelComment.find(params[:id])
    @model_comment.destroy

    respond_to do |format|
      format.html { redirect_to model_comments_url }
      format.json { head :no_content }
    end
  end
end
