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

class EcoTasksController < ApplicationController


  before_filter(:verify_logged_in, :except => [:get_attachment,
                                               :index,
                                               :show])
 

  # GET /eco_tasks
  def index
    @eco_tasks = EcoTask.find_open
    set_stored()
  end
  
  def report
    @eco_tasks = EcoTask.find_closed
  end

  # GET /eco_tasks/1
  def show
    #@eco_task = EcoTask.find(params[:id])
    redirect_to :action => :edit

  end

  # GET /eco_tasks/new
  def new
    @eco_task     = EcoTask.new
    @eco_document = EcoDocument.new
    @eco_comment  = EcoComment.new
    @eco_types    = EcoType.find_active
    #variables for display of CC list with shared/_display_mail_lists
    @reviewers        = [];
    @users_copied     = [];
    @users_not_copied = @eco_task.users_eligible_for_cc_list
  end

  # GET /eco_tasks/1/edit
  def edit
    @eco_task = EcoTask.find(params[:id])
        #variables for display of CC list with shared/_display_mail_lists
    @reviewers        = []
    @users_copied     = @eco_task.users.uniq
    @users_not_copied = @eco_task.users_eligible_for_cc_list

  end

  # POST /eco_tasks
  def create

    @eco_task     = EcoTask.new(params[:eco_task])
 
    if params[:eco_document] != ''
      @eco_document = EcoDocument.new(params[:eco_document])
    end
    
    @eco_comment = EcoComment.new(params[:eco_comment])

    if @eco_task.save
      flash['notice'] = 'ECO CAD Task was successfully created.'
      
      @eco_task.add_users_to_cc_list(params[:eco_task_user][:ids]) if params[:eco_task_user]

      @eco_task.add_comment(@eco_comment, @logged_in_user)

      if @eco_document
        eco_document = @eco_task.attach_document(@eco_document, @logged_in_user, true)
          
        if !eco_document.errors.empty?
          if eco_document.errors[:empty_document]
            flash['notice'] += "<br />#{eco_document.errors[:empty_document]}"
          end
          if eco_document.errors[:document_too_large]
            flash['notice'] += "<br />#{eco_document.errors[:document_too_large]}"
          end
        end
      end

    if params[:eco_attachment1] && params[:eco_attachment1][:document] != ''
      @eco_attachment = @eco_task.attach_document(EcoDocument.new(params[:eco_attachment1]),
                                                @logged_in_user)
                                             
      task_updated = true
      if !@eco_attachment.errors.empty?
        if @eco_attachment.errors[:empty_document]
          flash['notice'] += "<br />#{@eco_attachment.errors[:empty_document]}"
        end
        if @eco_attachment.errors[:document_too_large]
          flash['notice'] += "<br />#{@eco_attachment.errors[:document_too_large]}"
        end
      end
    end

   if params[:eco_attachment2] && params[:eco_attachment2][:document] != ''
      @eco_attachment = @eco_task.attach_document(EcoDocument.new(params[:eco_attachment2]),
                                                @logged_in_user)

      task_updated = true
      if !@eco_attachment.errors.empty?
        if @eco_attachment.errors[:empty_document]
          flash['notice'] += "<br />#{@eco_attachment.errors[:empty_document]}"
        end
        if @eco_attachment.errors[:document_too_large]
          flash['notice'] += "<br />#{@eco_attachment.errors[:document_too_large]}"
        end
      end
    end

   if params[:eco_attachment3] && params[:eco_attachment3][:document] != ''
      @eco_attachment = @eco_task.attach_document(EcoDocument.new(params[:eco_attachment3]),
                                                @logged_in_user)

      task_updated = true
      if !@eco_attachment.errors.empty?
        if @eco_attachment.errors[:empty_document]
          flash['notice'] += "<br />#{@eco_attachment.errors[:empty_document]}"
        end
        if @eco_attachment.errors[:document_too_large]
          flash['notice'] += "<br />#{@eco_attachment.errors[:document_too_large]}"
        end
      end
    end
       
      EcoTaskMailer::eco_task_message(@eco_task, 'Task Created').deliver
        
      redirect_to(eco_tasks_url)
    else
      @eco_types   = EcoType.find_active
      render :action => "new"
    end
  end

  # PUT /eco_tasks/1
  # PUT /eco_tasks/1.xml
  def update

    @eco_task       = EcoTask.find(params[:id])
    eco_task_update = EcoTask.new(params[:eco_task])
    
    flash['notice'] = ''

    # Save any comments that were entered.
    comment = @eco_task.add_comment(EcoComment.new(params[:eco_comment]), @logged_in_user)
    task_updated = !comment.comment.blank?
    
    
    # This option will only be available to the ECO Admin
    if @eco_task.specification_attached? && params[:document]
      @eco_task.destroy_specification
    end

    
    if params[:eco_document] && params[:eco_document][:document] != ''
      @eco_document = @eco_task.attach_document(EcoDocument.new(params[:eco_document]),
                                                @logged_in_user,
                                                true)
                                              
      task_updated = true
      if !@eco_document.errors.empty?
        if @eco_document.errors[:empty_document]
          flash['notice'] += "<br />#{@eco_document.errors[:empty_document]}"
        end
        if @eco_document.errors[:document_too_large]
          flash['notice'] += "<br />#{@eco_document.errors[:document_too_large]}"
        end
      end
    end

