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

  before_filter :verify_admin_role

  auto_complete_for :design, :name


  ######################################################################
  #
  # initial_cc_list
  #
  # Description:
  #
  #
  # Parameters from @params
  # design_id -
  #
  # Return value:
  # None
  #
  # Additional information:
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
    
    @reviewers = reviewers.sort_by { |reviewer| reviewer[:last_name] }
      
    # Get all of the users who are on the CC list for the board
    users_on_cc_list = []
    for user in @design.board.users
      users_on_cc_list.push(user.id)
    end

    # Get all of the active users.
    users = User.find_all('active=1', 'last_name ASC')
    for reviewer in @reviewers
      users.delete_if { |user| user.id == reviewer[:id] }
    end

    @users_copied     = []
    @users_not_copied = []
    for user in users
      next if user.id == @design.designer_id
      if users_on_cc_list.include?(user.id)
        @users_copied.push(user)
      else
        @users_not_copied.push(user)
      end
    end

    flash[:details] = {:design     => @design,
                       :reviewers  => @reviewers,
                       :copied     => @users_copied,
                       :not_copied => @users_not_copied}
  end


  def add_to_initial_cc_list

    details    = flash[:details]
    @reviewers = details[:reviewers]
    user       = User.find(@params[:id])

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


  def remove_from_initial_cc_list

    details = flash[:details]
    @reviewers = details[:reviewers]
    user = User.find(@params[:id])

    # Update the database
    details[:design].board.remove_users(user)

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


  def initial_attachments

    @design        = Design.find(params[:design_id])
    document_types = DocumentType.find_all(nil, 'name ASC')
    @pre_art       = ReviewType.find_by_name("Pre-Artwork")
    @design_review = @design.design_reviews.detect { |dr| dr.review_type_id == @pre_art.id }
    
    @documents = []
    for doc_type in document_types

      docs = DesignReviewDocument.find_all("board_id='#{@design.board.id}' " +
                                           " and document_type_id='#{doc_type.id}'")
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


end
