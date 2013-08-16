########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: change_class_controller.rb
#
# This contains the logic to create and modify change classes.
#
# $Id$
#
########################################################################

class ChangeClassesController < ApplicationController
  
  
  before_filter :verify_admin_role 
  
  
  # GET /change_classes
  # GET /change_classes.xml
  def index

    @change_classes = ChangeClass.find(:all, :order => :position)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @change_classes }
    end
  end

  # GET /change_classes/1
  # GET /change_classes/1.xml
  #def show
  #  @change_class = ChangeClass.find(params[:id])
  #  
  #  respond_to do |format|
  #    format.html # show.html.erb
  #    format.xml  { render :xml => @change_class }
  #  end
  #end

  # GET /change_classes/new
  # GET /change_classes/new.xml
  def new
    @change_classes = ChangeClass.find(:all, :order => :position)
    @positions      = @change_classes.size + 1
    @change_class   = ChangeClass.new( :position  => @change_classes.size + 1,
                                       :active    => true )
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @change_class }
    end
  end

  # GET /change_classes/1/edit
  def edit
    @change_classes = ChangeClass.find(:all, :order => :position)
    @positions      = @change_classes.size
    @change_class   = ChangeClass.find(params[:id])
  end

  # POST /change_classes
  # POST /change_classes.xml
  def create
    @change_class = ChangeClass.new(params[:change_class])

    respond_to do |format|
      if @change_class.add_to_list
        flash['notice'] = "Change class '#{@change_class.name}' was successfully created."
        format.html { redirect_to(change_classes_path) }
        format.xml  { render :xml => @change_class, :status => :created, :location => @change_class }
      else
        @change_classes = ChangeClass.find(:all, :order => :position)
        @positions      = @change_classes.size + 1
        format.html { render :action => "new" }
        format.xml  { render :xml => @change_class.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /change_classes/1
  # PUT /change_classes/1.xml
  def update
    @change_class = ChangeClass.find(params[:id])

    respond_to do |format|
      if @change_class.update_list(params[:change_class])
        flash['notice'] = "Change class '#{@change_class.name}' was successfully updated."
        format.html { redirect_to(change_classes_path) }
        format.xml  { head :ok }
      else
        @change_classes = ChangeClass.find(:all, :order => :position)
        @positions      = @change_classes.size
        format.html { render :action => "edit" }
        format.xml  { render :xml => @change_class.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /change_classes/1
  # DELETE /change_classes/1.xml
  #def destroy
  #  @change_class = ChangeClass.find(params[:id])
  #  @change_class.destroy
  #
  #  respond_to do |format|
  #    format.html { redirect_to(change_classes_url) }
  #    format.xml  { head :ok }
  #  end
  #end
  
  def reason_relationships
    @reasons = ChangeClass.includes(change_types: [change_items: :change_details]).order("position")
  end
  
end







