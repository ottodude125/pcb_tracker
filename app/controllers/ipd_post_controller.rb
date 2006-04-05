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
          flash["notice"] = "Reply post sucessfully created"
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
  # This method creates a root level in-process dialogue post
  # for a the design identified by params[:design_id]
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


  def create
    @ipd_post = IpdPost.new(params[:ipd_post])
    @ipd_post.user_id = @session[:user].id
    if @ipd_post.save
      flash[:notice] = 'Post was successfully created'
      redirect_to(:action => 'show', :id => @ipd_post.id)
    else
      render :action => 'new'
    end
  end
  
  
end
