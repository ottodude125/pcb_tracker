class ModelDocumentsController < ApplicationController
  # GET /model_documents
  # GET /model_documents.json
  def index
    @model_documents = ModelDocument.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @model_documents }
    end
  end

  # GET /model_documents/1
  # GET /model_documents/1.json
  def show
    @model_document = ModelDocument.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @model_document }
    end
  end

  # GET /model_documents/new
  # GET /model_documents/new.json
  def new
    @model_document = ModelDocument.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @model_document }
    end
  end

  # GET /model_documents/1/edit
  def edit
    @model_document = ModelDocument.find(params[:id])
  end

  # POST /model_documents
  # POST /model_documents.json
  def create
    @model_document = ModelDocument.new(params[:model_document])

    respond_to do |format|
      if @model_document.save
        format.html { redirect_to @model_document, notice: 'Model document was successfully created.' }
        format.json { render json: @model_document, status: :created, location: @model_document }
      else
        format.html { render action: "new" }
        format.json { render json: @model_document.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /model_documents/1
  # PUT /model_documents/1.json
  def update
    @model_document = ModelDocument.find(params[:id])

    respond_to do |format|
      if @model_document.update_attributes(params[:model_document])
        format.html { redirect_to @model_document, notice: 'Model document was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @model_document.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /model_documents/1
  # DELETE /model_documents/1.json
  def destroy
    model_document = ModelDocument.find(params[:id])
    doc_name = model_document.name
    model_task = model_document.model_task
    
    spec = model_document.specification ? "Specification" : ""
    comment = "Model #{spec} document #{doc_name} deleted." 
    mod_comment = ModelComment.new({:model_task_id => model_task.id, :user_id => @logged_in_user.id, :comment => comment })
    mod_comment.save
    
    model_document.destroy
    
    redirect_to edit_model_task_path(model_task), notice: "Model #{spec} document #{doc_name} was successfully deleted."
  end
  #def destroy
  #  @model_document = ModelDocument.find(params[:id])
  #  @model_document.destroy

  #  respond_to do |format|
  #    format.html { redirect_to model_documents_url }
  #    format.json { head :no_content }
  #  end
  #end
end
