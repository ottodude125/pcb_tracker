########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: tracker_controller.rb
#
# This contains the logic that handles events from the outside world
# (user input), interacts with the tracker model, and displays the 
# appropriate view to the user.
#
# $Id$
#
########################################################################

class TrackerController < ApplicationController

  before_filter(:verify_logged_in,
                :except => :index)

  ######################################################################
  #
  # index
  #
  # Description:
  # This method determines which home page to display based on the 
  # user's role
  #
  # Parameters from @params
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def index

    session[:return_to] = {:controller => 'tracker',
                           :action     => 'index'}
    flash['notice'] = flash['notice']

    if @session[:active_role] != nil
      case @session[:active_role]
      when "Designer"
        redirect_to :action => :designer_home
      when "Reviewer"   
        redirect_to :action => :reviewer_home
      when "Manager"    
        redirect_to :action => :manager_home
      when "Admin"      
        redirect_to :action => :admin_home
      when "PCB Admin"
        redirect_to :action => :pcb_admin_home
      else
        redirect_to :action => :reviewer_home
      end
    end
    
    @session[:return_to] = {:controller => 'tracker',
                            :action     => 'index'}

  end


  ######################################################################
  #
  # pcb_admin_home
  #
  # Description:
  # This method gathers the information to display the PCB Admin's 
  # home page.
  #
  # Parameters from @params
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def pcb_admin_home
  
    @designer = Hash.new

    release_review = ReviewType.find_by_name('Release')
    designs = Design.find_all_by_phase_id(release_review.id,
                                          'created_on ASC')

    designs = designs.sort_by { |dr| dr.priority.value }
        
    @design_list = Array.new
    for design in designs
      
      design_summary = Hash.new
      design_summary[:design] = design

      design_reviews = DesignReview.find_all("design_id='#{design.id}'")
      reviews = design_reviews.sort_by{ |r| r.review_type.sort_order }

      # Go through the reviews until the first review that has not been
      # started is found.
      review_list = Array.new
	    reviews_started = 0

      for review in reviews

        next_review = review
        
        break if review.review_status.name == 'Not Started'
        last_status = review.review_status.name
        
        reviews_started += 1

        review_rec = Hash.new
        review_rec[:review]    = review
        review_results = DesignReviewResult.find_all("design_review_id='#{review.id}'")
        review_rec[:reviewers] = review_results.size
        review_results.delete_if { |dr| dr.result != 'APPROVED' && dr.result != 'WAIVED' }
        review_rec[:approvals] = review_results.size
        review_list.push(review_rec)

      end

      design_summary[:reviews]     = review_list

	    if reviews_started == 0
	      design_summary[:next_review] = reviews[0]
	    elsif reviews.size == review_list.size
        design_summary[:next_review] = nil
	    elsif last_status == "Review Completed"
	      design_summary[:next_review] = next_review
      else
	      design_summary[:next_review] = nil
	    end

      audit = Audit.find_all("design_id='#{design.id}'").pop
      design_summary[:audit] = audit

      num_checks = Audit.check_count(audit.id)
	
      design_summary[:percent_complete]      = 
        audit.designer_completed_checks * 100.0 / num_checks[:designer]
      design_summary[:peer_percent_complete] = 
        audit.auditor_completed_checks * 100.0 / num_checks[:peer]

      @design_list.push(design_summary)
    end

  end


  ######################################################################
  #
  # designer_home
  #
  # Description:
  # This method gathers the information to display the Designer's 
  # home page.
  #
  # Parameters from @params
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def designer_home

    @designer = Hash.new

    designs = Design.find_all_by_designer_id(@session[:user].id,
                                             'created_on ASC')
    pre_art_phase_id = ReviewType.find_by_name('Pre-Artwork').id
    designs += Design.find_all_by_pcb_input_id_and_phase_id(@session[:user].id,
                                                             pre_art_phase_id,
                                                             'created_on ASC')
    designs = designs.uniq

    designs = designs.sort_by { |dr| dr.priority.value }
    designs.reverse!
        
    @design_list = Array.new
    for design in designs

      design_summary = Hash.new
      design_summary[:design] = design

      design_reviews = design.design_reviews
      reviews = design_reviews.sort_by{ |r| r.review_type.sort_order }

      # Go through the reviews until the first review that has not been
      # started is found.
      review_list = Array.new
	    reviews_started = 0

      for review in reviews

        next_review = review
        
        break if review.review_status.name == 'Not Started'
        last_status = review.review_status.name
        
        reviews_started += 1

        review_rec = Hash.new
        review_rec[:review]    = review
        review_results = DesignReviewResult.find_all("design_review_id='#{review.id}'")
        review_rec[:reviewers] = review_results.size
        review_results.delete_if { |dr| dr.result != 'APPROVED' && dr.result != 'WAIVED' }
        review_rec[:approvals] = review_results.size
        review_list.push(review_rec)

      end

      design_summary[:reviews]     = review_list

	    if reviews_started == 0
	      design_summary[:next_review] = reviews[0]
	    elsif reviews.size == review_list.size
        design_summary[:next_review] = nil
	    elsif next_review && next_review.review_status.name == "Not Started"
	      design_summary[:next_review] = next_review
      else
	      design_summary[:next_review] = nil
	    end

      audit = Audit.find_all("design_id='#{design.id}'").pop
      design_summary[:audit] = audit

      num_checks = Audit.check_count(audit.id)
	
      design_summary[:percent_complete]      = 
        audit.designer_completed_checks * 100.0 / num_checks[:designer]
      design_summary[:peer_percent_complete] = 
        audit.auditor_completed_checks * 100.0 / num_checks[:peer]

      @design_list.push(design_summary)
    end

    @audits = Array.new
    
    peer_designs = Design.find_all("peer_id=#{@session[:user].id}",
                                   'created_on ASC')
    
    for peer_design in peer_designs
      audit = Audit.find_all("design_id='#{peer_design.id}'").pop

      num_checks = Audit.check_count(audit.id)

      audit[:percent_complete]          = audit.auditor_completed_checks *
        100.0 / num_checks[:peer]
      audit[:designer_percent_complete] = audit.designer_completed_checks *
        100.0 / num_checks[:designer]
      @audits.push(audit)
    end

  end
  
  
  ######################################################################
  #
  # reviewer_home
  #
  # Description:
  # This method gathers the information to display the Reviewer's 
  # home page.
  #
  # Parameters from @params
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def reviewer_home
  
    me = @session[:user]
    in_review      = ReviewStatus.find_by_name('In Review')
    pending_repost = ReviewStatus.find_by_name('Pending Repost')
    
    design_reviews  = DesignReview.find_all_by_review_status_id(in_review.id) +
      DesignReview.find_all_by_review_status_id(pending_repost.id)

    design_reviews = design_reviews.sort_by { |dr| dr.priority.value }
    design_reviews.reverse!
    
    @my_reviews    = Array.new
    @other_reviews = Array.new
    for design_review in design_reviews
      review_results = design_review.design_review_results
    
      for review_result in review_results
        a_reviewer = (review_result.reviewer_id == me.id)
        break if a_reviewer
      end
      
      if a_reviewer
        @my_reviews.push(design_review)
      else

        # Capture the reviewer's peer names for display.
        design_review[:peer_list]   = []
        design_review[:peer_result] = []
        for role in @session[:roles]
          if role.reviewer?
            for review_result in review_results

              peer_info = {}
              if role.id == review_result.role_id
                peer_info[:name]   = User.find(review_result.reviewer_id).name
                peer_info[:role]   = role.name
                design_review[:peer_list].push(peer_info)
                
                design_review[:peer_result].push(review_result.result)
              end
            end
          end
        end

        @other_reviews.push(design_review)
      end
    end

  end
  
  
  ######################################################################
  #
  # manager_home
  #
  # Description:
  # This method gathers the information to display the Manager's 
  # home page.
  #
  # Parameters from @params
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def manager_home

    @sort_order = {:priority => 'DESC'}
    @sort_order.default = 'ASC'
    flash[:sort_order] = @sort_order
      
    @design_reviews = get_design_reviews
    @design_reviews = @design_reviews.sort_by { |dr| dr.priority.value }
    @design_reviews.reverse!

    @session[:return_to] = {:controller => 'tracker',
                            :action     => 'index'}
  end
 
  
  def manager_list_by_priority
  
    if @session[:active_role] == 'Manager'
      @sort_order = @session['flash'][:sort_order]

      @sort_order[:priority] = @params[:order] == 'ASC' ? 'DESC' : 'ASC'
      flash[:sort_order] = @sort_order

      @design_reviews = get_design_reviews
    
      @design_reviews = @design_reviews.sort_by { |dr| dr.priority.value }
      @design_reviews.reverse! if @params[:order] == 'ASC'

      @session[:return_to] = {:controller => 'tracker',
                              :action     => 'manager_list_by_priority'}
      render_action 'manager_home'
    else
      redirect_to :action => :index
    end
  end  
  
  
  def manager_list_by_design
  
    if @session[:active_role] == 'Manager'
      @sort_order = flash[:sort_order]
      @sort_order[:design] = @params[:order] == 'ASC' ? 'DESC' : 'ASC'
      flash[:sort_order] = @sort_order
    
      @design_reviews = get_design_reviews
    
      @design_reviews = @design_reviews.sort_by { |dr| dr.design.name }
      @design_reviews.reverse! if @params[:order] == 'ASC'
    
      @session[:return_to] = {:controller => 'tracker',
                              :action     => 'manager_list_by_design'}
      render_action 'manager_home'
    else
      redirect_to :action => :index
    end
  end  
  
  
  def manager_list_by_type
  
    if @session[:active_role] == 'Manager'
      @sort_order = flash[:sort_order]
      @sort_order[:type] = @params[:order] == 'ASC' ? 'DESC' : 'ASC'
      flash[:sort_order] = @sort_order
    
      @design_reviews = get_design_reviews
    
      @design_reviews = @design_reviews.sort_by { |dr| dr.review_type.name }
      @design_reviews.reverse! if @params[:order] == 'ASC'
    
      @session[:return_to] = {:controller => 'tracker',
                              :action     => 'manager_list_by_type'}
      render_action 'manager_home'
    else
      redirect_to :action => :index
    end
  end  
  
  
  def manager_list_by_designer
  
    if @session[:active_role] == 'Manager'
      @sort_order = flash[:sort_order]
      @sort_order[:designer] = @params[:order] == 'ASC' ? 'DESC' : 'ASC'
      flash[:sort_order] = @sort_order
    
      @design_reviews = get_design_reviews
    
      @design_reviews = @design_reviews.sort_by { |dr| User.find(dr.design.designer_id).last_name }
      @design_reviews.reverse! if @params[:order] == 'ASC'
    
      @session[:return_to] = {:controller => 'tracker',
                              :action     => 'manager_list_by_designer'}
      render_action 'manager_home'
    else
      redirect_to :action => :index
    end
  end  
  
  
  def manager_list_by_peer
  
    if @session[:active_role] == 'Manager'
      @sort_order = flash[:sort_order]
      @sort_order[:designer] = @params[:order] == 'ASC' ? 'DESC' : 'ASC'
      flash[:sort_order] = @sort_order
    
      @design_reviews = get_design_reviews
    
      @design_reviews = @design_reviews.sort_by { |dr| User.find(dr.design.peer_id).last_name }
      @design_reviews.reverse! if @params[:order] == 'ASC'
    
      @session[:return_to] = {:controller => 'tracker',
                              :action     => 'manager_list_by_peer'}
      render_action 'manager_home'
    else
      redirect_to :action => :index
    end
  end  
  
  
  def manager_list_by_date
  
    if @session[:active_role] == 'Manager'
      @sort_order = flash[:sort_order]
      @sort_order[:date] = @params[:order] == 'ASC' ? 'DESC' : 'ASC'
      flash[:sort_order] = @sort_order
    
      @design_reviews = get_design_reviews
    
      @design_reviews = @design_reviews.sort_by { |dr| dr.reposted_on }
      @design_reviews.reverse! if @params[:order] == 'ASC'
    
      @session[:return_to] = {:controller => 'tracker',
                              :action     => 'manager_list_by_date'}
      render_action 'manager_home'
    else
      redirect_to :action => :index
    end
  end  
  
  
  def admin_home
  
  end
  
  
  private
  
  
  def get_design_reviews
   in_process = ReviewStatus.find_by_name('In Review')
   design_reviews = DesignReview.find_all("review_status_id=#{in_process.id}",
                                           'created_on ASC')
    for design_review in design_reviews
      begin
        design_review[:priority_name] = design_review.priority.name
      rescue
        design_review[:priority_name] = "Unset"
      end
      
      design_review[:reviewers] = 
        DesignReviewResult.find_all("design_review_id='#{design_review.id}'").size
      design_review[:approvals] = DesignReviewResult.find_all("design_review_id='#{design_review.id}' and result='#{DesignReviewResult::APPROVED}'").size
    end
    return design_reviews
  end

end
