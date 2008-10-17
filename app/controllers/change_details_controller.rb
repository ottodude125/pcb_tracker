########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: change_details_controller.rb
#
# This contains the logic to create and modify change details.
#
# $Id$
#
########################################################################

class ChangeDetailsController < ApplicationController
  
  before_filter :verify_admin_role
  before_filter :load_change_items
  
  
  # GET /change_details
  # GET /change_details.xml
  def index
    @change_details = @change_item.change_details.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @change_details }
    end
  end

  # GET /change_details/1
  # GET /change_details/1.xml
  #def show
  #  @change_detail = ChangeDetail.find(params[:id])
  #
  #  respond_to do |format|
  #    format.html # show.html.erb
  #    format.xml  { render :xml => @change_detail }
  #  end
  #end

  # GET /change_details/new
  # GET /change_details/new.xml
  def new
    @change_details = @change_item.change_details.find(:all)
    @positions      = @change_details.size + 1
    @change_detail = ChangeDetail.new( :change_item_id => @change_item.id,
                                       :position       => @positions,
                                       :active         => true )

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @change_detail }
    end
  end

  # GET /change_details/1/edit
  def edit
    @change_detail  = ChangeDetail.find(params[:id])
    @change_details = @change_item.change_details.find(:all)
    @positions      = @change_details.size
  end

  # POST /change_details
  # POST /change_details.xml
  def create
    @change_detail = ChangeDetail.new(params[:change_detail])
    @change_detail.change_item_id = @change_item.id

    respond_to do |format|
      if @change_detail.add_to_list
        flash['notice'] = "Change detail '#{@change_detail.name}' was successfully created."
        format.html { redirect_to(change_item_change_details_path(@change_item)) }
        format.xml  { render :xml => @change_detail, :status => :created, :location => @change_detail }
      else
        @change_details = @change_item.change_details.find(:all)
        @positions      = @change_details.size + 1
        format.html { render :action => "new" }
        format.xml  { render :xml => @change_detail.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /change_details/1
  # PUT /change_details/1.xml
  def update
    @change_detail = ChangeDetail.find(params[:id])
    
    respond_to do |format|
      if @change_detail.update_list(params[:change_detail])
        flash['notice'] = "Change detail '#{@change_detail.name}' was successfully updated."
        format.html { redirect_to(change_item_change_details_path(@change_item)) }
        format.xml  { head :ok }
      else
        @change_details = @change_item.change_details.find(:all)
        @positions      = @change_details.size
        format.html { render :action => "edit" }
        format.xml  { render :xml => @change_detail.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /change_details/1
  # DELETE /change_details/1.xml
  #def destroy
  #  @change_detail = ChangeDetail.find(params[:id])
  #  @change_detail.destroy
  #
  #  respond_to do |format|
  #    format.html { redirect_to(change_details_url) }
  #    format.xml  { head :ok }
  #  end
  #end
  
private

def load_change_items
  @change_item = ChangeItem.find(params[:change_item_id])
end

  
end
