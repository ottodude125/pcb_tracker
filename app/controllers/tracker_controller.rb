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

  before_filter(:verify_manager_admin_privs, 
                :except => [:index,
                            :admin_home,
                            :designer_home,
                            :manager_home,
                            :pcb_admin_home,
                            :reviewer_home])

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
    
    if session[:active_role] != nil
      case session[:active_role].name
      when "Designer"
        designer_home_setup
        render_action('designer_home')
      when "Reviewer"
        reviewer_home_setup
        render_action('reviewer_home')
      when "Manager", "Admin"
        manager_home_setup
        render_action('manager_home')
      when "PCB Admin"
        pcb_admin_home_setup
        render_action('pcb_admin_home')
      when "Basic User"
        # Use the default home page
      else
        reviewer_home_setup
        render_action('reviewer_home')
      end
    end
    
    @session[:return_to] = {:controller => 'tracker',
                            :action     => 'index'}

  end
  
  
  ######################################################################
  #
  # admin_home
  #
  # Description:
  # This method redirects to index to accomodate an obsolete action.
  #
  # Parameters from @params
  # None
  #
  ######################################################################
  #
  def admin_home
    redirect_to(:action => 'index')
  end
  
  
  ######################################################################
  #
  # reviewer_home
  #
  # Description:
  # This method redirects to index to accomodate an obsolete action.
  #
  # Parameters from @params
  # None
  #
  ######################################################################
  #
  def reviewer_home
    redirect_to(:action => 'index')
  end
  
  
  ######################################################################
  #
  # manager_home
  #
  # Description:
  # This method redirects to index to accomodate an obsolete action.
  #
  # Parameters from @params
  # None
  #
  ######################################################################
  #
  def manager_home
    redirect_to(:action => 'index')
  end
  
  
  ######################################################################
  #
  # pcb_admin_home
  #
  # Description:
  # This method redirects to index to accomodate an obsolete action.
  #
  # Parameters from @params
  # None
  #
  ######################################################################
  #
  def pcb_admin_home
    redirect_to(:action => 'index')
  end
  
  
  ######################################################################
  #
  # designer_home
  #
  # Description:
  # This method redirects to index to accomodate an obsolete action.
  #
  # Parameters from @params
  # None
  #
  ######################################################################
  #
  def designer_home
    redirect_to(:action => 'index')
  end


  ######################################################################
  #
  # manager_list_by_priority
  #
  # Description:
  # This method manages the ordering of the list by the criticality.
  #
  # Parameters from @params
  # order - the desired order, either ascending or descending, of the
  #         list by the criticality.
  #
  ######################################################################
  #
  def manager_list_by_priority
  
    @sort_order            = get_sort_order
    @sort_order[:priority] = @params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order]     = @sort_order

    @design_reviews = 
      get_active_reviews.sort_by { |dr| [dr.priority.value, dr.age] }
    @design_reviews.reverse! if @params[:order] == 'DESC'

    @submissions = BoardDesignEntry.count("state='submitted'")
    @session[:return_to] = {:controller => 'tracker',
                            :action => 'manager_list_by_priority',
                            :order  => @params[:order]}
    render_action 'manager_home'

  end  
  
  
  ######################################################################
  #
  # manager_list_by_design
  #
  # Description:
  # This method manages the ordering of the list by the design number.
  #
  # Parameters from @params
  # order - the desired order, either ascending or descending, of the
  #         list by the design number.
  #
  ######################################################################
  #
  def manager_list_by_design
  
      @sort_order          = get_sort_order
      @sort_order[:design] = @params[:order] == 'ASC' ? 'DESC' : 'ASC'
      flash[:sort_order]   = @sort_order
    
      @design_reviews = get_active_reviews.sort_by { |dr| dr.design.name }
      @design_reviews.reverse! if @params[:order] == 'DESC'
    
      @submissions = BoardDesignEntry.count("state='submitted'")
      @session[:return_to] = {:controller => 'tracker',
                              :action     => 'manager_list_by_design',
                              :order      => @params[:order]}
      render_action 'manager_home'

  end  
  
  
  ######################################################################
  #
  # manager_list_by_type
  #
  # Description:
  # This method manages the ordering of the list by the design review
  # type.
  #
  # Parameters from @params
  # order - the desired order, either ascending or descending, of the
  #         list by the design review type.
  #
  ######################################################################
  #
  def manager_list_by_type
    
    @sort_order        = get_sort_order
    @sort_order[:type] = @params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order] = @sort_order
    
    @design_reviews = 
      get_active_reviews.sort_by { |dr| [dr.review_type.name, dr.age] }
    @design_reviews.reverse! if @params[:order] == 'DESC'
    
    @submissions = BoardDesignEntry.count("state='submitted'")
    @session[:return_to] = {:controller => 'tracker',
                            :action     => 'manager_list_by_type',
                            :order      => @params[:order]}
    render_action 'manager_home'

  end  
  
  
  ######################################################################
  #
  # manager_list_by_designer
  #
  # Description:
  # This method manages the ordering of the list by the designer.
  #
  # Parameters from @params
  # order - the desired order, either ascending or descending, of the
  #         list by the designer.
  #
  ######################################################################
  #
  def manager_list_by_designer

    @sort_order            = get_sort_order
    @sort_order[:designer] = @params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order]     = @sort_order
    
    @design_reviews = 
      get_active_reviews.sort_by { |dr| [dr.designer.last_name, dr.age] }
    @design_reviews.reverse! if @params[:order] == 'DESC'
    
    @submissions = BoardDesignEntry.count("state='submitted'")
    @session[:return_to] = {:controller => 'tracker',
                            :action     => 'manager_list_by_designer',
                            :order      => @params[:order]}
    render_action 'manager_home'

  end  
  
  
  ######################################################################
  #
  # manager_list_by_peer
  #
  # Description:
  # This method manages the ordering of the list by the peer.
  #
  # Parameters from @params
  # order - the desired order, either ascending or descending, of the
  #         list by the peer.
  #
  ######################################################################
  #
  def manager_list_by_peer
  
    @sort_order        = get_sort_order
    @sort_order[:peer] = @params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order] = @sort_order
    
    @design_reviews = 
      get_active_reviews.sort_by { |dr| [dr.design.peer.last_name, dr.age] }
    @design_reviews.reverse! if @params[:order] == 'DESC'
    
    @submissions = BoardDesignEntry.count("state='submitted'")
    @session[:return_to] = {:controller => 'tracker',
                            :action     => 'manager_list_by_peer',
                            :order      => @params[:order]}
    render_action 'manager_home'
    
  end  
  
  
  ######################################################################
  #
  # manager_list_by_age
  #
  # Description:
  # This method manages the ordering of the list by the age in work days.
  #
  # Parameters from @params
  # order - the desired order, either ascending or descending, of the
  #         list by age in work days..
  #
  ######################################################################
  #
  def manager_list_by_age
  
    @sort_order        = get_sort_order
    @sort_order[:date] = @params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order] = @sort_order
    
    @design_reviews = 
      get_active_reviews.sort_by { |dr| [dr.age, dr.priority.value] }
    @design_reviews.reverse! if @params[:order] == 'DESC'
    
    @submissions = BoardDesignEntry.count("state='submitted'")
    @session[:return_to] = {:controller => 'tracker',
                            :action     => 'manager_list_by_age',
                            :order      => @params[:order]}
    render_action 'manager_home'

  end  
  
  
  ######################################################################
  #
  # manager_list_by_status
  #
  # Description:
  # This method manages the ordering of the list by the design review
  # status.
  #
  # Parameters from @params
  # order - the desired order, either ascending or descending, of the
  #         list by the design review status.
  #
  ######################################################################
  #
  def manager_list_by_status
  
    @sort_order          = get_sort_order
    @sort_order[:status] = @params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order]   = @sort_order
    
    @design_reviews = 
      get_active_reviews.sort_by { |dr| [dr.review_status.name, dr.age] }
    @design_reviews.reverse! if @params[:order] == 'DESC'
    
    @submissions = BoardDesignEntry.count("state='submitted'")
    @session[:return_to] = {:controller => 'tracker',
                            :action     => 'manager_list_by_date',
                            :order      => @params[:order]}
    render_action 'manager_home'

  end  
  
  
  private
  
  
  ######################################################################
  #
  # get_sort_order
  #
  # Description:
  # This method attempts to retrieve the sort order from the session flash.
  # If it does not exist then a new hash is created and the default order 
  # is set to ascending
  #
  # Parameters
  # None
  # 
  # Returns
  # A hash containing the sort order
  #
  ######################################################################
  #
  def get_sort_order
    if @session['flash'][:sort_order]
      return @session['flash'][:sort_order]
    else
      return Hash.new('ASC')
    end
  end
  
  
  ######################################################################
  #
  # pcb_admin_home_setup
  #
  # Description:
  # This method gathers the information to display the PCB Admin's 
  # home page.
  #
  # Parameters from @params
  # None
  #
  ######################################################################
  #
  def pcb_admin_home_setup
  
    @designer = {}

    release_review = ReviewType.find_by_name('Release')
    designs = Design.find_all_by_phase_id(release_review.id,
                                          'created_on ASC')

    designs = designs.sort_by { |dr| dr.priority.value }
        
    @design_list = []
    designs.each do |design|
      
      design_summary = {:design => design}

      design_reviews = DesignReview.find_all("design_id='#{design.id}'")
      reviews = design_reviews.sort_by{ |r| r.review_type.sort_order }

      # Go through the reviews until the first review that has not been
      # started is found.
      review_list = []
	    reviews_started = 0

      reviews.each do |review|

        next_review = review
        
        break if review.review_status.name == 'Not Started'
        last_status = review.review_status.name
        
        reviews_started += 1

        review_rec = {:review => review}
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

      num_checks = audit.check_count
	
      design_summary[:percent_complete]      = 
        audit.designer_completed_checks * 100.0 / num_checks[:designer]
      design_summary[:peer_percent_complete] = 
        audit.auditor_completed_checks * 100.0 / num_checks[:peer]

      @design_list.push(design_summary)
    end

  end


  ######################################################################
  #
  # designer_home_setup
  #
  # Description:
  # This method gathers the information to display the Designer's 
  # home page.
  #
  # Parameters from @params
  # None
  #
  ######################################################################
  #
  def designer_home_setup

    pre_art_phase_id = ReviewType.find_by_name('Pre-Artwork').id

    designs  = Design.find_all("designer_id='#{session[:user].id}' AND phase_id!='#{Design::COMPLETE}' AND phase_id!='#{pre_art_phase_id}'",
                               'created_on ASC') +
               Design.find_all("pcb_input_id='#{session[:user].id}' AND phase_id='#{pre_art_phase_id}'",
                               'created_on ASC')
    @designs = designs.uniq.sort_by { |dr| dr.priority.value }
        
    @designs.each do |design|

      current_phase           = ReviewType.find(design.phase_id)
      design[:next_review]    = design.design_reviews.detect{ |dr| dr.review_type_id == design.phase_id}
      design.design_reviews.delete_if do |dr| 
        (dr.review_status.name == "Not Started" || 
         dr.review_type.sort_order > current_phase.sort_order)
      end
      design[:design_reviews] = design.design_reviews.sort_by{ |dr| dr.review_type.sort_order }

      # Go through the reviews until the first review that has not been
      # started is found.
      design.design_reviews.each do |design_review|
        review_results            = design_review.design_review_results
        design_review[:reviewers] = review_results.size
        review_results.delete_if { |dr| dr.result != 'APPROVED' && dr.result != 'WAIVED' }
        design_review[:approvals] = review_results.size
      end


      audit = design.audit

      num_checks = audit.check_count
	
      design[:percent_complete]      = 
        audit.designer_completed_checks * 100.0 / num_checks[:designer]
      design[:peer_percent_complete] = 
        audit.auditor_completed_checks * 100.0 / num_checks[:peer]

    end

    audits = {}
    #
    # Get the audits where the user is the member of an audit team.
    # 
    my_audit_teams = AuditTeammate.find_all_by_user_id(@session[:user].id)
    for audit_team in my_audit_teams
      
      audit = audit_team.audit
      next if audit.is_peer_audit? & audit_team.self?
 
      audit[:self] = audit_team.self?
      num_checks = audit.check_count
      audit[:percent_complete]          = audit.auditor_completed_checks *
        100.0 / num_checks[:peer]
      audit[:designer_percent_complete] = audit.designer_completed_checks *
        100.0 / num_checks[:designer]
      audits[audit.id] = audit
      
    end
    
    #
    # Get the audits where the user is listed as the lead peer.
    # 
    peer_designs = Design.find_all("peer_id=#{@session[:user].id}",
                                   'created_on ASC')

    for peer_design in peer_designs
    
      audit = Audit.find_all("design_id='#{peer_design.id}'").pop
      next if audit.is_self_audit? && audits[audit.id]
      
      audit[:self] = false
      num_checks = audit.check_count
      audit[:percent_complete]          = audit.auditor_completed_checks *
        100.0 / num_checks[:peer]
      audit[:designer_percent_complete] = audit.designer_completed_checks *
        100.0 / num_checks[:designer]
      audits[audit.id] = audit
      
    end
    
    audit_list = []
    audits.each_value { |a| audit_list << a }
    
    @audits = audit_list.sort_by { |a| a.design.priority.value }
    ##
    #TODO: After reversing the values of priority so that the call to reverse is not
    #      needed make this a multi-level sort.
    #      audits.sort_by { |a| [a.design.priority.value, a.design.age] }
    
    # Get all of the active designs and determine if there are any work assignments
    # associated with the design for the user.
    @work_assignments = false
    @my_assignments   = {}
    active_designs = Design.find_all("phase_id != #{Design::COMPLETE}")
    
    active_designs.each do |design|
      @work_assignments                 |= design.have_assignments(session[:user].id)
      my_assignments                     = design.my_assignments(session[:user].id)
      @my_assignments[design.created_on] = my_assignments if my_assignments.size > 0
    end
    
    @my_assignments = @my_assignments.to_a.sort_by { |a| a[0]}
    
  end
  
  
  ######################################################################
  #
  # reviewer_home_setup
  #
  # Description:
  # This method gathers the information to display the Reviewer's 
  # home page.
  #
  # Parameters from @params
  # None
  #
  ######################################################################
  #
  def reviewer_home_setup

    me = session[:user]
    review_status_list = [ReviewStatus.find_by_name('In Review').id,
                          ReviewStatus.find_by_name('Pending Repost').id,
                          ReviewStatus.find_by_name('Review On-Hold').id]

    design_reviews = []
    review_status_list.each do |review_status_id|
      design_reviews += DesignReview.find_all_by_review_status_id(review_status_id)
    end

    design_reviews = design_reviews.sort_by { |dr| [dr.priority.value, (10000 - dr.age)] }

    @my_reviews    = []
    @other_reviews = []
    design_reviews.each do |design_review|
      review_results = design_review.design_review_results
    
      if review_results.detect { |rr| rr.reviewer_id == me.id}
        @my_reviews.push(design_review)
      else

        # Capture the reviewer's peer names for display.
        design_review[:peer_list]   = []
        design_review[:peer_result] = []
        session[:roles].each do |role|
          if role.reviewer?
            review_results.each do |review_result|
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

        if design_review.design_review_results.detect { |rr| rr.role.id == session[:active_role].id } 
          @other_reviews.push(design_review) 
        end
      end
    end
    
    @my_reviews.sort_by { |dr| [dr.priority.value, dr.age] }

  end
  
  
  ######################################################################
  #
  # manager_home_setup
  #
  # Description:
  # This method gathers the information to display the Manager's 
  # home page.
  #
  # Parameters from @params
  # None
  #
  ######################################################################
  #
  def manager_home_setup

    @sort_order = {:priority => 'DESC'}
    @sort_order.default = 'ASC'
    flash[:sort_order] = @sort_order
      
    @design_reviews = get_active_reviews
    @design_reviews = @design_reviews.sort_by { |dr| [dr.priority.value, dr.age] }

    @submissions = BoardDesignEntry.count("state='submitted'")
    @session[:return_to] = {:controller => 'tracker',
                            :action     => 'index'}
    
  end
 
  
