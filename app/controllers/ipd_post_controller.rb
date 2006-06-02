########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: ipd_post_controller.rb
#
# This contains the logic that handles events from the outside world
# (user input), interacts with the in-process dialogue post model,
# and displays the appropriate view to the user.
#
# $Id$
#
########################################################################

class IpdPostController < ApplicationController


  before_filter(:verify_logged_in, :except => :show)
 

  ######################################################################
  #
  # list
  #
  # Description:
  # This method gathers the root level in-process dialogue posts
  # for a the design identified by params[:design_id]
  #
  # Parameters from @params
  # design_id - identifies the design.
  # page      - used by the paginate library to determine the
  #             range of ipd dialogue posts to be displayed.
  #
  ######################################################################
  #
  def list

    @design = Design.find(params[:design_id])
    @ipd_post_pages, 
    @ipd_posts = paginate(:ipd_posts,
                          :conditions => ['parent_id = 0 and design_id = ?', 
                                          @design.id],
                          :per_page => 20,
                          :order => 'root_id desc, lft')
  end


  ######################################################################
  #
  # create_reply
  #
  # Description:
  # This method uses the information passed in to create a reply to
  # a post.
  #
  # Parameters from @params
  # reply_post[:body] - contains the reply entered by the user.
  # id - identifies the root post (the post that is being replied
  #      too).
  #
  ######################################################################
  #
  def create_reply
    body = params[:reply_post][:body].rstrip
    if body != ''

      root_post = IpdPost.find(params[:id])
      last_reply_post = root_post.all_children.last

      if (last_reply_post == nil ||
          last_reply_post.body != body)
        reply_post = IpdPost.new
        reply_post.parent_id = params[:id]
        reply_post.user_id   = @session[:user].id
        reply_post.body      = body
        if reply_post.save
          TrackerMailer::deliver_ipd_update(root_post)
          flash["notice"] = "Reply post sucessfully created - mail was sent"
        end
      end
    else
      flash["notice"] = "Your reply was empty - post not created"
    end
        
    @root_post = IpdPost.find(params[:id])
    render :action => 'show'
  end


  ######################################################################
  #
  # show
  #
  # Description:
  # This method retrieves the root level in-process dialogue post
  # for a the design identified by params[:design_id].  It also
  # sets up a reply in-process dialogue post.
  #
  # Parameters from @params
  # design_id - identifies the design.
  #
  ######################################################################
  #
  def show
    @root_post = IpdPost.find(params[:id])

    @reply_post = IpdPost.new
    @reply_post.parent_id = @root_post.id
    @reply_post.design_id = @root_post.design_id
  end


  ######################################################################
  #
  # new
  #
  # Description:
  # This method creates a form to create aroot level in-process dialogue 
  # post for a the design identified by params[:design_id]
  #
  # Parameters from @params
  # design_id - identifies the design.
  #
  ######################################################################
  #
  def new
    @ipd_post           = IpdPost.new
    @ipd_post.design_id = params[:design_id]
  end


  ######################################################################
  #
  # create
  #
  # Description:
  # This method creates a root level in-process dialogue post.
  #
  # Parameters from @params
  # design_id - identifies the design.
  #
  ######################################################################
  #
  def create
    @ipd_post = IpdPost.new(params[:ipd_post])
    @ipd_post.user_id = @session[:user].id
    if @ipd_post.save
      flash['notice'] = 'Post was successfully created'
      redirect_to(:action => 'manage_email_list',
                  :id     => @ipd_post.id)
    else
      render :action => 'new'
    end
  end
  
  
  ######################################################################
  #
  # manage_email_list
  #
  # Description:
  # This method sets up the data structures to manage the email list of
  # a new thread.
  #
  # Parameters from @params
  # id - identifies the root ipd post.
  #
  ######################################################################
  #
  def manage_email_list

    flash['notice'] = flash['notice']
  
    @posting_new_thread = true
    @ipd_post           = IpdPost.find(params[:id])
    @associated_users   = @ipd_post.design.get_associated_users_by_role

    @manager_list = Role.find_by_name('Manager').users
    @manager_list.delete_if { |user| not user.active? }
   
    @input_gate_list = Role.find_by_name('PCB Input Gate').users
    @input_gate_list.delete_if { |user| not user.active? }
    
    @optional_cc_list = @ipd_post.users.dup
    

    available_to_cc = User.find_all('active=1')
    available_to_cc.delete_if { |user| user == @session[:user] }
    available_to_cc.delete_if { |user| user == @associated_users['HWENG'] }
    available_to_cc.delete_if { |user| user == @associated_users['Hardware Engineering Manager'] }
    for input_gate in @input_gate_list
      available_to_cc.delete_if { |user| user == input_gate }
    end
    for manager in @manager_list
      available_to_cc.delete_if { |user| user == manager }
    end
    for person in @optional_cc_list
      available_to_cc.delete_if { |user| user == person }
    end
    @available_to_cc = available_to_cc.sort_by { |user| user.last_name }
    
    email_list = {
      :optional_cc_list => @optional_cc_list,
      :available_to_cc  => @available_to_cc
      }
    flash[:thread_email_list] = email_list
    flash[:ipd_post]          = @ipd_post
    
  end
  
  
  ######################################################################
  #
  # add_to_thread_list
  #
  # Description:
  # This method adds the user identified by the id paramater to the 
  # thread's email CC list.
  #
  # Parameters from @params
  # id - the id of the user record to add to the list.
  #
  ######################################################################
  #
  def add_to_thread_list
  
    email_list        = flash[:thread_email_list]
    @optional_cc_list = email_list[:optional_cc_list]
    @available_to_cc  = email_list[:available_to_cc]
    ipd_post          = flash[:ipd_post]
    @subtractions     = flash[:subtractions]
    @additions        = flash[:additions]

    user_to_add = @available_to_cc.detect { |user| user.id == @params[:id].to_i }
    @available_to_cc.delete_if { |user| user == user_to_add }

    ipd_post.users << user_to_add

    if (! @subtractions ||
        ! @subtractions.detect { |u| u == user_to_add })
      if flash[:additions]
        @additions += [user_to_add]
        @additions = @additions.sort_by { |u| u.last_name }
      else
        @additions = [user_to_add] 
      end
    end
    @subtractions.delete_if { |u| u == user_to_add } if @subtractions

    @optional_cc_list << user_to_add
    @optional_cc_list = @optional_cc_list.sort_by { |user| user.last_name }

    email_list = {
      :optional_cc_list => @optional_cc_list,
      :available_to_cc  => @available_to_cc
    }

    flash[:thread_email_list] = email_list
    flash[:ipd_post]          = ipd_post
    flash[:additions]         = @additions
    flash[:subtractions]      = @subtractions

    render(:action => 'update_thread_list',
           :layout => false)

  end
  
  
  ######################################################################
  #
  # remove_from_thread_list
  #
  # Description:
  # This method removes the user identified by the id paramater from the 
  # thread's email CC list.
  #
  # Parameters from @params
  # id - the id of the user record to remove from the list.
  #
  ######################################################################
  #
  def remove_from_thread_list
  
    email_list        = flash[:thread_email_list]
    @optional_cc_list = email_list[:optional_cc_list]
    @available_to_cc  = email_list[:available_to_cc]
    ipd_post          = flash[:ipd_post]
    @additions        = flash[:additions]
    @subtractions     = flash[:subtractions]

    user_to_remove = @optional_cc_list.detect { |user| user.id == @params[:id].to_i }
    @optional_cc_list.delete_if { |user| user == user_to_remove}

    if (! @additions ||
        ! @additions.detect { |u| u == user_to_remove })
      if flash[:subtractions]
        @subtractions += [user_to_remove]
        @subtractions = @subtractions.sort_by { |u| u.last_name }
      else
        @subtractions = [user_to_remove] 
      end
    end
    @additions.delete_if { |u| u == user_to_remove } if @additions

    ipd_post.remove_users(user_to_remove)

    @available_to_cc << user_to_remove
    @available_to_cc = @available_to_cc.sort_by { |user| user.last_name }
    
    email_list = {
      :optional_cc_list => @optional_cc_list,
      :available_to_cc  => @available_to_cc
    }
    
    flash[:thread_email_list] = email_list
    flash[:ipd_post]          = ipd_post
    flash[:additions]         = @additions
    flash[:subtractions]      = @subtractions
    
    render(:action => 'update_thread_list',
           :layout => false)
    
  end
  
  
  ######################################################################
  #
  # deliver_thread_mail
  #
  # Description:
  # This method delivers the email and then redirects back to the IPD
  # post.
  #
  # Parameters from @params
  # id - identifies the root ipd post.
  #
  ######################################################################
  #
  def deliver_thread_mail
    ipd_post = IpdPost.find(params['ipd_post']['id'])
    TrackerMailer::deliver_ipd_update(ipd_post)
    redirect_to(:action => 'show', :id => ipd_post.id)
  end
  
  
  ######################################################################
  #
  # modify_email_list
  #
  # Description:
  # This method sets up the data structures to manage the email list
  # of an existing thread.
  #
  # Parameters from @params
  # id - identifies the root ipd post.
  #
  ######################################################################
  #
  def modify_email_list

    flash['notice'] = flash['notice']
  
    @posting_new_thread = false
    @ipd_post           = IpdPost.find(params[:ipd_post_id])
    @associated_users   = @ipd_post.design.get_associated_users_by_role

    @manager_list = Role.find_by_name('Manager').users
    @manager_list.delete_if { |user| not user.active? }
   
    @input_gate_list = Role.find_by_name('PCB Input Gate').users
    @input_gate_list.delete_if { |user| not user.active? }
    
    @optional_cc_list = @ipd_post.users.dup
    

    available_to_cc = User.find_all('active=1')
    available_to_cc.delete_if { |user| user == @session[:user] }
    available_to_cc.delete_if { |user| user == @associated_users['HWENG'] }
    available_to_cc.delete_if { |user| user == @associated_users['Hardware Engineering Manager'] }
    for input_gate in @input_gate_list
      available_to_cc.delete_if { |user| user == input_gate }
    end
    for manager in @manager_list
      available_to_cc.delete_if { |user| user == manager }
    end
    for person in @optional_cc_list
      available_to_cc.delete_if { |user| user == person }
    end
    @available_to_cc = available_to_cc.sort_by { |user| user.last_name }
    
    email_list = {
      :optional_cc_list => @optional_cc_list,
      :available_to_cc  => @available_to_cc
      }
    flash[:thread_email_list] = email_list
    flash[:ipd_post]          = @ipd_post
    
    render(:action => 'manage_email_list')
    
  end


end
