########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: change_types_controller.rb
#
# This contains the logic to create and modify change types.
#
# $Id$
#
########################################################################

class ChangeTypesController < ApplicationController
  
  before_filter :verify_admin_role 
  before_filter :load_change_classes
  
  
  # GET /change_types
  # GET /change_types.xml
  def index
    @change_types = @change_class.change_types.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @change_types }
    end
  end

  # GET /change_types/1
  # GET /change_types/1.xml
  #def show
  #  @change_type = ChangeType.find(params[:id])
  #
  #  respond_to do |format|
  #    format.html # show.html.erb
  #    format.xml  { render :xml => @change_type }
  #  end
  #end

  # GET /change_types/new
  # GET /change_types/new.xml
  def new
    
    @change_types = @change_class.change_types.find(:all)
    @positions    = @change_types.size + 1
    @change_type  = ChangeType.new( :change_class_id => params[:change_class_id],
                                    :position        => @positions,
                                    :active          => true)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @change_type }
    end
  end

  # GET /change_types/1/edit
  def edit
    @change_type  = ChangeType.find(params[:id])
    @change_types = @change_type.change_class.change_types.find(:all)
    @positions    = @change_types.size
  end

  # POST /change_types
  # POST /change_types.xml
  def create
    @change_type = ChangeType.new(params[:change_type])
    @change_type.change_class_id = @change_class.id

    respond_to do |format|
      if @change_type.add_to_list
        flash['notice'] = "Change type '#{@change_class.name}' was successfully created."
        format.html { redirect_to(change_class_change_types_path(@change_class)) }
        format.xml  { render :xml => @change_type, :status => :created, :location => @change_type }
      else
        @change_types = @change_class.change_types.find(:all)
        @positions    = @change_types.size + 1
        format.html { render :action => "new" }
        format.xml  { render :xml => @change_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /change_types/1
  # PUT /change_types/1.xml
  def update
    @change_type = ChangeType.find(params[:id])

    respond_to do |format|
      if @change_type.update_list(params[:change_type])
        flash['notice'] = "Change type '#{@change_class.name}' was successfully updated."
        format.html { redirect_to(change_class_change_types_path(@change_class)) }
        format.xml  { head :ok }
      else
        @change_types = @change_type.change_class.change_types.find(:all)
        @positions    = @change_types.size
        format.html { render :action => "edit" }
        format.xml  { render :xml => @change_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /change_types/1
  # DELETE /change_types/1.xml
  #def destroy
  #  @change_type = ChangeType.find(params[:id])
  #  @change_type.destroy
  #
  #  respond_to do |format|
  #    format.html { redirect_to(change_types_url) }
  #    format.xml  { head :ok }
  #  end
  #end
  
private

def load_change_classes
  @change_class = ChangeClass.find(params[:change_class_id])
end

  
end
