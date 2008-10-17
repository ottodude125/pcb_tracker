########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: change_items_controller.rb
#
# This contains the logic to create and modify change items.
#
# $Id$
#
########################################################################

class ChangeItemsController < ApplicationController
  
  before_filter :verify_admin_role 
  before_filter :load_change_types
  
  
  # GET /change_items
  # GET /change_items.xml
  def index
    @change_items = @change_type.change_items.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @change_items }
    end
  end

  # GET /change_items/1
  # GET /change_items/1.xml
  #def show
  #  @change_item = ChangeItem.find(params[:id])
  #
  #  respond_to do |format|
  #    format.html # show.html.erb
  #    format.xml  { render :xml => @change_item }
  #  end
  #end

  # GET /change_items/new
  # GET /change_items/new.xml
  def new
    @change_items = @change_type.change_items.find(:all)
    @positions    = @change_items.size + 1
    @change_item  = ChangeItem.new( :change_type_id => @change_type.id,
                                    :position       => @positions,
                                    :active         => true )

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @change_item }
    end
  end

  # GET /change_items/1/edit
  def edit
    @change_item  = ChangeItem.find(params[:id])
    @change_items = @change_type.change_items.find(:all)
    @positions    = @change_items.size    
  end

  # POST /change_items
  # POST /change_items.xml
  def create
    @change_item = ChangeItem.new(params[:change_item])
    @change_item.change_type_id = @change_type.id

    respond_to do |format|
      if @change_item.add_to_list
        flash['notice'] = "Change type '#{@change_item.name}' was successfully created."
        format.html { redirect_to(change_type_change_items_path(@change_type)) }
        format.xml  { render :xml => @change_item, :status => :created, :location => @change_item }
      else
        @change_items = @change_type.change_items.find(:all)
        @positions    = @change_items.size + 1
        format.html { render :action => "new" }
        format.xml  { render :xml => @change_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /change_items/1
  # PUT /change_items/1.xml
  def update
    @change_item = ChangeItem.find(params[:id])

    respond_to do |format|
      if @change_item.update_list(params[:change_item])
        flash['notice'] = "Change type '#{@change_item.name}' was successfully updated."
        format.html { redirect_to(change_type_change_items_path(@change_type)) }
        format.xml  { head :ok }
      else
         @change_items = @change_type.change_items.find(:all)
         @positions    = @change_items.size    
        format.html { render :action => "edit" }
        format.xml  { render :xml => @change_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /change_items/1
  # DELETE /change_items/1.xml
  #def destroy
  #  @change_item = ChangeItem.find(params[:id])
  #  @change_item.destroy
  #
  #  respond_to do |format|
  #    format.html { redirect_to(change_items_url) }
  #    format.xml  { head :ok }
  #  end
  #end
  
private

def load_change_types
  @change_type = ChangeType.find(params[:change_type_id])
end

  
end
