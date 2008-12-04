########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_controller.rb
#
# This contains the logic that handles events from the outside world
# (user input), interacts with the design model, and displays the 
# appropriate view to the user.
#
# $Id$
#
########################################################################

class DesignController < ApplicationController

  before_filter(:verify_admin_role, 
                :except => [:design_review_reviewers,
                            :pcb_mechanical_comments, 
                            :process_reviewer_modifications,
                            :view])

  auto_complete_for :design, :name


  ######################################################################
  #
  # initial_cc_list
  #
  # Description:
  # Provides the data for the initial_cc_list view.
  #
  # Parameters from params
  # design_id - identifies the design
  #
  ######################################################################
  #
  def initial_cc_list

    @design = Design.find(params[:design_id])

    # Get the list of all of the reviewers from all of the reviews
    design_reviews = DesignReview.find_all_by_design_id(@design.id)

    reviewers = []
    for design_review in design_reviews
      review_results = DesignReviewResult.find_all_by_design_review_id(
                         design_review.id)

      for review_result in review_results

        next if reviewers.find{ |r| r[:group] == review_result.role.name }
        
        reviewer = User.find(review_result.reviewer_id)
        reviewer = {
          :name       => reviewer.name,
          :group      => review_result.role.name,
          :group_name => review_result.role.display_name,
          :last_name  => reviewer.last_name,
          :id         => reviewer.id
        }

        reviewers.push(reviewer)
      end
    end
    
    @reviewers = reviewers.sort_by { |r| r[:last_name] }
      
    # Get all of the users who are on the CC list for the board
    users_on_cc_list = []
    for user in @design.board.users
      users_on_cc_list.push(user.id)
    end

    # Get all of the active users.
    users = User.find(:all, :conditions=>'active=1', :order=>'last_name')
    @reviewers.each { |rvr| users.delete_if { |u| u.id == rvr[:id] } }

    @users_copied     = []
    @users_not_copied = []
    for u in users
      next if u.id == @design.designer_id
      if users_on_cc_list.include?(u.id)
        @users_copied.push(u)
      else
        @users_not_copied.push(u)
      end
    end

    flash[:details] = {:design     => @design,
                       :reviewers  => @reviewers,
                       :copied     => @users_copied,
                       :not_copied => @users_not_copied}
  end


  ######################################################################
  #
  # add_to_initial_cc_list
  #
  # Description:
  # This method responds when the users clicks on a name in the list of
  # names to be added to the CC list.  The database is updated to add the
  # user to the CC list and the view is refreshed to indicate that the 
  # change was made.
  #
  # Parameters from params
  # id - identifies the user to add to the CC list.
  #
  ######################################################################
  #
  def add_to_initial_cc_list

    details    = flash[:details]
    @reviewers = details[:reviewers]
    user       = User.find(params[:id])

    details[:design].board.users << user

    # Update the history
    if 1 == 2
    cc_list_history = CcListHistory.new
    cc_list_history.design_review_id = details[:design_review].id
    cc_list_history.user_id          = details[:user].id
    cc_list_history.addressee_id     = user.id
    cc_list_history.action           = 'Added'
    cc_list_history.save
    end

    # Update the display lists
    details[:not_copied].delete_if { |u| u.id == user.id }

    copied = details[:copied]
    user[:name] = user.name
    copied.push(user)
    details[:copied] = copied.sort_by { |u| u.last_name }

    @users_copied     = details[:copied]
    @users_not_copied = details[:not_copied]

    flash[:details] = details
    flash[:ack]     = "Added #{user.name} to the CC list"

    render(:layout=>false)
     
  end


  ######################################################################
  #
  # remove_from_initial_cc_list
  #
  # Description:
  # This method responds when the users clicks on a name in the list of
  # names to be removed from the CC list.  The database is updated to 
  # removea the user from the CC list and the view is refreshed to 
  # indicate that the change was made.
  #
  # Parameters from params
  # id - identifies the user to remove from the CC list.
  #
  ######################################################################
  #
  def remove_from_initial_cc_list

    details = flash[:details]
    @reviewers = details[:reviewers]
    user = User.find(params[:id])

    # Update the database
    details[:design].board.users.delete(user)

    # Update the history
    if 1 == 2
      # Deal with the cc_list_history
    end

    # Update the display lists
    details[:copied].delete_if { |u| u.id == user.id }

    not_copied  = details[:not_copied]
    user[:name] = user.name
    not_copied.push(user)
    details[:not_copied] = not_copied.sort_by { |u| u.last_name }

    @users_copied     = details[:copied]
    @users_not_copied = details[:not_copied]

    flash[:details] = details
    flash[:ack]     = "Removed #{user.name} from the CC list"

    render(:layout=>false)

  end


  ######################################################################
  #
  # initial_attachments
  #
  # Description:
  # Provides the data for the initial_attachments view.
  #
  # Parameters from params
  # design_id - identifies the design
  #
  ######################################################################
  #
  def initial_attachments

    # TODO: See review_attachments() in the design review controller.
    @design        = Design.find(params[:design_id])
    @pre_art       = ReviewType.get_pre_artwork
    @design_review = @design.design_reviews.detect { |dr| dr.review_type_id == @pre_art.id }
    
    @documents = []
    DocumentType.get_document_types.each do |doc_type|

      docs = DesignReviewDocument.find(:all,
                                       :conditions => "board_id='#{@design.board.id}' AND " +
                                                      "document_type_id='#{doc_type.id}'")
      next if docs.size == 0

      if doc_type.name != "Other"
        display_doc = docs.pop
      
        # Check against zero because document has been popped off
        display_doc[:multiple_docs] = (docs.size > 0)
        @documents.push(display_doc)
      else
        docs.sort_by { |drd| drd.document.name }
        docs.reverse!
        for display_doc in docs
          display_doc[:multiple_docs] = false
          @documents.push(display_doc)
        end
      end
    end
  end
  
  
  ######################################################################
  #
  # view
  #
  # Description:
  # Provides the data for the design view view.
  #
  # Parameters from params
  # id - identifies the design
  #
  ######################################################################
  #
  def view
  
    @design         = Design.find(params[:id])
    @design_reviews = @design.design_reviews.sort_by { |dr| dr.review_type.sort_order}
  
  end
  
  
  ######################################################################
  #
  # pcb_mechanical_comments
  #
  # Description:
  # Provides the data for the design pcb_mechanical_comments.
  #
  # Parameters from params
  # id - identifies the design
  #
  ######################################################################
  #
  def pcb_mechanical_comments

    @design    = Design.find(params[:id])
    @comments  = @design.comments_by_role("PCB Mechanical")

    render(:layout => false)
  
  end
  
  
  ######################################################################
  #
  # design_review_reviewers
  #
  # Description:
  # Gathers the data to provide the user with a view to change
  # the reviewers for a design's reviews.
  #
  # Parameters from params
  # id - identifies the design
  #
  ######################################################################
  #
  def design_review_reviewers
  
    @design         = Design.find(params[:id])
    @design_reviews = @design.design_reviews.sort_by { |dr| dr.review_type.sort_order } 
    @review_roles   = Role.get_review_roles + Role.get_manager_review_roles
    
    # Do not display a review role that is not set up to review the
    # design.
    @review_roles.delete_if { |r| @design.role_review_count(r) == 0 }
    
    @review_roles_locked    = []
    @review_roles.each_with_index do |r, i|
      @review_roles_locked[i] = @design.role_open_review_count(r) == 0
    end
    
  end
  
  
  ######################################################################
  #
  # process_reviewer_modifications
  #
  # Description:
  # Processes any changes that the user made on the 
  # design_review_reviewers screen.
  #
  # Parameters from params
  # id        - identifies the design
  # role_id_# - the role ids that are paired with user ids that
  #             identify the role reviewer.
  #
  ######################################################################
  #
  def process_reviewer_modifications

    design = Design.find(params[:id])
    
    updated_reviewers = false
    review_in_review  = nil
    params.each do |key, value|

      # Pass over any parameter keys not addressing the role id
      # or the user if the reviewer's user id is set to 0.
      next if !(key =~ /^role_id/) || (value == '0')
      
      new_reviewer = User.find(value)
      role         = Role.find(key.split('_')[2])

      if !design.is_role_reviewer?(role, new_reviewer)
        review_in_review = design.set_role_reviewer(role, new_reviewer, @logged_in_user)
        updated_reviewers = true
      end
      

    end
    
    flash["notice"] = ''
    if updated_reviewers
      flash["notice"]  = "The reviewer list has been modified"
      flash["notice"] += "<br />Mail has been sent to the #{review_in_review} reviewers impacted" if review_in_review
    end
    
    if design.inactive_reviewers?
      flash["notice"] += "<br />The names in red indicate that the user is inactive."
      redirect_to(:action => "design_review_reviewers", :id => design.id)
    else
      redirect_to(session[:return_to])
    end
    
  end

  
  ######################################################################
  #
  # list
  #
  # Description:
  # Provides a list active designs sorted by the part number
  #
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def list
    
    # Get all of the designs that are not complete.
    active_designs = Design.find_all_active
    
    # Detect if any designs do not have a part number every design in the 
    # list that does not have a part number
    no_part_number = active_designs.detect { |d| d.part_number_id == 0 }
    
    if no_part_number
      active_designs.delete_if { |d| d.part_number_id == 0 }
      flash['notice'] = "Designs exist that have no associated part number"
    end
    
    @active_designs = active_designs.sort_by { |d| d.directory_name }  
    
  end


  ######################################################################
  #
  # show
  #
  # Description:
  # Retrieves a design for display
  #
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def show
    @design = Design.find(params[:id])
  end


  ######################################################################
  #
  # convert_checklist_type
  #
  # Description:
  # Called when a user clicks a button on the show screen indicating
  # that the user wants to convert the audit (from full or partial or
  # partial to full).  Once the work is done the show screen is 
  # redisplayed.
  #
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def convert_checklist_type

    design = Design.find(params[:id])
    design.flip_design_type
    redirect_to(:action => "show", :id => design.id)
    
    flash['notice'] = 'The audit has been converted to a ' + design.audit_type +
                      ' audit'
    
  end


end
