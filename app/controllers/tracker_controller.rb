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
    
    if session[:active_role] != nil
      case session[:active_role].name
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
        # Use the default home page
      else
        reviewer_home_setup
        render( :action => 'reviewer_home' )
      end
    else
      # No user is identified.
      @designs = Design.get_active_designs#.sort_by { |d| d.part_number.pcba_name }
      @designs.delete_if { |d| d.part_number_id == 0 }
      @designs = @designs.sort_by { |d| d.part_number.pcba_name }
      
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
  
    @generate_role_links = true
    
    @sort_order            = get_sort_order
    @sort_order[:priority] = params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order]     = @sort_order

    design_reviews = get_active_reviews
    @active_reviews   = design_reviews[:active].sort_by   { |dr| [dr.priority.value, dr.age] }
    @inactive_reviews = design_reviews[:inactive].sort_by { |dr| [dr.priority.value, dr.age] }
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
    
    @generate_role_links = true
  
    @sort_order          = get_sort_order
    @sort_order[:design] = params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order]   = @sort_order
    
    design_reviews = get_active_reviews
    @active_reviews   = design_reviews[:active].sort_by   { |dr| dr.design.part_number.pcb_display_name }
    @inactive_reviews = design_reviews[:inactive].sort_by { |dr| dr.design.part_number.pcb_display_name }
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
    
    @generate_role_links = true
    
    @sort_order        = get_sort_order
    @sort_order[:type] = params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order] = @sort_order
    
    design_reviews = get_active_reviews
    @active_reviews   = design_reviews[:active].sort_by   { |dr| [dr.review_type.name, dr.age] }
    @inactive_reviews = design_reviews[:inactive].sort_by { |dr| [dr.review_type.name, dr.age] }
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
    
    @generate_role_links = true

    @sort_order            = get_sort_order
    @sort_order[:designer] = params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order]     = @sort_order
    
    design_reviews = get_active_reviews
    @active_reviews   = design_reviews[:active].sort_by   { |dr| [dr.designer.last_name, dr.age] }
    @inactive_reviews = design_reviews[:inactive].sort_by { |dr| [dr.designer.last_name, dr.age] }
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
    
    @generate_role_links = true
  
    @sort_order        = get_sort_order
    @sort_order[:peer] = params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order] = @sort_order
    
    design_reviews = get_active_reviews
    @active_reviews   = design_reviews[:active].sort_by   { |dr| [dr.design.peer.last_name, dr.age] }
    @inactive_reviews = design_reviews[:inactive].sort_by { |dr| [dr.design.peer.last_name, dr.age] }
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
    
    @generate_role_links = true
  
    @sort_order        = get_sort_order
    @sort_order[:date] = params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order] = @sort_order
    
    design_reviews = get_active_reviews
    @active_reviews   = design_reviews[:active].sort_by   { |dr| [dr.age, dr.priority.value] }
    @inactive_reviews = design_reviews[:inactive].sort_by { |dr| [dr.age, dr.priority.value] }
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
    
    @generate_role_links = true
  
    @sort_order          = get_sort_order
    @sort_order[:status] = params[:order] == 'ASC' ? 'DESC' : 'ASC'
    flash[:sort_order]   = @sort_order
    
    design_reviews = get_active_reviews
    @active_reviews   = design_reviews[:active].sort_by   { |dr| [dr.review_status.name, dr.age] }
    @inactive_reviews = design_reviews[:inactive].sort_by { |dr| [dr.review_status.name, dr.age] }
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
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def message_broadcast
  
    @subject      = params[:subject] ? params[:subject] : 'IMPORTANT - Please Read'
    @message      = params[:message] ? params[:message] : ''
    @active_roles = Role.find_all_active if params[:show_roles]
    
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
  
    if params[:mail][:message].strip.size == 0
    
      flash[:roles] = params[:roles]
      
      flash['notice'] = 'The mail message was not sent - there was no message'
      redirect_to(:action     => 'message_broadcast', 
                  :subject    => params[:mail][:subject],
                  :show_roles => params[:mail_to][:all_users] == '0')
    else
    
      if params[:mail_to][:all_users] == '1'
        recipients = User.find_all_by_active(1)
      else
        recipients = []
        params[:roles].each do |role|
          entry = role.to_a
          
          if entry[1] == '1'
            recipients += Role.find(entry[0]).active_users
          end
          
        end
      end
      
      if recipients.size > 0

        TrackerMailer::deliver_broadcast_message(params[:mail][:subject],
                                                 params[:mail][:message],
                                                 recipients)

        flash['notice'] = 'The message has been sent'
        redirect_to(:controller => 'tracker', :action => 'index')
      else
        flash['notice'] = 'The mail message was not sent - no recipient roles were selected'
        redirect_to(:action  => 'message_broadcast', 
                    :subject    => params[:mail][:subject],
                    :message    => params[:mail][:message],
                    :show_roles => true)
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
    if session['flash'][:sort_order]
      return session['flash'][:sort_order]
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

    @designs = Design.get_active_designs_owned_by(session[:user])       
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

    end

    audits = {}
    #
    # Get the audits where the user is the member of an audit team.
    # 
    my_audit_teams = AuditTeammate.find_all_by_user_id(session[:user].id)
    my_audit_teams.each do |audit_team|
      
      audit = audit_team.audit
      next if audit.is_peer_audit? & audit_team.self?
 
      audit[:self] = audit_team.self?
      audits[audit.id] = audit
      
    end
    
    #
    # Get the audits where the user is listed as the lead peer.
    # 
    # TODO Add a class method to Design - find_all_peer_designs(peer)
    peer_designs = Design.find(:all,
                               :conditions => "peer_id=#{session[:user].id}",
                               :include    => :audit,
                               :order      => 'created_on')

    peer_designs.each do |peer_design|
      audit = peer_design.audit
      next if ((audit.is_self_audit? && audits[audit.id]) || audit.is_complete?)
      audit[:self] = false
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
    Design.find_all_active.each do |design|
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
  # Parameters from params
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
    @active_reviews   = design_reviews[:active].sort_by   { |dr| [dr.priority.value, dr.age] }
    @inactive_reviews = design_reviews[:inactive].sort_by { |dr| [dr.priority.value, dr.age] }

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

#      design_review = DesignReview.find(design_review.id,
#                                        :include => [:priority, 
#                                                   #  :design,
#                                                   # :design_review_results,
#                                                     :review_status])

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
    
    lists = { :active => [], :inactive => [] }
    design_reviews.each do |design_review|
      if design_review.review_status.name != 'Not Started'
        lists[:active] << design_review
      else
        lists[:inactive] << design_review
      end
    end

    return lists
    
  end
  

end
