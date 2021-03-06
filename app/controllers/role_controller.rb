########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: role_controller.rb
#
# This contains the logic to create and modify role information.
#
# $Id$
#
########################################################################

class RoleController < ApplicationController


  before_filter :verify_admin_role
  

  ######################################################################
  #
  # list
  #
  # Description:
  # This method retrieves a list of roles from the database for
  # display.  The list is paginated and is limited to the number 
  # passed to the ":per_page" argument.
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

    @roles = Role.find(:all, :order => 'name')

  end

  ######################################################################
  #
  # add
  #
  # Description:
  # This method creates a role for the edit view.
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
  def add
  
    @role = Role.new(:active => 1)
    @users = User.all
    
    render(:action => 'edit')
    
  end
  ######################################################################
  #
  # create
  #
  # Description:
  # This method uses the information passed back from the user
  # to create a new role in the database
  #
  # Parameters from params
  # ['new_role'] - the information to be stored for the new role.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def create

    @role = Role.create(params[:role])

    if @role.errors.empty?
      flash['notice'] = "Role #{@role.display_name} added"
      redirect_to :action => 'list'
    else
      flash['notice'] = @role.errors.full_messages.pop
      redirect_to :action => 'add'
    end
   
  end


  ######################################################################
  #
  # edit
  #
  # Description:
  # This method retrieves the role from the database for display.
  #
  # Parameters from params
  # ['id'] - Used to identify the role to be retrieved.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def edit 
    @role = Role.find(params[:id])
    @users = User.all
  end


  ######################################################################
  #
  # update
  #
  # Description:
  # This method uses information passed back from the edit screen to
  # update the database.
  #
  # Parameters from params
  # ['role'] - Used to identify the role to be updated.
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update
    @role = Role.find(params[:role][:id])

    if @role.update_attributes(params[:role])
      flash['notice'] = 'Role was successfully updated.'
      redirect_to :action => 'edit', 
                  :id     => params[:role][:id]
    else
      flash['notice'] = 'Role not updated'
      redirect_to :action => 'edit', 
                  :id     => params[:role][:id]
    end
    

  end


  ######################################################################
  #
  # list_review_roles
  #
  # Description:
  # This method gathers the information to display the review roles.
  #
  # Parameters from params
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def list_review_roles

    @review_roles = Role.get_review_roles

  end

  
  ######################################################################
  #
  # update_review_roles
  #
  # Description:
  # This method processes the user input from the list_review_roles
  # screen.
  #
  # Parameters from params
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update_review_roles

    review_roles = Role.get_review_roles
    
    updated_roles = params[:review_role]

    update = false
    for review_role in review_roles
      
      role_id = review_role.id.to_s

      if review_role.cc_peers? && updated_roles[role_id] == '0'
	review_role.cc_peers = 0
	review_role.save
	update = true
      elsif (not review_role.cc_peers?) && updated_roles[role_id] == '1'
	review_role.cc_peers = 1
	review_role.save
	update = true
      end
    end

    if update
      flash['notice'] = 'Role(s) were successfully updated'
    else
      flash['notice'] = 'No updates occurred'
    end
    redirect_to(:action => 'list_review_roles')

  end
  

  ######################################################################
  #
  # toggle_reviewer_selection
  #
  # Description:
  # Provides/hides the default reviewer selection box from the view.
  # If the review checkbox is selected then the selection box is provided.
  #
  # Parameters from params
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def toggle_reviewer_selection
    @role = Role.find(params[:id]) if params[:id]
    render(:partial => 'toggle_reviewer_selection')
  end

  # POST
  # Method takes permission selected from list of permissions on the edit page and adds or deletes it 
  # from the permissions_roles join table based on what list user selected the permission from
  def change_users_list
    @role = Role.find(params[:id])
    user = User.find(params[:user_id])
    mode = params[:mode]
    
    if mode == "add_user"
      @role.users << user if user
    else
      @role.users.delete(user) if user
    end
    
    @role.reload
    render :partial => 'user_select_boxes'
  end
  

end