### Commenting this out 12/5/12. Was unable to upload attachments so replaced this with code from create method above.
=begin    
    if params[:eco_attachment] && params[:eco_attachment][:document] != ''
      @eco_attachment = @eco_task.attach_document(EcoDocument.new(params[:eco_attachment]),
                                                @logged_in_user)
                                              
      task_updated = true
      if !@eco_attachment.errors.empty?
        if @eco_attachment.errors[:empty_document]
          flash['notice'] += "<br />#{@eco_attachment.errors[:empty_document]}"
        end
        if @eco_attachment.errors[:document_too_large]
          flash['notice'] += "<br />#{@eco_attachment.errors[:document_too_large]}"
        end
      end
    end
=end
    
    if params[:eco_attachment1] && params[:eco_attachment1][:document] != ''
      @eco_attachment = @eco_task.attach_document(EcoDocument.new(params[:eco_attachment1]),
                                                @logged_in_user)                                            
      task_updated = true
      if !@eco_attachment.errors.empty?

        if @eco_attachment.errors[:empty_document]

          flash['notice'] += "<br />#{@eco_attachment.errors[:empty_document]}"
        end
        if @eco_attachment.errors[:document_too_large]

          flash['notice'] += "<br />#{@eco_attachment.errors[:document_too_large]}"
        end
      end
    end

   if params[:eco_attachment2] && params[:eco_attachment2][:document] != ''
      @eco_attachment = @eco_task.attach_document(EcoDocument.new(params[:eco_attachment2]),
                                                @logged_in_user)

      task_updated = true
      if !@eco_attachment.errors.empty?
        if @eco_attachment.errors[:empty_document]
          flash['notice'] += "<br />#{@eco_attachment.errors[:empty_document]}"
        end
        if @eco_attachment.errors[:document_too_large]
          flash['notice'] += "<br />#{@eco_attachment.errors[:document_too_large]}"
        end
      end
    end

   if params[:eco_attachment3] && params[:eco_attachment3][:document] != ''
      @eco_attachment = @eco_task.attach_document(EcoDocument.new(params[:eco_attachment3]),
                                                @logged_in_user)

      task_updated = true
      if !@eco_attachment.errors.empty?
        if @eco_attachment.errors[:empty_document]
          flash['notice'] += "<br />#{@eco_attachment.errors[:empty_document]}"
        end
        if @eco_attachment.errors[:document_too_large]
          flash['notice'] += "<br />#{@eco_attachment.errors[:document_too_large]}"
        end
      end
    end
    
    # If the user deselects all of the ECO Types on the form then the 
    # eco_type_ids field from the form will be nil when submitted.  In that
    # case, load an empty array so that downstream validation works
    eco_admin = @logged_in_user.is_a_role_member?('ECO Admin')
    if eco_admin 
      if !params[:eco_task][:eco_type_ids]
        params[:eco_task][:eco_type_ids] = []
      end
      # Check for changes while in this branch
      task_updated |= @eco_task.check_for_admin_update(eco_task_update)
      
    else
      task_updated |= @eco_task.check_for_processor_update(eco_task_update)      
    end

    eco_task_update_privs = (eco_admin || @logged_in_user.is_an_lcr_designer?)

    if task_updated
      
      @eco_task.set_user(@logged_in_user)
      
      if !eco_task_update_privs
        flash['notice'] = "ECO #{@eco_task.number} was successfully updated."
        redirect_to(eco_tasks_url)
      elsif (eco_task_update_privs && 
             @eco_task.update_attributes(params[:eco_task]))
        flash['notice'] = "ECO #{@eco_task.number} was successfully updated."
        
        redirect_to(eco_tasks_url)
      else
        render :action => "edit"
      end
      
      if !eco_task_update.closed?
        EcoTaskMailer::eco_task_message(@eco_task,
                              "[#{@eco_task.state}] - Task Updated").deliver
      else
        EcoTaskMailer::eco_task_closed_notification(@eco_task).deliver
      end
      
    else 
      flash['notice'] = "All fields were empty - no updates were entered for " +
                        "ECO  #{@eco_task.number}"
      redirect_to(eco_tasks_url)
    end
  end

  
  # DELETE /eco_tasks/1
  # DELETE /eco_tasks/1.xml
  def destroy
    @eco_task = EcoTask.find(params[:id])
    @eco_task.destroy

    respond_to do |format|
      format.html { redirect_to(eco_tasks_url) }
      format.xml  { head :ok }
    end
  end
  
  
  def edit_eco_task_email_list
    @eco_task = EcoTask.find(params[:id])
    @users_eligible_for_cc_list = @eco_task.users_eligible_for_cc_list
  end
  
  ######################################################################
  #
  # change_cc_list
  #
  # Description:
  # This method updates the CC list with the user that was selected
  #
  # Parameters from params
  # [:user_id] - Identifies the user to be added to the CC list.
  # [:eco_task_id]
  # [;mode]    - add or remove
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def change_cc_list
    eco_task = EcoTask.find(params[:eco_task_id])
    mode             = params[:mode]
    user             = User.find(params[:user_id])

    # update the data base
    if ( mode == "add_name")
      eco_task.users << user
      flash[:ack]     = "Added #{user[:name]} to the CC list"
    end

    if ( mode == "remove_name")
      eco_task.users.delete(user)
      flash[:ack]     = "Removed #{user[:name]} from the CC list"
    end

    @reviewers        = []
    @users_copied     = eco_task.users.uniq.sort_by { |et| et.last_name}
    @users_not_copied = eco_task.users_eligible_for_cc_list

    render( :partial => "shared/display_mail_lists",
      :locals  => { :eco_task_id  => eco_task.id,
                    :url => url_for(:action => "change_cc_list",
                                    :controller => "eco_tasks"  )
      })

  end
  ######################################################################
  #
  # add_to_cc_list
  #
  # Description:
  # This method updates the CC list with the user that was selected to be
  # added.
  #
  # Parameters from params
  # [:id] - Identifies the user to be added to the CC list.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def add_to_cc_list

    @eco_task = EcoTask.find(params[:eco_task_id])

    # Add the user to the email cc list.
    user = User.find(params[:id])
    if !@eco_task.users.include?(user)
      @eco_task.users << user
      @eco_task.save
    end
    @users_eligible_for_cc_list = @eco_task.users_eligible_for_cc_list
    
    render(:layout=>false)

  end


  ######################################################################
  #
  # remove_from_cc_list
  #
  # Description:
  # This method updates the CC list with the user that was selected to be
  # removed.
  #
  # Parameters from params
  # [:id] - Identifies the user to be added to the CC list.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def remove_from_cc_list

    @eco_task = EcoTask.find(params[:eco_task_id])

    # Add the user to the email cc list.
    @eco_task.users.delete(User.find(params[:id]))
    @eco_task.reload
    @users_eligible_for_cc_list = @eco_task.users_eligible_for_cc_list
    
    render(:layout=>false)

  end
  
  
  def list_copied_users
    @eco_task = EcoTask.find(params[:id])
    @users    = @eco_task.users.sort_by {|u| u.last_name }
    render(:layout => false)
  end


  ######################################################################
  #
  # get_attachment
  #
  # Description:
  # This method retrieves the attachment selected by the user.
  #
  # Parameters from params
  # [:design_review_id] - Used to identify the design review.
  # [:document_type][:id] - Identifies the type of document.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def get_attachment
    @document = EcoDocument.find(params[:id])
    send_data(@document.data,
              :filename    => @document.name,
              :type        => @document.content_type,
              :disposition => "inline")
  end

end
