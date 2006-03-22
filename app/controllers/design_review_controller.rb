########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_review_controller.rb
#
# This contains the logic that handles events from the outside world
# (user input), interacts with the design review model, and displays the 
# appropriate view to the user.
#
# $Id$
#
########################################################################

class DesignReviewController < ApplicationController

  before_filter(:verify_manager_admin_privs,
                :only => [:process_admin_update])

  def view

    case @session[:active_role]
      when 'Designer'
        redirect_to(:action => :designer_view,  :id => @params[:id])
      when 'Manager'
        redirect_to(:action => :manager_view,   :id => @params[:id])
      when 'Admin'
        redirect_to(:action => :admin_view,     :id => @params[:id])
      when nil
        redirect_to(:action => :safe_view,      :id => @params[:id])
      else
        active_role = Role.find_by_name(@session[:active_role])
        reviewer_roles = Role.find_all(nil,'reviewer=1 and active=1')

        if reviewer_roles.include?(active_role)
          redirect_to(:action => :reviewer_view,  :id => @params[:id])
        else
          redirect_to(:action => :safe_view, :id => @params[:id])
        end
    end
    
  end


  ######################################################################
  #
  # admin_view
  #
  # Description:
  # This method retrieves the design review from the database for display.
  #
  # Parameters from @params
  # ['id'] - Used to identify the design review to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def admin_view

    @design_review = DesignReview.find(@params[:id])
    @design        = Design.find(@design_review.design_id)
    review_results = DesignReviewResult.find_all("design_review_id='#{@design_review.id}'")

    @review_results = review_results.sort_by { |review_result| 
      review_result.role.name
    }

    @comments = DesignReviewComment.find_all("design_review_id='#{@design_review.id}'",
                                             'created_on DESC')

  end


  ######################################################################
  #
  # manager_view
  #
  # Description:
  # This method retrieves the design review from the database for display.
  #
  # Parameters from @params
  # ['id'] - Used to identify the design review to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def manager_view

    session[:return_to] = {:controller => 'design_review',
                           :action     => 'view',
                           :id         => @params[:id]}
    @design_review = DesignReview.find(@params[:id])
    @design        = Design.find(@design_review.design_id)
    review_results = DesignReviewResult.find_all("design_review_id='#{@design_review.id}'")

    @review_results = review_results.sort_by { |review_result| 
      review_result.role.name
    }

    @comments = DesignReviewComment.find_all("design_review_id='#{@design_review.id}'",
                                             'created_on DESC')

  end


  ######################################################################
  #
  # safe_view
  #
  # Description:
  # This method retrieves the design review from the database for display.
  #
  # Parameters from @params
  # ['id'] - Used to identify the design review to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def safe_view

    @design_review = DesignReview.find(@params[:id])
    @design        = Design.find(@design_review.design_id)
    review_results = DesignReviewResult.find_all("design_review_id='#{@design_review.id}'")

    @review_results = review_results.sort_by { |review_result| 
      review_result.role.name
    }

    @comments = DesignReviewComment.find_all("design_review_id='#{@design_review.id}'",
                                             'created_on DESC')

  end


  ######################################################################
  #
  # designer_view
  #
  # Description:
  # This method retrieves the design review from the database for display.
  #
  # Parameters from @params
  # ['id'] - Used to identify the design review to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def designer_view

    @design_review = DesignReview.find(@params[:id])
    @design        = Design.find(@design_review.design_id)
    review_results = DesignReviewResult.find_all("design_review_id='#{@design_review.id}'")

    @review_results = review_results.sort_by { |review_result| 
      review_result.role.name
    }

    @comments = DesignReviewComment.find_all("design_review_id='#{@design_review.id}'",
                                             'created_on DESC')

  end


  ######################################################################
  #
  # reviewer_view
  #
  # Description:
  # This method retrieves the design review from the database for display.
  #
  # Parameters from @params
  # ['id'] - Used to identify the design review to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def reviewer_view

    session[:return_to] = {:controller => 'design_review',
                           :action     => 'view',
                           :id         => @params[:id]}
    @design_review = DesignReview.find(@params[:id])
    @design        = Design.find(@design_review.design_id)
    review_results = DesignReviewResult.find_all("design_review_id='#{@design_review.id}'")

    @review_results = review_results.sort_by { |review_result| 
      review_result.role.name
    }
    
    @my_review_results = Array.new
    for review_result in @review_results
      @my_review_results << review_result if review_result.reviewer_id == @session[:user].id
    end

    @comments = DesignReviewComment.find_all("design_review_id='#{@design_review.id}'",
                                             'created_on DESC')

    if pre_art_pcb(@design_review, @my_review_results)
      designers   = Role.find_by_name("Designer").users
      @designers  = designers.delete_if { |d| not d.active? }
      @priorities = Priority.find_all(nil, 'value ASC')
    else
      @designers  = nil
      @priorities = nil
    end

    if (@my_review_results.find { |rr| rr.role.name == "SLM-Vendor"})
      design_fab_house_list = @design.fab_houses
      design_fab_houses = {}
      for dfh in design_fab_house_list
        design_fab_houses[dfh.id] = dfh
      end
      @fab_houses = FabHouse.find_all(nil, 'name ASC')

      for fab_house in @fab_houses
        fab_house[:selected] = design_fab_houses[fab_house.id] != nil
      end
    else
      @fab_houses = nil
    end

  end


  ######################################################################
  #
  # posting_filter
  #
  # Description:
  # This method redirects to the next method depending on the review type
  # that the user is posting.
  #
  # Parameters from @params
  # ['design_id']      - Used to identify the design that the user is posting
  #                      the review for.
  # ['review_type_id'] - Used to identify the review type.
  #
  ######################################################################
  #
  def posting_filter

    review = ReviewType.find(@params["review_type_id"])

    if review.name != 'Placement'
      redirect_to(:action         => 'post_review',
                  :design_id      => @params["design_id"],
                  :review_type_id => @params["review_type_id"])
    else
      flash[:design_id]      = @params["design_id"]
      flash[:review_type_id] = @params["review_type_id"]
      redirect_to(:action => 'placement_routing_post')
    end

  end


  ######################################################################
  #
  # placement_routing_post
  #
  # Description:
  # This method refreshes the information in the flash prior to displaying the
  # Plaement Routing Review Posting form.
  #
  # Parameters from @params
  # None
  #
  ######################################################################
  #
  def placement_routing_post
    flash[:design_id]      = flash[:design_id]
    flash[:review_type_id] = flash[:review_type_id]
  end


  ######################################################################
  #
  # process_placement_routing
  #
  # Description:
  # This method refreshes the information in the flash prior to displaying the
  # Plaement Routing Review Posting form.
  #
  # Parameters from @params
  # None
  #
  ######################################################################
  #
  def process_placement_routing

    if @params["combine"]["reviews"] == '1'
      design_id = flash[:design_id]

      design_reviews = DesignReview.find_all_by_design_id(flash[:design_id])
      placement_review = design_reviews.find { |dr| dr.review_type.name == 'Placement' }
      routing_review   = design_reviews.find { |dr| dr.review_type.name == 'Routing' }

      placement_results = DesignReviewResult.find_all_by_design_review_id(
                            placement_review.id)
      routing_results   = DesignReviewResult.find_all_by_design_review_id(
                            routing_review.id)

      for routing_result in routing_results
       if !placement_results.find { |pr| pr.role_id == routing_result.role_id }
         new_placement_result = DesignReviewResult.new
         new_placement_result.design_review_id = placement_results[0].design_review_id
         new_placement_result.reviewer_id      = routing_result.reviewer_id
         new_placement_result.role_id          = routing_result.role_id
         new_placement_result.result           = routing_result.result
         new_placement_result.reviewed_on      = routing_result.reviewed_on
         new_placement_result.create
       end
      end
    end

    redirect_to(:action                    => 'post_review',
                :combine_placement_routing => @params["combine"]["reviews"],
                :design_id                 => flash[:design_id],
                :review_type_id            => flash[:review_type_id])
    
  end


  ######################################################################
  #
  # post_review
  #
  # Description:
  # This method retrieves the design reviews and the reviewers to display for
  # posting.
  #
  # Parameters from @params
  # ['id'] - Used to identify the design to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def post_review

    @design        = Design.find(@params[:design_id])
    design_reviews = DesignReview.find_all_by_design_id(@design.id)
    review_type    = ReviewType.find(@params[:review_type_id])
    @design_review = design_reviews.find { |dr|  dr.review_type_id == review_type.id }
    
    # Handle the combined Placement/Routing reviews
    if @params[:combine_placement_routing] == '1'

      routing_review = ReviewType.find_by_name 'Routing'
      
      @design_review.review_type_id_2 = routing_review.id
      @design_review.update

      # Remove the routing design review and review results for this design
      routing_review = design_reviews.find { |dr|
        dr.review_type_id == routing_review.id 
      }
      routing_review_results = 
        DesignReviewResult.delete_all("design_review_id=#{routing_review.id}")

      if routing_review_results
        DesignReview.delete(routing_review.id)
      end

    end

    review_results = DesignReviewResult.find_all_by_design_review_id(@design_review.id)
    group_ids = Array.new
    for review_result in review_results
      group_ids.push(review_result.role_id)
    end
                                                                      
    @reviewers = Design.get_reviewers(@design.board_id, group_ids)

  end


  ######################################################################
  #
  # repost_review
  #
  # Description:
  # This method retrieves the design review and the reviewers to display for
  # posting.
  #
  # Parameters from @params
  # ['id'] - Used to identify the design to be retrieved.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def repost_review

    @design_review = DesignReview.find(@params[:design_review_id])
    @design        = Design.find(@design_review.design_id)

    # Remove roles that are not appropriate for the review.
    roles = Role.find_all("reviewer=1 and active=1")
    
    review_results = DesignReviewResult.find_all_by_design_review_id(@design_review.id)
    group_ids = Array.new
    for review_result in review_results
      group_ids.push(review_result.role_id)
    end

    @reviewers = Design.get_reviewers(@design.board_id, group_ids)
    review_results = DesignReviewResult.find_all("design_review_id=#{@design_review.id}")

    for reviewer in @reviewers
      review_result = review_results.find { |rr| rr.role_id == reviewer[:group_id] }

      if review_result
        reviewer[:reviewer_id] = review_result.reviewer_id
      end
    end

    render_action 'post_review'

  end


  ######################################################################
  #
  # post
  #
  # Description:
  # This method retrieves the design review and updates it with the posting
  # information.
  #
  # Parameters from @params
  # ['id'] - Used to identify the design review to be retrieved.
  # [:post_comment] - The posting comment
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def post


    design_review = DesignReview.find(@params[:design_review][:id])

    # Set the status for the design review.
    in_review = ReviewStatus.find_by_name('In Review')
    design_review.review_status_id = in_review.id
    design_review.posting_count    = 1
    design_review.created_on       = Time.now
    design_review.reposted_on      = Time.now
    design_review.update

    review_results = DesignReviewResult.find_all("design_review_id='#{design_review.id}'")
    reviewer_list = Hash.new
    @params[:board_reviewers].each { |role_id, reviewer_id|
      reviewer_list[role_id.to_i] = reviewer_id.to_i
    }

    current_time = Time.now
    for review_result in review_results

      if reviewer_list[review_result.role_id] != review_result.reviewer_id
        review_result.reviewer_id = reviewer_list[review_result.role_id]
      end
      review_result.result      = 'No Response'
      review_result.reviewed_on = current_time
      review_result.update

      #Update the CC list.
      if review_result.role.cc_peers?
        cc_list = review_result.role.users
        for peer in cc_list
          # Do not update the list for the following conditions.
          #    - peer is the reviewer
          #    - peer is not active
          #    - peer is already on the list
          if (peer.id == review_result.reviewer_id or
              not peer.active?                     or
              design_review.design.board.users.include?(peer))
            next
          end
          design_review.design.board.users << peer
        end
      end
    end
    

    # Store the comment if the designer entered one.
    if @params[:post_comment][:comment] != ""
      dr_comment = DesignReviewComment.new
      dr_comment.comment = @params[:post_comment][:comment]
      dr_comment.user_id = @session[:user][:id]
      dr_comment.design_review_id = design_review.id
      dr_comment.create
    end


    # Let everybody know that the design has been posted.
    DesignReviewMailer::deliver_posting_notification(design_review,
                                                     @params[:post_comment][:comment])

    redirect_to(:action     => 'index',
                :controller => 'tracker')

  end


  ######################################################################
  #
  # repost
  #
  # Description:
  # This method retrieves the design review and updates it with the posting
  # information.
  #
  # Parameters from @params
  # ['id'] - Used to identify the design review to be retrieved.
  # [:post_comment] - The posting comment
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def repost

    design_review  = DesignReview.find(@params[:design_review][:id])

    # Set the status for the design review.
    in_review = ReviewStatus.find_by_name('In Review')
    design_review.review_status_id = in_review.id
    design_review.posting_count    += 1
    design_review.reposted_on      = Time.now
    design_review.update

    review_results = 
      DesignReviewResult.find_all("design_review_id='#{design_review.id}'" +
                                    " and result!='WAIVED'")
    reviewer_list = Hash.new
    @params[:board_reviewers].each { |role_id, reviewer_id|
      reviewer_list[role_id.to_i] = reviewer_id.to_i
    }

    current_time = Time.now
    for review_result in review_results

      if reviewer_list[review_result.role_id] != review_result.reviewer_id
        review_result.reviewer_id = reviewer_list[review_result.role_id]
      end
      review_result.result      = 'No Response'
      review_result.reviewed_on = current_time
      review_result.update
    end
    

    # Store the comment if the designer entered one.
    if @params[:post_comment][:comment] != ""
      dr_comment = DesignReviewComment.new
      dr_comment.comment = @params[:post_comment][:comment]
      dr_comment.user_id = @session[:user][:id]
      dr_comment.design_review_id = design_review.id
      dr_comment.create
    end

    # Let everybody know that the design has been posted.
    DesignReviewMailer::deliver_posting_notification(design_review,
                                                     @params[:post_comment][:comment],
                                                     true)


    redirect_to(:action     => 'index',
                :controller => 'tracker')

  end


  ######################################################################
  #
  # add_comment
  #
  # Description:
  # This method updates the database with the comment for the design review.
  #
  # Parameters from @params
  # [:design_review][:id] - Used to identify the design review.
  # [:post_comment] - The posting comment
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def add_comment

    if @params[:post_comment][:comment] != ""
      dr_comment = DesignReviewComment.new
      dr_comment.comment = @params[:post_comment][:comment]
      dr_comment.user_id = @session[:user][:id]
      dr_comment.design_review_id = @params[:design_review][:id]
      dr_comment.create

      DesignReviewMailer::deliver_update(@session[:user],
                                         DesignReview.find(@params[:design_review][:id]),
                                         true)
    end

    flash['notice'] = "Comment added - mail has been sent"

    redirect_to(:action => :view,
                :id     => @params[:design_review][:id])

  end
  
  
  ######################################################################
  #
  # change_design_center
  #
  # Description:
  # This method gathers the data used to populate the change design 
  # center form.
  #
  # Parameters from @params
  # [:design_review_id] - Used to identify the design review.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def change_design_center
    @design_centers = DesignCenter.find_all('active=1', 'name ASC')
    @design_review  = DesignReview.find(@params[:design_review_id])
  end
  
  
  ######################################################################
  #
  # update_design_center
  #
  # Description:
  # This method the imput from the change design center form and updates
  # the database.
  #
  # Parameters from @params
  # [:design_review][:id] - Used to identify the design review.
  # [:design_center][:location] - The design center ID of the new design
  #                               center.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def update_design_center
  
    design_review = DesignReview.find(@params[:design_review][:id])
    design_review.design_center_id = @params[:design_center][:location]
    
    if design_review.update
      flash['notice'] = 'The design center has been updated.'
    else
      flash['notice'] = 'Error: The design center was not updated.'
    end
  
    redirect_to(:action => :designer_view,
                :id     => design_review.id)
  end
  
  


  ######################################################################
  #
  # review_attachments
  #
  # Description:
  # This method retrieves the design review and the documents associated with
  # the design review.
  #
  # Parameters from @params
  # [:design_review_id] - Used to identify the design review.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def review_attachments
 
    @design_review = DesignReview.find(@params[:design_review_id])
    document_types = DocumentType.find_all(nil, 'name ASC')

    @documents = Array.new
    for doc_type in document_types
      docs = DesignReviewDocument.find_all("board_id='#{@design_review.design.board_id}' " +
                                           "and document_type_id='#{doc_type.id}'")
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
  # update_documents
  #
  # Description:
  # This method gathers the information to display update a document.
  #
  # Parameters from @params
  # [:design_review_id] - Used to identify the design review.
  # [:document_id] - Used to identify the document.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def update_documents
    @drd = DesignReviewDocument.new
    @design_review = DesignReview.find(@params[:design_review_id])
    @existing_drd  = DesignReviewDocument.find(@params[:document_id])
    @document_type = DocumentType.find(@existing_drd.document_type_id)
  end
  
  
  ######################################################################
  #
  # save_update
  #
  # Description:
  # This method stores the document identified by the user.
  #
  # Parameters from @params
  # [:document] - The document that will be stored.
  # [:design_review][:id] - Used to identify the design review.
  # [:doc_id] - Used to identify the document.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def save_update
  
    document = Document.new(params[:document])
    drd_doc  = DesignReviewDocument.new
    
    if document.name == ''
      flash['notice'] = 'No file was specified'
      redirect_to(:action           => :update_documents,
                  :design_review_id => @params[:design_review][:id],
                  :document_id      => @params[:doc_id])
    elsif document.data.size >= Document::MAX_FILE_SIZE
      flash['notice'] = "Files must be smaller than #{Document::MAX_FILE_SIZE} characters"
      redirect_to(:action           => :update_documents,
                  :design_review_id => @params[:design_review][:id],
                  :document_id      => @params[:doc_id])
    else
      
      document.created_by       = @session[:user].id
      
      if document.save
        
        design_review = DesignReview.find(@params[:design_review][:id])
        board         = Board.find(design_review.design.board_id)
        existing_drd  = DesignReviewDocument.find(@params[:doc_id])
        
        drd_doc.document_type_id = existing_drd.document_type_id
        drd_doc.board_id         = board.id
        drd_doc.design_id        = design_review.design_id
        drd_doc.document_id      = document.id
        drd_doc.save
        
        doc_type_name = DocumentType.find(drd_doc.document_type_id).name
        flash['notice'] = "The #{doc_type_name} document has been updated."
        redirect_to(:action           => :review_attachments,
                    :design_review_id => @params[:design_review][:id])
      end
    end
  end


  ######################################################################
  #
  # add_attachment
  #
  # Description:
  # This method retrieves the document types the board for adding an attachment
  #
  # Parameters from @params
  # [:id] - Used to identify the board.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def add_attachment

    @document = Document.new
    @document_types = DocumentType.find_all('active=1', 'name ASC')
    
    if @params[:design_review] != nil
      design_review_id = @params[:design_review][:id]
    else
      design_review_id = @params[:design_review_id]
    end
   
   
    @design_review = DesignReview.find(design_review_id)
    @board = Board.find(@params[:id])
    
    # Eliminate document types that are already attached.
    documents = DesignReviewDocument.find_all("design_id='#{@design_review.design_id}'")
    other = DocumentType.find_by_name('Other')

    for doc in documents
      next if doc.document_type_id == other.id
      @document_types.delete_if { |dt| dt.id == doc.document_type_id }
    end

  end


  ######################################################################
  #
  # save_attachment
  #
  # Description:
  # This method saves the attachment that the user selected.
  #
  # Parameters from @params
  # [:id] - Used to identify the board.
  # [:document_type][:id] - Identifies the type of document.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def save_attachment

    @document = Document.new(params[:document])
    
    if @params[:document_type][:id] == ''
      save_failed = true
      flash['notice'] = 'Please select the document type'
    elsif @document.name == ''
      save_failed = true
      flash['notice'] = 'No name provided - Please specify a document'
    elsif @document.data.size == 0
      save_failed = true
      flash['notice'] = 'Empty file - The document was not stored'
    else
      
      if @document.data.size < Document::MAX_FILE_SIZE
      
        @document.created_by       = @session[:user].id

        if @document.save
          drd_doc = DesignReviewDocument.new
          
          drd_doc.document_type_id = @params[:document_type][:id]
          drd_doc.board_id         = @params[:board][:id]
          drd_doc.design_id        = DesignReview.find(@params[:design_review][:id]).design_id
          drd_doc.document_id      = @document.id
          
          if drd_doc.save
          
            doc_type_name = DocumentType.find(drd_doc.document_type_id).name
            flash['notice'] = "File #{@document.name} (#{doc_type_name}) has been attached"
            save_failed = false
          else
            flash['notice'] = "Unable to attach the file."
          end
        else
        end
      else
        save_failed = true
        flash['notice'] = "Files must be smaller than #{Document::MAX_FILE_SIZE} characters"
      end
    end
    
    if save_failed
      redirect_to(:action           => :add_attachment,
                  :id               => @params[:id],
                  :design_review_id => @params[:design_review][:id])
    else
      redirect_to(:action           => :review_attachments,
                  :id               => @params[:id],
                  :design_review_id => @params[:design_review][:id])
    end
  end
  
  
  ######################################################################
  #
  # get_attachment
  #
  # Description:
  # This method retrieves the attachment selected by the user.
  #
  # Parameters from @params
  # [:design_review_id] - Used to identify the design review.
  # [:document_type][:id] - Identifies the type of document.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def get_attachment
    @document = Document.find(params[:id])

    send_data(@document.data.to_a.pack("H*"),
              :filename    => @document.name,
              :type        => @document.content_type,
              :disposition => "inline")
  end
  
  
  ######################################################################
  #
  # list_obsolete
  #
  # Description:
  # This method gathers the information to display a list of obsolete
  # documents.
  #
  # Parameters from @params
  # [:id] - Used to identify the design review.
  # [:document_type_id] - Identifies the type of document.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def list_obsolete
  
    @design_review = DesignReview.find(@params[:id])
    @docs = DesignReviewDocument.find_all("design_id='#{@design_review.design.id}' " +
                                          "and document_type_id='#{@params[:document_type_id]}'")
                                          
    @docs.sort_by { |drd| drd.document.created_on}
    @docs.reverse!
                              
    # Discard the last entry
    latest_doc = @docs.shift
    @document_type_name = DocumentType.find(latest_doc.document_type_id).name

  end


  ######################################################################
  #
  # review_mail_list
  #
  # Description:
  # This method gathers the information to the mail list information for the 
  # design review.
  #
  # Parameters from @params
  # [:design_review_id] - Used to identify the design review.
  # [:document_type][:id] - Identifies the type of document.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def review_mail_list

    @design_review = DesignReview.find(@params[:design_review_id])
    @design        = Design.find(@design_review.design_id)

    # Get the list of reviewers
    review_results = DesignReviewResult.find_all("design_review_id='#{@design_review.id}'")

    # Grab the reviewer names, their functions and sort the list by the
    # reviewer's last name.
    reviewers = Array.new
    for review_result in review_results
      reviewer = User.find(review_result.reviewer_id)
      reviewer = {
        :name      => reviewer.first_name + ' ' + reviewer.last_name,
        :group     => review_result.role.name,
        :last_name => reviewer.last_name,
        :id        => reviewer.id
      }
      
      reviewers.push(reviewer)

      @reviewers = reviewers.sort_by { |reviewer| reviewer[:last_name] }

    end

    # Get all of the users who are in the CC list for the board.
    users_copied = Board.find(@design.board_id).users
    users_on_cc_list = Array.new
    for user in users_copied
      users_on_cc_list.push(user.id)
    end


    # Get all of the users, remove the reviewer names, and add the full name.
    users = User.find_all('active=1', 'last_name ASC')
    for reviewer in @reviewers
      users.delete_if { |user| user.id == reviewer[:id] }
    end

    @users_copied     = Array.new
    @users_not_copied = Array.new
    for user in users

      next if user.id == @design.designer_id
      if users_on_cc_list.include?(user.id)
        @users_copied.push(user)
      else
        @users_not_copied.push(user)
      end
    end
    
    details = Hash.new
    details[:design]        = @design
    details[:design_review] = @design_review
    details[:reviewers]     = @reviewers
    details[:copied]        = @users_copied
    details[:not_copied]    = @users_not_copied
    flash[:details]         = details

  end


  ######################################################################
  #
  # add_to_list
  #
  # Description:
  # This method updates the CC list with the user that was selected to be
  # added.
  #
  # Parameters from @params
  # [:id] - Identifies the user to be added to the CC list.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def add_to_list

    details    = flash[:details]
    @reviewers = details[:reviewers]

    user = User.find(@params[:id])

    # Update the database.
    details[:design].board.users << user
    
    # Update the history
    cc_list_history = CcListHistory.new
    cc_list_history.design_review_id = details[:design_review].id
    cc_list_history.user_id          = @session[:user].id
    cc_list_history.addressee_id     = user.id
    cc_list_history.action           = 'Added'
    cc_list_history.save

    # Update the display lists.
    details[:not_copied].delete_if { |u| u.id == user.id }

    copied = details[:copied]
    user[:name] = user.first_name + ' ' + user.last_name
    copied.push(user)
    details[:copied] = copied.sort_by { |u| u.last_name }

    @users_copied     = details[:copied]
    @users_not_copied = details[:not_copied]
    
    flash[:details] = details
    flash[:ack]     = "Added #{user[:name]} to the CC list"

    render(:layout=>false)

  end


  ######################################################################
  #
  # remove_from_list
  #
  # Description:
  # This method updates the CC list with the user that was selected to be
  # removed.
  #
  # Parameters from @params
  # [:id] - Identifies the user to be removed from the CC list.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def remove_from_list
    
    details    = flash[:details]
    @reviewers = details[:reviewers]

    user = User.find(@params[:id])

    # Update the database.
    details[:design].board.remove_users(user)
    
    # Update the history
    cc_list_history = CcListHistory.new
    cc_list_history.design_review_id = details[:design_review].id
    cc_list_history.user_id          = @session[:user].id
    cc_list_history.addressee_id     = user.id
    cc_list_history.action           = 'Removed'
    cc_list_history.save

    # Update the display lists.
    details[:copied].delete_if { |u| u.id == user.id }

    not_copied = details[:not_copied]
    user[:name] = user.first_name + ' ' + user.last_name
    not_copied.push(user)
    details[:not_copied] = not_copied.sort_by { |u| u.last_name }

    @users_copied     = details[:copied]
    @users_not_copied = details[:not_copied]

    flash[:details] = details
    flash[:ack]     = "Removed #{user[:name]} from the CC list"

    render(:layout=>false)

  end
  
  
  ######################################################################
  #
  # reviewer_results
  #
  # Description:
  #
  # Parameters from @params
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def reviewer_results
  
    # Go through the results for each role and look for a rejection
    rejected = false
    roles    = Array.new
    @params.each { |key, value|

      if key.include?("role_id")
        result = value.to_a
        rejected = ((result[0][1] == "REJECTED") || rejected)
        
        # Save the results to store in flash
        roles << { :id                      => key.split('_')[2],
                   :design_review_result_id => result[0][0],
                   :result                  => result[0][1] }
      end
    }
    
    # Save the data in flash
    review_results = {
      :comments         => @params["post_comment"]["comment"],
      :design_review_id => @params["design_review"]["id"],
      :roles            => roles,
      :priority         => @params["priority"],
      :designer         => @params["designer"],
      :fab_houses       => @params["fab_house"]
    }
    flash[:review_results] = review_results

    if not rejected
      redirect_to(:action => :post_results)
    else
      redirect_to(:action => :confirm_rejection)
    end
  end
  
  
  ######################################################################
  #
  # post_results
  #
  # Description:
  #
  # Parameters from @params
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def post_results

    # TO be handled: an approval coming in after a rejection was received.
  
    review_results  = flash[:review_results]
    flash_msg       = ''
    comment_update  = false
    review_complete = false
    design_review   = DesignReview.find(review_results[:design_review_id])
    
    if review_results[:comments].size > 0
      dr_comment = DesignReviewComment.new
      dr_comment.comment          = review_results[:comments]
      dr_comment.user_id          = @session[:user].id
      dr_comment.design_review_id = review_results[:design_review_id]
      dr_comment.create
      
      flash_msg = "comments"
      comment_update = true
    end
    
    review_result_list = 
      DesignReviewResult.find_all("design_review_id='#{review_results[:design_review_id]}'")

    results_recorded  = 0
    rejection_entered = false
    result_update     = {}
    for review_result in review_results[:roles]

      review_record = review_result_list.find { |rr| 
        rr.role_id.to_s == review_result[:id]
      }
      
      if review_result[:result] != 'COMMENT' && review_record
        review_record.result      = review_result[:result]
        review_record.reviewed_on = Time.now
        review_record.update
        results_recorded += 1

        result_update[review_record.role.name] = review_result[:result]

        rejection_entered = review_result[:result] == "REJECTED" || rejection_entered
      end
      
    end

    # Check to see if the reviewer is PCB Design performing a Pre_Artwork review
    alternate_msg = ''
    if (review_results[:priority] && review_results[:designer])
      design = design_review.design

      # Get any review but a Pre-Artwork review to determin the existing
      # priority and designer.
      pre_art = ReviewType.find_by_name("Pre-Artwork")
      rev_i = 0
      0.upto(design.design_reviews.size-1) { |i|
        rev_i = i
        break if design.design_reviews[i].review_type_id != pre_art.id
      }

      designer_id     = design.design_reviews[rev_i].designer_id
      priority_id     = design.design_reviews[rev_i].priority_id
      designer_update = designer_id != review_results[:designer]["id"]
      priority_update = priority_id != review_results[:priority]["id"]

      if designer_update || priority_update
        for review in design.design_reviews
          
          if review.id == design_review.id
            design_review.priority_id = review_results[:priority]["id"] if priority_update
            next
          end
          
          if designer_update && review.id != design_review.id
            if review.review_type.name != "Release"
              review.designer_id      = review_results[:designer]["id"]
              review.design_center_id = User.find(review.designer_id).design_center.id
            end            
          end
          review.priority_id = review_results[:priority]["id"] if priority_update
          review.update
        end
      end

      if designer_update && priority_update
        alternate_msg = "Updated priority and designer for the remaining reviews "
      elsif designer_update
        alternate_msg = "Updated designer for the remaining reviews "
      elsif priority_update
        alternate_msg = "Updated priority for the remaining reviews "
      end
      
    end

    # Check to see if the reviewer is an SLM-Vendor reviewer.
    # review_results[:fab_houses] will be non-nil.
    added   = ''
    removed = ''
    if (review_results[:fab_houses])
      review_results[:fab_houses].each { |id, selected|

        fab_house = FabHouse.find(id)
        # Update the design
        design = design_review.design
        if selected == '0' && design.fab_houses.include?(fab_house)
          design.remove_fab_houses(fab_house)
          if removed == ''
            removed = fab_house.name
          else
            removed += ', ' + fab_house.name
          end
        elsif selected == '1' && !design.fab_houses.include?(fab_house)
          design.fab_houses << fab_house
          if added == ''
            added = fab_house.name
          else
            added += ', ' + fab_house.name
          end
        end
        
        # Update the board
        board = design.board
        if selected == '0' && board.fab_houses.include?(fab_house)
          board.remove_fab_houses(fab_house)
        elsif selected == '1' && !board.fab_houses.include?(fab_house)
          board.fab_houses << fab_house                                      
        end
      }

      if added !=  '' || removed != ''
        alternate_msg = 'Updated the fab houses '
        
        alternate_msg += " - Added: #{added}"     if added   != ''
        alternate_msg += " - Removed: #{removed}" if removed != ''
      
        dr_comment = DesignReviewComment.new
        dr_comment.comment          = alternate_msg
        dr_comment.user_id          = @session[:user].id
        dr_comment.design_review_id = review_results[:design_review_id]
        dr_comment.create
        comment_update = true
      else
        alternate_msg = ''
      end

    end

    # Go through the design review list and withdraw the approvals and set the 
    # status to "Pending Repost"
    if rejection_entered

      for review_result in review_result_list
        if review_result.result == "APPROVED"
          review_result.result = "WITHDRAWN"
          review_result.update
        end
      end

      pending_repost = ReviewStatus.find_by_name('Pending Repost')
      design_review.review_status_id = pending_repost.id
      design_review.update

    else
      # If all of the reviews have a positive response, the review is complete
      response = ['WITHDRAWN', 'No Response', 'REJECTED']
      outstanding_result = review_result_list.find { |rr| response.include?(rr.result) }

      if not outstanding_result
        review_completed = ReviewStatus.find_by_name('Review Completed')
        design_review.review_status_id = review_completed.id
        design_review.completed_on     = Time.now
        design_review.update
        review_complete = true

        # Check the design's designer and priority information against the 
        # next review, if there is one, and update the design record, if they
        # do not match.
        not_started = ReviewStatus.find_by_name("Not Started")
        design = Design.find(design_review.design_id)

        design_reviews = DesignReview.find_all_by_design_id(design.id)
        design_reviews = design_reviews.sort_by { |dr| dr.review_type.sort_order}

        for design_rvw in design_reviews
          if design_rvw.review_status.id == not_started.id
            next_design_review = design_rvw
            break
          end
        end

        if next_design_review
          design.designer_id = next_design_review.designer_id
          design.priority_id = next_design_review.priority_id
          design.phase_id    = next_design_review.review_type_id
        else
          design.phase_id = Design::COMPLETE
        end
        design.update
      end

    end

    if comment_update || result_update.size > 0
      DesignReviewMailer::deliver_update(@session[:user], 
                                         design_review,
                                         comment_update,
                                         result_update)
    end

    if review_complete
      DesignReviewMailer::deliver_review_complete_notification(@session[:user],
                                                               design_review)
    end

    flash_msg += ' and the '          if flash_msg != '' && results_recorded > 0
    flash_msg += ' the review result' if results_recorded > 0
    flash_msg += 's'                  if results_recorded > 1
    
    if flash_msg != ''
      flash_msg = 'Design Review updated with ' + flash_msg + alternate_msg + '- mail has been sent'
    elsif alternate_msg != ''
      flash_msg = alternate_msg
    else
      flash_msg = 'No information provided - database was not updated'
    end
    flash['notice'] = flash_msg
    
    redirect_to(:action => :reviewer_view,
                :id     => review_results[:design_review_id])
  end
  
  
  ######################################################################
  #
  # confirm_rejection
  #
  # Description:
  #
  # Parameters from @params
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def confirm_rejection
  
    review_results = flash[:review_results]    
    review_results.each { |k,v|
      if k != :roles
        logger.info "  #{k} -> #{v}"
      else
        for role in v
        logger.info "  ROLE ID: #{role[:id]}  DESIGN REVIEW RESULT ID: #{role[:design_review_result_id]}  RESULT: #{role[:result]}}" 
        end
      end
    }
    
    logger.info "-----------------------------------------------------"
    flash[:review_results] = review_results
    
    @design_review_id = review_results[:design_review_id]
    
  end


  ######################################################################
  #
  # reassign_reviewer
  #
  # Description:
  #
  # Parameters from @params
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def reassign_reviewer

    review_results = DesignReviewResult.find_all("design_review_id=#{@params[:design_review_id]}")

    @design_review_id = @params[:design_review_id]
    @matching_roles = Array.new
    for role in @session[:roles]

      next if not role.reviewer?

      match = review_results.find { |rr| role.id == rr.role_id }
      if match
        if @session[:user].id == match.reviewer_id
          peers = Role.find(match.role_id).users.delete_if { |u| u == @session[:user] }
          peers.delete_if { |u| u.active == 0 }
          @matching_roles << { 
            :design_review => match,
            :peers         => peers
          }
        else
          @matching_roles << { :design_review => match }
        end
      end
    end

  end


  ######################################################################
  #
  # update_review_assignments
  #
  # Description:
  #
  # Parameters from @params
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def update_review_assignments

    design_review_id = @params[:id]
    new_reviewers    = @params[:user]
    design_review    = DesignReview.find(design_review_id)
    designer         = User.find(design_review.designer_id)
    flash_msg        = ''

    if new_reviewers
      # Reassign the review to the new reviewer
      new_reviewers.each { |role_name, user_id|
        next if user_id == ''
        role = Role.find_by_name(role_name)
        design_review_result = DesignReviewResult.find_first("design_review_id='#{design_review_id}' and reviewer_id='#{session[:user].id}' and role_id='#{role.id}'")

        if design_review_result
          is_reviewer = @session[:user].id == design_review_result.reviewer_id
          design_review_result.reviewer_id = user_id
          design_review_result.update
          peer         = User.find(user_id)
          new_reviewer = peer.name
          if flash_msg == ''
            flash_msg = "#{new_reviewer} is assigned to the #{role_name} review"
          else
            flash_msg += " and #{new_reviewer} is assigned to the #{role_name} review"
          end

          if is_reviewer
            ReviewReassignment::deliver_reassign_to_peer(@session[:user],
                                                         peer,
                                                         designer,
                                                         design_review.design,
                                                         role)
          end
        end
      }
    end

    # Check to see if any "assign_to_self" box is check.
    @params.each { |key, value|

      next if not key.include?("assign_to_self")
      next if value[@session[:user].id.to_s] == 'no'

      role = Role.find(key.split('_').shift)
      design_review_result = DesignReviewResult.find_first("design_review_id='#{design_review_id}' and role_id='#{role.id}'")

      if design_review_result
        peer = User.find(design_review_result.reviewer_id)
        design_review_result.reviewer_id = @session[:user].id
        design_review_result.update

        new_reviewer = session[:user].name
        if flash_msg == ''
          flash_msg = "You are assigned to the #{role.name} review"
        else
          flash_msg += " and you are assigned to the #{role.name} review"
        end

        ReviewReassignment::deliver_reassign_from_peer(@session[:user],
                                                       peer,
                                                       designer,
                                                       design_review.design,
                                                       role)
      end

    }

    if flash_msg != ''
      flash['notice'] = flash_msg + ' - mail was sent'
    else
      flash['notice'] = 'Nothing selected - no assignments were made'
    end

    redirect_to(:action => :reviewer_view,
                :id     => design_review_id)

  end


  ######################################################################
  #
  # admin_update
  #
  # Description:
  # Gathers the data for the admin/manager update screen.
  #
  # Parameters from @params
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def admin_update
    
    if @session['flash'][:sort_order]
      @session['flash'][:sort_order] = @session['flash'][:sort_order]
    end
    
    @design_review = DesignReview.find(@params[:id])
    
    designer_role        = Role.find_by_name("Designer")
    @designers           = designer_role.users.delete_if { |d| !d.active }
    @peer_list           = @designers
    @pcb_input_gate_list = Role.find_by_name('PCB Input Gate').users.delete_if { |u| !u.active }
    @priorities          = Priority.find_all(nil, 'value ASC')
    @design_centers      = DesignCenter.find_all('active=1', 'name ASC')

    pre_art_review_type = ReviewType.find_by_name('Pre-Artwork')
    design_reviews      = @design_review.design.design_reviews

    pre_art_review = 
      design_reviews.detect { |dr| dr.review_type_id == pre_art_review_type.id}

    @pcb_input_gate = User.find(pre_art_review.designer_id).name
    @pcb_input_gate_id = pre_art_review.designer_id

    if @design_review.design.phase_id != Design::COMPLETE

      # Determine the phase
      phase = ReviewType.find(@design_review.design.phase_id)

      if 'Pre-Artwork' != phase.name
        @designer = User.find(@design_review.designer_id)
      else
        reviews = design_reviews.sort_by { |dr| dr.review_type.sort_order }
        for review in reviews
          next if review.review_type.name == 'Pre-Artwork'
          break if review.review_status.name != 'Review_Completed'
        end
        @designer = User.find(review.designer_id)
      end
    end 
  end


  ######################################################################
  #
  # process_admin_update
  #
  # Description:
  # Updates the based on user input on the admin update screen.
  #
  # Parameters from @params
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def process_admin_update

    if @session['flash'][:sort_order]
      @session['flash'][:sort_order] = @session['flash'][:sort_order]
    end
    
    design_review = DesignReview.find(params[:id])

    if !params[:designer]

      for dsg_review in design_review.design.design_reviews
        dsg_review.design_center_id = params[:design_center][:id]
        dsg_review.update
      end

      flash['notice'] = "#{design_review.design.name} has been updated"
      if @session[:return_to]
        redirect_to(@session[:return_to])
      else
        redirect_to(:action => "index", :controller => "tracker" )
      end
    elsif params[:designer][:id] != params[:peer][:id]
      
      # Update the design reord
      design = design_review.design
      design.designer_id = params[:designer][:id]
      design.peer_id     = params[:peer][:id]
      design.priority_id = params[:priority][:id]
      design.update

      # Update all design reviews that are not complete
      pre_art_review = ReviewType.find_by_name('Pre-Artwork')
      release_review = ReviewType.find_by_name('Release')
      for design_review in design.design_reviews
        if design_review.review_status.name != 'Review Completed'
          if design_review.review_type_id != pre_art_review.id
            if design_review.review_type_id != release_review.id
              design_review.designer_id = params[:designer][:id]
            end
          else
            design_review.designer_id = params[:pcb_input_gate][:id]
          end
          design_review.priority_id      = params[:priority][:id]
        end
        design_review.design_center_id = params[:design_center][:id]
        design_review.update

        if design.phase_id == design_review.review_type_id
          design.designer_id = design_review.designer_id
          design.update
        end
      end

      flash['notice'] = "#{design.name} has been updated"
      if @session[:return_to]
        redirect_to(@session[:return_to])
      else
        redirect_to(:action => "index", :controller => "tracker" )
      end
    else
      flash['notice'] = "The peer and the designer must be different - update not recorded"
      redirect_to(:action => "admin_update", :id => params[:id])
    end
  end


  def dump_design_review_info

    @design = Design.find(40)
    @design_reviews = DesignReview.find_all_by_design_id(@design.id)
    @design_reviews = @design_reviews.sort_by { |dr| dr.review_type.sort_order }

    for design_review in @design_reviews
      design_review[:result] = DesignReviewResult.find_all_by_design_review_id(design_review.id)
    end

  end


  private


  def pre_art_pcb(design_review, review_results)
    return (review_results.find { |rr| rr.role.name == "PCB Design" } &&
            design_review.review_type.name == "Pre-Artwork")
  end
  
  

end
