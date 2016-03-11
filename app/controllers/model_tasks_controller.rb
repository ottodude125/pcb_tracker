class ModelTasksController < ApplicationController

  before_filter(:verify_logged_in, :except => [:get_attachment,
                                               :index,
                                               :show])

  # GET /model_tasks
  # GET /model_tasks.json
  def index
    @model_tasks = ModelTask.find_open
    set_stored()
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @model_tasks }
    end
  end

  # GET /model_tasks/1
  # GET /model_tasks/1.json
  def show
    @model_task = ModelTask.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @model_task }
    end
  end

  # GET /model_tasks/new
  # GET /model_tasks/new.json
  def new
    @model_task = ModelTask.new
    @model_types = ModelType.find_active
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @model_task }
    end
  end

  # GET /model_tasks/1/edit
  def edit
    @model_task = ModelTask.find(params[:id])
    @model_types = ModelType.find_active
  end

  # POST /model_tasks
  # POST /model_tasks.json
  def create
    mod_comment_update = "\n"
    
    params[:model_task][:user_id] = @logged_in_user.id unless !params[:model_task][:user_id].empty?
    @model_task = ModelTask.new(params[:model_task])
        
    respond_to do |format|
      if @model_task.save
        mod_comment_update += "Model Task Created.\n"
        
        flash['notice'] = 'Model Task was successfully created.'
          
        attach_count = 0
        if params[:model_attachment1] && params[:model_attachment1][:document] != ''
          @model_attachment = @model_task.attach_document(ModelDocument.new(params[:model_attachment1]),
                                                    @logged_in_user)
                                                 
          task_updated = true
          if !@model_attachment.errors.empty?
            if @model_attachment.errors[:empty_document]
              flash['notice'] += "<br />#{@model_attachment.errors[:empty_document]}"
            end
            if @model_attachment.errors[:document_too_large]
              flash['notice'] += "<br />#{@model_attachment.errors[:document_too_large]}"
            end
          else
            attach_count += 1
          end
        end
  
        if params[:model_attachment2] && params[:model_attachment2][:document] != ''
          @model_attachment = @model_task.attach_document(ModelDocument.new(params[:model_attachment2]),
                                                    @logged_in_user)
                                                 
          task_updated = true
          if !@model_attachment.errors.empty?
            if @model_attachment.errors[:empty_document]
              flash['notice'] += "<br />#{@model_attachment.errors[:empty_document]}"
            end
            if @model_attachment.errors[:document_too_large]
              flash['notice'] += "<br />#{@model_attachment.errors[:document_too_large]}"
            end
          else
            attach_count += 1
          end
        end
  
        if params[:model_attachment3] && params[:model_attachment3][:document] != ''
          @model_attachment = @model_task.attach_document(ModelDocument.new(params[:model_attachment3]),
                                                    @logged_in_user)
                                                 
          task_updated = true
          if !@model_attachment.errors.empty?
            if @model_attachment.errors[:empty_document]
              flash['notice'] += "<br />#{@model_attachment.errors[:empty_document]}"
            end
            if @model_attachment.errors[:document_too_large]
              flash['notice'] += "<br />#{@model_attachment.errors[:document_too_large]}"
            end
          else
            attach_count += 1
          end
        end

        if params[:model_attachment4] && params[:model_attachment4][:document] != ''
          @model_attachment = @model_task.attach_document(ModelDocument.new(params[:model_attachment4]),
                                                    @logged_in_user)
                                                 
          task_updated = true
          if !@model_attachment.errors.empty?
            if @model_attachment.errors[:empty_document]
              flash['notice'] += "<br />#{@model_attachment.errors[:empty_document]}"
            end
            if @model_attachment.errors[:document_too_large]
              flash['notice'] += "<br />#{@model_attachment.errors[:document_too_large]}"
            end
          else
            attach_count += 1
          end
        end

        if params[:model_attachment5] && params[:model_attachment5][:document] != ''
          @model_attachment = @model_task.attach_document(ModelDocument.new(params[:model_attachment5]),
                                                    @logged_in_user)
                                                 
          task_updated = true
          if !@model_attachment.errors.empty?
            if @model_attachment.errors[:empty_document]
              flash['notice'] += "<br />#{@model_attachment.errors[:empty_document]}"
            end
            if @model_attachment.errors[:document_too_large]
              flash['notice'] += "<br />#{@model_attachment.errors[:document_too_large]}"
            end
          else
            attach_count += 1
          end
        end
        
        mod_comment_update += "There were #{attach_count} new attachments added.\n" unless attach_count == 0
        params[:model_comment][:comment] += mod_comment_update
        @model_comment = ModelComment.new(params[:model_comment])
        @model_task.add_comment(@model_comment, @logged_in_user)
        
        #ModelTaskMailer::model_task_message(@model_task, 'Task Created').deliver
        # Send email notification of new task. Include managers (triggered by third param)
        ModelTaskMailer::model_task_message(@model_task,
                            "[New Model Task #{@model_task.request_number} Created", true).deliver
          
        redirect_to(model_tasks_url)
        #format.html { redirect_to model_task_url, notice: 'Model task was successfully created.' }
        format.json { render json: @model_task, status: :created, location: @model_task }
      else
        @model_types   = ModelType.find_active
        format.html { render action: "new" }
        format.json { render json: @model_task.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /model_tasks/1
  # PUT /model_tasks/1.json
  def update
    mod_comment_update = ""
    
    @model_task = ModelTask.find(params[:id])
    params[:model_task][:user_id] = @logged_in_user.id unless !params[:model_task][:user_id].empty?
    model_task_update = ModelTask.new(params[:model_task])
    
    flash['notice'] = ''

    task_updated = false #!params[:model_comment][:comment].blank?
    
    attach_count = 0
    if params[:model_attachment1] && params[:model_attachment1][:document] != ''
      @model_attachment = @model_task.attach_document(ModelDocument.new(params[:model_attachment1]),
                                                @logged_in_user)
                                             
      task_updated = true
      if !@model_attachment.errors.empty?
        if @model_attachment.errors[:empty_document]
          flash['notice'] += "<br />#{@model_attachment.errors[:empty_document]}"
        end
        if @model_attachment.errors[:document_too_large]
          flash['notice'] += "<br />#{@model_attachment.errors[:document_too_large]}"
        end
      else
        attach_count += 1
      end
    end

    if params[:model_attachment2] && params[:model_attachment2][:document] != ''
      @model_attachment = @model_task.attach_document(ModelDocument.new(params[:model_attachment2]),
                                                @logged_in_user)
                                             
      task_updated = true
      if !@model_attachment.errors.empty?
        if @model_attachment.errors[:empty_document]
          flash['notice'] += "<br />#{@model_attachment.errors[:empty_document]}"
        end
        if @model_attachment.errors[:document_too_large]
          flash['notice'] += "<br />#{@model_attachment.errors[:document_too_large]}"
        end
      else
        attach_count += 1
      end
    end

    if params[:model_attachment3] && params[:model_attachment3][:document] != ''
      @model_attachment = @model_task.attach_document(ModelDocument.new(params[:model_attachment3]),
                                                @logged_in_user)
                                             
      task_updated = true
      if !@model_attachment.errors.empty?
        if @model_attachment.errors[:empty_document]
          flash['notice'] += "<br />#{@model_attachment.errors[:empty_document]}"
        end
        if @model_attachment.errors[:document_too_large]
          flash['notice'] += "<br />#{@model_attachment.errors[:document_too_large]}"
        end
      else
        attach_count += 1
      end
    end
    
    if params[:model_attachment4] && params[:model_attachment4][:document] != ''
      @model_attachment = @model_task.attach_document(ModelDocument.new(params[:model_attachment4]),
                                                @logged_in_user)
                                             
      task_updated = true
      if !@model_attachment.errors.empty?
        if @model_attachment.errors[:empty_document]
          flash['notice'] += "<br />#{@model_attachment.errors[:empty_document]}"
        end
        if @model_attachment.errors[:document_too_large]
          flash['notice'] += "<br />#{@model_attachment.errors[:document_too_large]}"
        end
      else
        attach_count += 1
      end
    end
    
    if params[:model_attachment5] && params[:model_attachment5][:document] != ''
      @model_attachment = @model_task.attach_document(ModelDocument.new(params[:model_attachment5]),
                                                @logged_in_user)
                                             
      task_updated = true
      if !@model_attachment.errors.empty?
        if @model_attachment.errors[:empty_document]
          flash['notice'] += "<br />#{@model_attachment.errors[:empty_document]}"
        end
        if @model_attachment.errors[:document_too_large]
          flash['notice'] += "<br />#{@model_attachment.errors[:document_too_large]}"
        end
      else
        attach_count += 1
      end
    end
    
    mod_comment_update += "#{attach_count} new Model Document attachment(s) added.\n" unless attach_count == 0
    
    model_admin = @logged_in_user.is_a_role_member?('Modeler Admin')
    modeler     = @logged_in_user.is_a_role_member?('Modeler')
    if model_admin 
      # If the user deselects all of the Model Types on the form then the 
      # model_type_ids field from the form will be nil when submitted.  In that
      # case, load an empty array so that downstream validation works
      if !params[:model_task][:model_type_ids]
        params[:model_task][:model_type_ids] = []
      end
      # Check for changes while in this branch
      task_updated |= @model_task.check_for_admin_update(model_task_update)
      mod_comment_update.prepend("\n\nModel Task details updated (admin).\n") unless !@model_task.check_for_admin_update(model_task_update)
    elsif modeler
      task_updated |= @model_task.check_for_processor_update(model_task_update)
      mod_comment_update.prepend("\n\nModel Task details updated.\n") unless !@model_task.check_for_processor_update(model_task_update)      
    end

    model_task_update_privs = (model_admin || modeler || @logged_in_user.is_an_lcr_designer?)

    # Save any comments that were entered.
    params[:model_comment][:comment] += mod_comment_update
    #params[:model_comment][:comment] += "\n\n" + mod_comment_update
    

    if task_updated || !params[:model_comment][:comment].blank?
      
      @model_task.set_user(@logged_in_user)
      
      if !model_task_update_privs
        flash['notice'] = "Model #{@model_task.request_number} was successfully updated."
      elsif (model_task_update_privs && @model_task.update_attributes(params[:model_task]))
        flash['notice'] = "Model #{@model_task.request_number} was successfully updated."
      else
        @model_types = ModelType.find_active
        render :action => "edit" and return
      end

      comment = @model_task.add_comment(ModelComment.new(params[:model_comment]), @logged_in_user) unless params[:model_comment][:comment].blank?
      
      # Send email of updates unless task is closed
      ModelTaskMailer::model_task_message(@model_task,
                            "[#{@model_task.state}] - Task Updated").deliver unless model_task_update.closed?

      redirect_to(model_tasks_url)
    else
      @model_types = ModelType.find_active
      flash['notice'] = "All fields were empty - no updates were entered for " +
                        "Model  #{@model_task.request_number}"
      redirect_to(model_tasks_url)
    end


    #respond_to do |format|
    #  if @model_task.update_attributes(params[:model_task])
    #    format.html { redirect_to @model_task, notice: 'Model task was successfully updated.' }
    #    format.json { head :no_content }
    #  else
    #    format.html { render action: "edit" }
    #    format.json { render json: @model_task.errors, status: :unprocessable_entity }
    #  end
    #end
  end

  # DELETE /model_tasks/1
  # DELETE /model_tasks/1.json
  def destroy
    @model_task = ModelTask.find(params[:id])
    @model_task.model_documents.destroy_all
    @model_task.model_comments.destroy_all
    req_num = @model_task.request_number
    @model_task.destroy

    respond_to do |format|
      format.html { redirect_to model_tasks_url, notice: "Model Task #{req_num} successfully deleted." }
      format.json { head :no_content }
    end
  end

  ######################################################################
  #
  # get_attachment
  #
  # Description:
  # This method retrieves the attachment selected by the user.
  #
  # Parameters from params
  # [:id] - Identifies the id of document.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def get_attachment
    @document = ModelDocument.find(params[:id])
    send_data(@document.data,
              :filename    => @document.name,
              :type        => @document.content_type,
              :disposition => "inline")
  end

end