#  def get_design_reviews
#   in_process = ReviewStatus.find_by_name('In Review')
#   design_reviews = DesignReview.find_all("review_status_id=#{in_process.id}",
#                                           'created_on ASC')
#    for design_review in design_reviews
#      begin
#        design_review[:priority_name] = design_review.priority.name
#      rescue
#        design_review[:priority_name] = "Unset"
#      end
#      
#      design_review[:reviewers] = 
#        DesignReviewResult.find_all("design_review_id='#{design_review.id}'").size
#      design_review[:approvals] = DesignReviewResult.find_all("design_review_id='#{design_review.id}' and result='#{DesignReviewResult::APPROVED}'").size
#    end
#    return design_reviews
#  end
  
  
  ######################################################################
  #
  # get_active_reviews
  #
  # Description:
  # This method retrieves all of the active design reviews.
  #
  # Parameters from @params
  # None
  #
  ######################################################################
  #
  def get_active_reviews
  
    design_reviews = []
    designs        = Design.find_all("phase_id!=#{Design::COMPLETE}")

    designs.each do |design|
    
      next if design.phase_id == 0
    
      design_review = DesignReview.find_by_design_id_and_review_type_id(
                        design.id,
                        design.phase_id)
           
      begin
        design_review[:priority_name] = design_review.priority.name
      rescue
        design_review[:priority_name] = 'Unset'
      end
      
      results = design_review.design_review_results.collect { |r| r.result }
      design_review[:reviewers] = results.size
      design_review[:approvals] = results.find_all { |r| 
                                    (r == DesignReviewResult::APPROVED ||
                                     r == DesignReviewResult::WAIVED) }.size
          
      design_reviews << design_review
    
    end
    
    return design_reviews
  end
  

end
