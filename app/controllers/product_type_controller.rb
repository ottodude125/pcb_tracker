########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: product_type_controller.rb
#
# This contains the logic to create and modify product types.
#
# $Id$
#
########################################################################

class ProductTypeController < ApplicationController

  before_filter :verify_admin_role


  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of product types from the database for 
  # display.
  #
  # Parameters from params
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def list
    
    @product_type_pages, @product_types = paginate(:product_types, 
					                               :per_page => 15,
					                               :order_by => "name")
  end 


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the product type from the database for display.
  #
  # Parameters from params
  # ['id'] - Used to identify the product type to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def edit 
    @product_type = ProductType.find(params[:id])
  end


  ######################################################################
  #
  # update
  #
  # Description:
  # This method updates the database with the modified product type
  # information
  #
  # Parameters from params
  # ['product_type'] - Contains the information used to make the update.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def update
    @product_type = ProductType.find(params[:product_type][:id])

    if @product_type.update_attributes(params[:product_type])
      flash['notice'] = 'Product Type was successfully updated.'
      redirect_to :action => 'edit', 
                  :id     => params[:product_type][:id]
    else
      flash['notice'] = @product_type.errors.full_messages.pop
      redirect_to :action => 'edit', 
                  :id     => params[:product_type][:id]
    end

  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method creates a new product type in the database.
  #
  # Parameters from params
  # ['new_product_type'] - Contains the information used to make the
  #                        update.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def create

    @product_type = ProductType.create(params[:new_product_type])

    if @product_type.errors.empty?
      flash['notice'] = "Product Type #{@product_type.name} added"
      redirect_to :action => 'list'
    else
      flash['notice'] = @product_type.errors.full_messages.pop
      redirect_to :action => 'add'
    end
   
  end

  
end
