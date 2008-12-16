########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_changes_controller.rb
#
# This contains the logic to create and modify change details.
#
# $Id$
#
########################################################################

class DesignChangesController < ApplicationController
  
  
  before_filter :verify_logged_in,           :except => [:show, :index]
  before_filter :verify_manager_admin_privs, :only   => [:pending_list]
  
  
  # POST /design_changes
  # POST /design_changes.xml
  def create
    @design        = Design.find(params[:design_change][:design_id])
    @design_change = DesignChange.new(params[:design_change])
    @design_change.design_id = @design.id

    respond_to do |format|
      @design_change.designer_id = @logged_in_user.id
      if @design_change.save
        flash['notice'] = "Pending approval, #{@design_change.schedule_impact_statement}"
        format.html { redirect_to(:controller => 'design_changes',
                                  :action     => 'index',
                                  :id         => @design.id) }
        format.xml  { render :xml => @change_detail, :status => :created, :location => @change_detail }
      else
        if @logged_in_user.is_designer?
          @change_classes = ChangeClass.find_all_active_designer_change_classes
        else
          @change_classes = ChangeClass.find_all_active_manager_change_classes
        end
        format.html { render :action => "new" }
        format.xml  { render :xml => @design_change.errors, :status => :unprocessable_entity }
      end
    end
  end


  # GET /change_details/1/edit
  def edit
    @design_change  = DesignChange.find(params[:id])
    @change_classes = ChangeClass.find_all_active_classes_for_user(@logged_in_user)
  end


  # GET /design_changes
  # GET /design_changes.xml
  def index
    
    @design = Design.find(params[:id])
    #@design.design_changes.find(:all, :order => 'approved, created_at ASC')
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @design }
    end
  end

  
  # GET /design_changes/new
  # GET /design_changes/new.xml
  def new
    
    @design         = Design.find(params[:design_id])
    @design_change  = DesignChange.new( :design_id        => @design.id,
                                        :change_class_id  => 0,
                                        :change_type_id   => 0,
                                        :change_item_id   => 0,
                                        :change_detail_id => 0)

    @change_classes = ChangeClass.find_all_active_classes_for_user(@logged_in_user)
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @change_detail }
    end
  end
  
  
  # GET /design_changes/pending_list
  # GET /design_changes/pending_list.xml
  def pending_list
    @design_changes = DesignChange.find_pending
    
    respond_to do |format|
      format.html # pending_list.html.erb
      format.xml  { render :xml => @design_changes }
    end
  end


  # GET /design_changes/1
  # GET /design_changes/1.xml
  def show
    @design_change = DesignChange.find(params[:id])
  
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @change_detail }
    end
  end


  # PUT /change_details/1
  # PUT /change_details/1.xml
  def update
    approving = false
    @design_change = DesignChange.find(params[:id])
    if @design_change.approving_change?(params[:design_change][:approved] == '1')
      @design_change.approve(@logged_in_user)
      approving = true
    end
    
    respond_to do |format|
      if @design_change.update_attributes(params[:design_change])
        if approving
          flash['notice'] = "Approval recorded for the schedule change."
        else
          flash['notice'] = "Schedule change was successfully updated."
        end
        format.html { redirect_to(:controller => 'design_changes',
                                  :action     => 'index',
                                  :id         => @design_change.design.id) }
        format.xml  { head :ok }
      else
        @design = @design_change.design
        if @logged_in_user.is_designer?
          @change_classes = ChangeClass.find_all_active_designer_change_classes
        else
          @change_classes = ChangeClass.find_all_active_manager_change_classes
        end
        format.html { render :action => "new" }
        format.xml  { render :xml => @design_change.errors, :status => :unprocessable_entity }
      end
    end
  end


  # AJAX Action used to populate change selection boxes
  #
  def display_design_change_form
    
    @design_change = DesignChange.new
    
    if params[:change_class_id]
      @design_change.change_class_id  = params[:change_class_id]
    elsif params[:change_type_id] && !params[:change_type_id].blank?
      @design_change.change_type_id   = params[:change_type_id]
      @design_change.change_class_id  = @design_change.change_type.change_class.id
    elsif params[:change_item_id]  && !params[:change_item_id].blank?
      @design_change.change_item_id   = params[:change_item_id]
      @design_change.change_type_id   = @design_change.change_item.change_type.id
      @design_change.change_class_id  = @design_change.change_type.change_class.id
    elsif params[:change_detail_id] && !params[:change_detail_id].blank?
      @design_change.change_detail_id = params[:change_detail_id]
      @design_change.change_item_id   = @design_change.change_detail.change_item.id
      @design_change.change_type_id   = @design_change.change_item.change_type.id
      @design_change.change_class_id  = @design_change.change_type.change_class.id
    end
    
    @change_classes = ChangeClass.find_all_active_classes_for_user(@logged_in_user)

  end
  
  
end
