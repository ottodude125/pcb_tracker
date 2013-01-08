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
                        
  before_filter(:manager_setup,
                :only => [ :index,
                           :manager_list_by_age,
                           :manager_list_by_design,
                           :manager_list_by_designer,
                           :manager_list_by_peer,
                           :manager_list_by_priority,
                           :manager_list_by_status,
                           :manager_list_by_type ])

  ######################################################################
  #
  # index
  #
  # Description:
  # This method determines which home page to display based on the 
  # user's role
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
  def index

    @generate_role_links = true
    
    session[:return_to] = {:controller => 'tracker', :action => 'index'}
    flash['notice'] = flash['notice']
    # see if we have a database
    if ! DbCheck.exist?
      render( :action => 'not_configured')
      return
    end
    
    if @logged_in_user && @logged_in_user.active_role
      case @logged_in_user.active_role.name
      when "Designer"
        designer_home_setup
        render( :action => 'designer_home' )
      when "Reviewer"
        reviewer_home_setup
        render( :action => 'reviewer_home' )
      when "Manager", "Admin"
        manager_home_setup
        render( :action => 'manager_home' )
      when "PCB Admin"
        pcb_admin_home_setup
        render( :action => 'pcb_admin_home' )
      when "Basic User"
        manager_home_setup
        render( :action => 'basic_user_home')
      else
        reviewer_home_setup
        render( :action => 'reviewer_home' )
      end
    else
      # No user is identified.
      @pcbas   = PartNum.get_active_pcbas
      @designs = Design.get_active_designs
      #@designs.delete_if { |d| d.pcb_number }
      @designs = @designs.sort_by { |d| d.pcbas_string }
      
    end
    
    session[:return_to] = {:controller => 'tracker', :action => 'index'}

  end
  
  
  ######################################################################
  #
  # admin_home
  #
  # Description:
  # This method redirects to index to accomodate an obsolete action.
  #
  # Parameters from params
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
  # Parameters from params
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
  # Parameters from params
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
  # Parameters from params
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
  # Parameters from params
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
  # Parameters from params
  # order - the desired order, either ascending or descending, of the
  #         list by the criticality.
  #
  ######################################################################
  #
  def manager_list_by_priority
  
    @sort_order            = get_sort_order
    @sort_order[:priority] = params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order]     = @sort_order

    design_reviews = get_active_reviews
    @active_reviews   = design_reviews[:active].sort_by   { |dr| [dr[:review].priority.value, dr[:review].age] }
    @inactive_reviews = design_reviews[:inactive].sort_by { |dr| [dr[:review].priority.value, dr[:review].age] }
    @active_reviews.reverse!   if params[:order] == 'DESC'
    @inactive_reviews.reverse! if params[:order] == 'DESC'

    @submissions = BoardDesignEntry.submission_count
    session[:return_to] = {:controller => 'tracker',
                           :action => 'manager_list_by_priority',
                           :order  => params[:order]}
    render( :action => 'manager_home' )

  end  
  
  
  ######################################################################
  #
  # manager_list_by_design
  #
  # Description:
  # This method manages the ordering of the list by the design number.
  #
  # Parameters from params
  # order - the desired order, either ascending or descending, of the
  #         list by the design number.
  #
  ######################################################################
  #
  def manager_list_by_design
    
    @sort_order          = get_sort_order
    @sort_order[:design] = params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order]   = @sort_order
    
    design_reviews = get_active_reviews
    @active_reviews   = design_reviews[:active].sort_by   { |dr| dr[:review].design.pcb_display }
    @inactive_reviews = design_reviews[:inactive].sort_by { |dr| dr[:review].design.pcb_display }
    @active_reviews.reverse!   if params[:order] == 'DESC'
    @inactive_reviews.reverse! if params[:order] == 'DESC'
    
    @submissions = BoardDesignEntry.submission_count
    session[:return_to] = {:controller => 'tracker',
                           :action     => 'manager_list_by_design',
                           :order      => params[:order]}
    render( :action => 'manager_home')

  end  
  
  
  ######################################################################
  #
  # manager_list_by_type
  #
  # Description:
  # This method manages the ordering of the list by the design review
  # type.
  #
  # Parameters from params
  # order - the desired order, either ascending or descending, of the
  #         list by the design review type.
  #
  ######################################################################
  #
  def manager_list_by_type
    
    @sort_order        = get_sort_order
    @sort_order[:type] = params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order] = @sort_order
    
    design_reviews = get_active_reviews
    @active_reviews   = design_reviews[:active].sort_by   { |dr| [dr[:review].review_type.sort_order, dr[:review].age] }
    @inactive_reviews = design_reviews[:inactive].sort_by { |dr| [dr[:review].review_type.sort_order, dr[:review].age] }
    @active_reviews.reverse!   if params[:order] == 'DESC'
    @inactive_reviews.reverse! if params[:order] == 'DESC'
    
    @submissions = BoardDesignEntry.submission_count
    session[:return_to] = {:controller => 'tracker',
                           :action     => 'manager_list_by_type',
                           :order      => params[:order]}
    render( :action => 'manager_home' )

  end  
  
  
  ######################################################################
  #
  # manager_list_by_designer
  #
  # Description:
  # This method manages the ordering of the list by the designer.
  #
  # Parameters from params
  # order - the desired order, either ascending or descending, of the
  #         list by the designer.
  #
  ######################################################################
  #
  def manager_list_by_designer
    
    @sort_order            = get_sort_order
    @sort_order[:designer] = params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order]     = @sort_order
    
    design_reviews = get_active_reviews
    @active_reviews   = design_reviews[:active].sort_by   { |dr| [dr[:review].designer.last_name, dr[:review].age] }
    @inactive_reviews = design_reviews[:inactive].sort_by { |dr| [dr[:review].designer.last_name, dr[:review].age] }
    @active_reviews.reverse!   if params[:order] == 'DESC'
    @inactive_reviews.reverse! if params[:order] == 'DESC'
    
    @submissions = BoardDesignEntry.submission_count
    session[:return_to] = {:controller => 'tracker',
                           :action     => 'manager_list_by_designer',
                           :order      => params[:order]}
    render( :action => 'manager_home' )

  end  
  
  
  ######################################################################
  #
  # manager_list_by_peer
  #
  # Description:
  # This method manages the ordering of the list by the peer.
  #
  # Parameters from params
  # order - the desired order, either ascending or descending, of the
  #         list by the peer.
  #
  ######################################################################
  #
  def manager_list_by_peer
   
    @sort_order        = get_sort_order
    @sort_order[:peer] = params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order] = @sort_order
    
    design_reviews = get_active_reviews
    @active_reviews   = design_reviews[:active].sort_by   { |dr| [dr[:review].design.peer.last_name, dr[:review].age] }
    @inactive_reviews = design_reviews[:inactive].sort_by { |dr| [dr[:review].design.peer.last_name, dr[:review].age] }
    @active_reviews.reverse!   if params[:order] == 'DESC'
    @inactive_reviews.reverse! if params[:order] == 'DESC'
    
    @submissions = BoardDesignEntry.submission_count
    session[:return_to] = {:controller => 'tracker',
                           :action     => 'manager_list_by_peer',
                           :order      => params[:order]}
    render( :action => 'manager_home' )
    
  end  
  
  
  ######################################################################
  #
  # manager_list_by_age
  #
  # Description:
  # This method manages the ordering of the list by the age in work days.
  #
  # Parameters from params
  # order - the desired order, either ascending or descending, of the
  #         list by age in work days..
  #
  ######################################################################
  #
  def manager_list_by_age
    
    @sort_order        = get_sort_order
    @sort_order[:date] = params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order] = @sort_order
    
    design_reviews = get_active_reviews
    @active_reviews   = design_reviews[:active].sort_by   { |dr| [dr[:review].age, dr[:review].priority.value] }
    @inactive_reviews = design_reviews[:inactive].sort_by { |dr| [dr[:review].age, dr[:review].priority.value] }
    @active_reviews.reverse!   if params[:order] == 'DESC'
    @inactive_reviews.reverse! if params[:order] == 'DESC'
    
    @submissions = BoardDesignEntry.submission_count
    session[:return_to] = {:controller => 'tracker',
                           :action     => 'manager_list_by_age',
                           :order      => params[:order]}
    render( :action =>  'manager_home' )

  end  
  
  
  ######################################################################
  #
  # manager_list_by_status
  #
  # Description:
  # This method manages the ordering of the list by the design review
  # status.
  #
  # Parameters from params
  # order - the desired order, either ascending or descending, of the
  #         list by the design review status.
  #
  ######################################################################
  #
  def manager_list_by_status
    
    @sort_order          = get_sort_order
    @sort_order[:status] = params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order]   = @sort_order
    
    design_reviews = get_active_reviews
    @active_reviews   = design_reviews[:active].sort_by   { |dr| [dr[:review].review_status.name, dr[:review].age] }
    @inactive_reviews = design_reviews[:inactive].sort_by { |dr| [dr[:review].review_status.name, dr[:review].age] }
    @active_reviews.reverse!   if params[:order] == 'DESC'
    @inactive_reviews.reverse! if params[:order] == 'DESC'
    
    @submissions = BoardDesignEntry.submission_count
    session[:return_to] = {:controller => 'tracker',
                           :action     => 'manager_list_by_date',
                           :order      => params[:order]}
    render( :action => 'manager_home' )

  end  
  
  
  ######################################################################
  #
  # message_broadcast
  #
  # Description:
  # This method manages the ordering of the list by the design review
  # status.
  #
  # It is called both form the admin index (with no params)
  # and from deliver_broadcast_message with params if there is an error.
  #
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def message_broadcast

    @subject      = params[:subject] ? params[:subject] : 'IMPORTANT - Please Read'
    @message      = params[:message] ? params[:message] : ''
    @active_roles = Role.find_all_active
    # present the previously selected roles if any
    all_role_ids = []
    @active_roles.each do |role|
      all_role_ids << "#{role.id}"
    end
    @roles        = params[:roles] ? params[:roles] : all_role_ids
 
    end

  
  ######################################################################
  #
  # display_roles
  #
  # Description:
  # This method responds to an AJAX call to populate the roles table
  # on the message_broadcast view.
  #
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def display_roles
  
    @active_roles = Role.find_all_active
    
    render(:layout => false)
    
  end
  

  ######################################################################
  #
  # remove_roles
  #
  # Description:
  # This method responds to an AJAX call to remove the roles table
  # on the message_broadcast view.
  #
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def remove_roles
    render(:layout => false)
  end  


  ######################################################################
  #
  # deliver_broadcast_message
  #
  # Description:
  # This method verifies that the user provided all of the information
  # to generate a mail message.  If the information is complete the 
  # mail is sent.  If not, the message broadcast view is displayed with
  # the error message displayed.
  #
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def deliver_broadcast_message
    message = params[:mail][:message].strip
    recipients = []

    if message.size == 0     
      flash['notice'] = 'The mail message was not sent - there was no message'
      redirect_to(:action     => 'message_broadcast', 
                  :subject    => params[:mail][:subject],
                  :roles      => params[:roles])
    else
    
      if params[:all_users] == '1'

        recipients = User.find_all_by_active(1).collect { |u| u.email}

      else
        params[:roles].each do |role|
            recipients += Role.find(role).active_users.collect { |u| u.email }          
        end
      end
      
      if recipients.size > 0
        message += "\n\n" + recipients.join("\n")
        TrackerMailer::broadcast_message(params[:mail][:subject],
                                         message,
                                         recipients).deliver

        flash['notice'] = "The message has been sent#{params[:mail][:to]}"
        redirect_to(:controller => 'tracker', :action => 'index')
      else
        flash['notice'] = 'The mail message was not sent - no recipient roles were selected'
        redirect_to(:action  => 'message_broadcast', 
                    :subject    => params[:mail][:subject],
                    :message    => params[:mail][:message],
                    :roles      => params[:roles])
      end
    end
  
  end
  
  
  private
  
  
  ######################################################################
  #
  # get_sort_order
  #
  # Description:
  # This method attempts to retrieve the sort order from the session flash.
  # If it does not exist then a new empty hash is created
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
    if flash[:sort_order]
      return flash[:sort_order]
    else
      return Hash.new()
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
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def pcb_admin_home_setup
  
    @designer = {}

    release_review = ReviewType.get_release
    designs = Design.find_all_by_phase_id(release_review.id,
                                          'created_on ASC')

    designs = designs.sort_by { |dr| dr.priority.value }
        
    @design_list = []
    designs.each do |design|

      design_summary = {:design => design}

      reviews = design.design_reviews.sort_by{ |r| r.review_type.sort_order }

      # Go through the reviews until the first review that has not been
      # started is found.
      review_list     = []
	  reviews_started = 0
	  next_review     = nil

      reviews.each do |review|

        next_review = review

        
        break if review.review_status.name == 'Not Started'
        last_status = review.review_status.name
        
        reviews_started += 1

        review_rec = {:review => review}
        review_results = review.design_review_results
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

      audit = design.audit
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
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def designer_home_setup
    @designs = []
    mydesigns = Design.get_active_designs_owned_by(@logged_in_user) 
    mydesigns.each do | design |
      dsn = {}
      dsn[:design] = design
      current_phase          = ReviewType.find(design.phase_id)
      dsn[:next_review]      = design.design_reviews.detect{ |dr| dr.review_type_id == design.phase_id}
      design.design_reviews.delete_if do |dr| 
        (dr.review_status.name == "Not Started" || 
         dr.review_type.sort_order > current_phase.sort_order)
      end
      
      reviews = design.design_reviews.sort_by{ |dr| dr.review_type.sort_order }

      # Go through the reviews until the first review that has not been
      # started is found.\
      drs = []
      reviews.each do |design_review|
        dr = {}
        dr[:review] = design_review
        review_results            = design_review.design_review_results
        dr[:reviewers] = review_results.size
        review_results.delete_if { |dr1| dr1.result != 'APPROVED' && dr1.result != 'WAIVED' }
        dr[:approvals] = review_results.size
        drs << dr
      end
      dsn[:reviews] = drs
      @designs << dsn
    end

    #
    @audits = []
    # Get the self audits from the users designs
    mydesigns.each do | design |
      if design.audit.is_self_audit? && ! design.audit.is_complete? #completed_user?(@logged_in_user)
        @audits << { :audit => design.audit,
                     :priority => design.priority.value,
                     :self => true }
      end 
    end
    # Get the audits where the user is the assigned peer
    peer_designs = Design.find(:all,
                               :conditions => "peer_id=#{@logged_in_user.id}",
                               :include    => :audit)
    peer_designs.each do |peer_design|
      audit = peer_design.audit
      next if audit.is_complete? #completed_user?(@logged_in_user)
      @audits << { :audit    => audit, 'self' => false , 
                   :priority => audit.design.priority.value ,
                   :self     => false }
    end
     
    # Get the audits where the user is the member of an audit tm.
    my_audit_teams = AuditTeammate.find_all_by_user_id(@logged_in_user.id)
    my_audit_teams.each do |audit_team|
      audit = audit_team.audit
      next if audit.is_complete? 
      if audit.is_self_audit?
        audit.trim_checklist_for_self_audit
      else
        audit.trim_checklist_for_peer_audit
      end
      audit.get_design_checks
      audit.checklist.sections.each do | section |
        auditor = audit.auditor(section)? audit.auditor(section).name : " Not Assigned"
        next unless auditor == @logged_in_user.name
        section.subsections.each do | subsection |
          next if audit.is_self_audit? && subsection.completed_self_design_checks_percentage == 100
          next if audit.is_peer_audit? && subsection.completed_peer_design_checks_percentage == 100
          @audits << { :audit => audit, 
                       :priority => audit.design.priority.value,
                       :self => audit_team.self?  }
          end
      end
    end
    
    @audits = @audits.uniq.sort_by { |a| a[:priority] }
    ##
    #TODO: After reversing the values of priority so that the call to reverse is not
    #      needed make this a multi-level sort.
    #      audits.sort_by { |a| [a.design.priority.value, a.design.age] }
    
    # Get all of the active designs and determine if there are any work assignments
    # associated with the design for the user.
    @work_assignments = false
    @my_assignments   = {}    
    Design.find_all_active.each do |design|
      @work_assignments                 |= design.have_assignments(@logged_in_user.id)
      my_assignments                     = design.my_assignments(@logged_in_user.id)
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
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def reviewer_home_setup

    @my_processed_reviews      = DesignReview.my_processed_reviews(@logged_in_user)
    @my_unprocessed_reviews    = DesignReview.my_unprocessed_reviews(@logged_in_user)
    @reviews_assigned_to_peers = DesignReview.reviews_assigned_to_peers(@logged_in_user)

  end
  
  
  ######################################################################
  #
  # manager_home_setup
  #
  # Description:
  # This method gathers the information to display the Manager's 
  # home page.
  #
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def manager_home_setup

    @sort_order = {:priority => 'DESC'}
    @sort_order.default = 'ASC'
    flash[:sort_order] = @sort_order
      
    design_reviews = get_active_reviews

    # TODO: These sorts are expensive.  Make this faster.
    @active_reviews   = design_reviews[:active].sort_by   { |dr| [dr[:review].age] }.reverse
    @inactive_reviews = design_reviews[:inactive].sort_by { |dr| [dr[:review].priority.value, dr[:review].age] }

    @submissions = BoardDesignEntry.submission_count
    session[:return_to] = {:controller => 'tracker', :action => 'index'}

  end
 
  
  ######################################################################
  #
  # get_active_reviews
  #
  # Description:
  # This method retrieves all of the active design reviews.
  #
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def get_active_reviews

    design_reviews = []
    Design.find(:all,
                :conditions => "phase_id!=#{Design::COMPLETE}",
                :include    => :design_reviews).each do |design|

      next if design.phase_id == 0 
      design_review = design.design_reviews.detect { |dr| dr.review_type_id == design.phase_id }


      begin
        priority_name = design_review.priority.name
      rescue
        priority_name = 'Unset'
      end
      
      reviewers = 0
      approvals = 0
      if design.phase.name != "Planning"
      results = design_review.design_review_results.collect { |r| r.result }
        reviewers = results.size
        approvals = results.find_all { |r| 
                                     (r == DesignReviewResult::APPROVED ||
                                      r == DesignReviewResult::WAIVED) }.size
      end                           
      design_reviews << { :review => design_review, :priority_name => priority_name, 
                          :reviewers => reviewers, :approvals => approvals } 
    
    end
    
    lists = { :active => [], :inactive => [] }
    design_reviews.each do |design_review|
      if design_review[:review].review_status.name != 'Not Started'
        lists[:active] << design_review
      else
        lists[:inactive] << design_review
      end
    end

    return lists
    
  end
  

private

  def manager_setup
    @generate_role_links = true
    @pending_entries     = BoardDesignEntry.get_pending_entries(@logged_in_user) if @logged_in_user
  end
  

end
