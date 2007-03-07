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


  ######################################################################
  #
  # view
  #
  # Description:
  # This method gathers the information for displaying a design review
  # and then renders the view based on the users' role.
  #
  # Parameters from params
  # ['id'] - The design review ID.
  #
  ######################################################################
  #
  def view

    session[:return_to] = {:controller => 'design_review',
                           :action     => 'view',
                           :id         => params[:id]}

    @design_review  = DesignReview.find(params[:id])
    @review_results = @design_review.review_results_by_role_name

    active_role = session[:active_role]
    if session[:active_role] && !active_role.reviewer?
    
      case session[:active_role].name
      when 'Designer'
        render_action('designer_view')
      when 'Manager'
        render_action('manager_view')
      when 'Admin'
        render_action('admin_view')
      else
        render_action('safe_view')
      end
      
    else

      if active_role && active_role.reviewer?
        
        @my_review_results = []
        @review_results.each do |review_result|
          @my_review_results << review_result if review_result.reviewer_id == session[:user].id
        end

        if pre_art_pcb(@design_review, @my_review_results)
          @designers  = Role.find_by_name("Designer").active_users
          @priorities = Priority.find_all(nil, 'value ASC')
        else
          @designers  = nil
          @priorities = nil
        end

        if (@my_review_results.find { |rr| rr.role.name == "SLM-Vendor"})
          design_fab_houses = {}
          @design_review.design.fab_houses.each { |dfh| design_fab_houses[dfh.id] = dfh }
          
          @fab_houses = FabHouse.get_all_active
          @fab_houses.each { |fh| fh[:selected] = design_fab_houses[fh.id] != nil }
        else
          @fab_houses = nil
        end

        render_action('reviewer_view')
      else
        render_action('safe_view')
      end
    end
  end
  
  
  ######################################################################
  #
  # safe_view
  #
  # Description:
  # This method redirects to the view action to display the appropriate
  # view.
  #
  # Parameters from params
  # ['id'] - The design review ID.
  #
  ######################################################################
  #
  def safe_view
    redirect_to(:action => 'view', :id => params[:id])
  end
  
  
  ######################################################################
  #
  # admin_view
  #
  # Description:
  # This method redirects to the view action to display the appropriate
  # view.
  #
  # Parameters from params
  # ['id'] - The design review ID.
  #
  ######################################################################
  #
  def admin_view
    redirect_to(:action => 'view', :id => params[:id])
  end
  
  
  ######################################################################
  #
  # manager_view
  #
  # Description:
  # This method redirects to the view action to display the appropriate
  # view.
  #
  # Parameters from params
  # ['id'] - The design review ID.
  #
  ######################################################################
  #
  def manager_view
    redirect_to(:action => 'view', :id => params[:id])
  end
  
  
  ######################################################################
  #
  # designer_view
  #
  # Description:
  # This method redirects to the view action to display the appropriate
  # view.
  #
  # Parameters from params
  # ['id'] - The design review ID.
  #
  ######################################################################
  #
  def designer_view
    redirect_to(:action => 'view', :id => params[:id])
  end
  
  
  ######################################################################
  #
  # reviewer_view
  #
  # Description:
  # This method redirects to the view action to display the appropriate
  # view.
  #
  # Parameters from params
  # ['id'] - The design review ID.
  #
  ######################################################################
  #
  def reviewer_view
    redirect_to(:action => 'view', :id => params[:id])
  end


  ######################################################################
  #
  # posting_filter
  #
  # Description:
  # This method redirects to the next method depending on the review type
  # that the user is posting.
  #
  # Parameters from params
  # ['design_id']      - Used to identify the design that the user is posting
  #                      the review for.
  # ['review_type_id'] - Used to identify the review type.
  #
  ######################################################################
  #
  def posting_filter

    review = ReviewType.find(params["review_type_id"])

    if review.name != 'Placement'
      redirect_to(:action         => 'post_review',
                  :design_id      => params["design_id"],
                  :review_type_id => params["review_type_id"])
    else
      flash[:design_id]      = params["design_id"]
      flash[:review_type_id] = params["review_type_id"]
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
  # Parameters from params
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
  # Parameters from params
  # None
  #
  ######################################################################
  #
  def process_placement_routing

    design_id = flash[:design_id]
    
    if params["combine"]["reviews"] == '1'
      
      design_reviews = DesignReview.find_all_by_design_id(design_id)
      placement_review = design_reviews.find { |dr| dr.review_type.name == 'Placement' }
      routing_review   = design_reviews.find { |dr| dr.review_type.name == 'Routing' }
      placement_results = placement_review.design_review_results
      
      routing_review.design_review_results.each do |routing_result|
       if !placement_results.detect { |pr| pr.role_id == routing_result.role_id }
         DesignReviewResult.new(
           :design_review_id => placement_review.id,
           :reviewer_id      => routing_result.reviewer_id,
           :role_id          => routing_result.role_id,
           :result           => routing_result.result,
           :reviewed_on      => routing_result.reviewed_on).create
       end
      end
    end

    redirect_to(:action                    => 'post_review',
                :combine_placement_routing => params["combine"]["reviews"],
                :design_id                 => design_id,
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
  # Parameters from params
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

    review_type    = ReviewType.find(params[:review_type_id])
    design_reviews = Design.find(params[:design_id]).design_reviews
    @design_review = design_reviews.detect { |dr| dr.review_type_id == review_type.id }

    # TODO: GET A DSR FOR THIS UPDATE
    @design_review.set_valor_reviewer  if @design_review.review_type.name == 'Final'
    @design_review.reload
       
    # Handle the combined Placement/Routing reviews
    if params[:combine_placement_routing] == '1'

      routing_review = ReviewType.find_by_name('Routing')
      
      @design_review.review_type_id_2 = routing_review.id
      @design_review.update

      # Remove the routing design review and review results for this design
      routing_review = design_reviews.detect { |dr| dr.review_type_id == routing_review.id }
      routing_review_results = 
        DesignReviewResult.delete_all("design_review_id=#{routing_review.id}")

      DesignReview.delete(routing_review.id) if routing_review_results

    end

    @reviewers = @design_review.generate_reviewer_selection_list

  end


  ######################################################################
  #
  # repost_review
  #
  # Description:
  # This method retrieves the design review and the reviewers to display for
  # posting.
  #
  # Parameters from params
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

    @design_review = DesignReview.find(params[:design_review_id])
    @reviewers     = @design_review.generate_reviewer_selection_list

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
  # Parameters from params
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

    design_review = DesignReview.find(params[:design_review][:id])
    current_time = Time.now

    # Set the status for the design review.
    in_review = ReviewStatus.find_by_name('In Review')
    design_review.review_status_id = in_review.id
    design_review.posting_count    = 1
    design_review.created_on       = current_time
    design_review.reposted_on      = current_time
    design_review.update

    reviewer_list = {}
    params[:board_reviewers].each { |role_id, reviewer_id|
      reviewer_list[role_id.to_i] = reviewer_id.to_i
    }

    pre_art_review = ReviewType.find_by_name('Pre-Artwork')
    
    if design_review.review_type.name == 'Pre-Artwork'
      design_review.design.board_design_entry.complete
    end

    design_review.design_review_results.each do |review_result|

      if reviewer_list[review_result.role_id] != review_result.reviewer_id
        review_result.reviewer_id = reviewer_list[review_result.role_id]
      end
      review_result.result      = 'No Response'
      review_result.reviewed_on = current_time
      review_result.update
      
      # Send an invitation to the reviewer if one has not been sent before
      reviewer = User.find(review_result.reviewer_id)
      if !reviewer.invited?
        TrackerMailer::deliver_tracker_invite(reviewer)

        reviewer.invited  = 1
        reviewer.password = ''
        reviewer.update
      end

      # Update the CC list.
      # Do not update the CC list for a Pre-Artwork review - it has already
      # been set when the design was created.
      if (design_review.review_type != pre_art_review &&
          review_result.role.cc_peers?)
        review_result.role.users.each do |peer|
          # Do not update the list for the following conditions.
          #    - peer is the reviewer
          #    - peer is not active
          #    - peer is already on the list
          if !(peer.id == review_result.reviewer_id or
               not peer.active?                     or
               design_review.design.board.users.include?(peer))
            design_review.design.board.users << peer
          end
        end
      end
    end
    

    # Store the comment if the designer entered one.
    if params[:post_comment][:comment] != ""
      DesignReviewComment.new(:comment          => params[:post_comment][:comment],
                              :user_id          => session[:user][:id],
                              :design_review_id => design_review.id).create
    end


    # Let everybody know that the design has been posted.
    TrackerMailer::deliver_design_review_posting_notification(design_review,
                                                              params[:post_comment][:comment])

    redirect_to(:action => 'index', :controller => 'tracker')

  end


  ######################################################################
  #
  # repost
  #
  # Description:
  # This method retrieves the design review and updates it with the posting
  # information.
  #
  # Parameters from params
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

    design_review  = DesignReview.find(params[:design_review][:id])

    # Set the status for the design review.
    in_review = ReviewStatus.find_by_name('In Review')
    design_review.review_status_id = in_review.id
    design_review.posting_count    += 1
    design_review.reposted_on      = Time.now
    design_review.update

    review_results = 
      design_review.design_review_results.delete_if { |rr| rr.result == 'WAIVED' }

    reviewer_list = {}
    params[:board_reviewers].each do |role_id, reviewer_id|
      reviewer_list[role_id.to_i] = reviewer_id.to_i
    end

    current_time = Time.now
    review_results.each do |review_result|

      if reviewer_list[review_result.role_id] != review_result.reviewer_id
        review_result.reviewer_id = reviewer_list[review_result.role_id]
      end
      review_result.result      = 'No Response'
      review_result.reviewed_on = current_time
      review_result.update
    end
    

    # Store the comment if the designer entered one.
    if params[:post_comment][:comment] != ""
      DesignReviewComment.new(:comment          => params[:post_comment][:comment],
                              :user_id          => session[:user][:id],
                              :design_review_id => design_review.id).create
    end

    # Let everybody know that the design has been posted.
    TrackerMailer::deliver_design_review_posting_notification(design_review,
                                                              params[:post_comment][:comment],
                                                              true)

    redirect_to(:action => 'index', :controller => 'tracker')

  end


  ######################################################################
  #
  # add_comment
  #
  # Description:
  # This method updates the database with the comment for the design review.
  #
  # Parameters from params
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

    if params[:post_comment][:comment] != ""
      DesignReviewComment.new(:comment          => params[:post_comment][:comment],
                              :user_id          => session[:user][:id],
                              :design_review_id => params[:design_review][:id]).create

      TrackerMailer::deliver_design_review_update(session[:user],
                                                  DesignReview.find(params[:design_review][:id]),
                                                  true)
    end

    flash['notice'] = "Comment added - mail has been sent"

    redirect_to(:action => :view, :id => params[:design_review][:id])

  end
  
  
  ######################################################################
  #
  # change_design_center
  #
  # Description:
  # This method gathers the data used to populate the change design 
  # center form.
  #
  # Parameters from params
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
    @design_centers = DesignCenter.get_all_active
    @design_review  = DesignReview.find(params[:design_review_id])
  end
  
  
  ######################################################################
  #
  # update_design_center
  #
  # Description:
  # This method the imput from the change design center form and updates
  # the database.
  #
  # Parameters from params
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
  
    design_review = DesignReview.find(params[:design_review][:id])

    changes = { }
    if (params[:design_center][:location] != "" &&
        params[:design_center][:location] != design_review.design_center_id.to_s)
      changes[:design_center] = { :old => design_review.design_center.name, 
                                  :new => DesignCenter.find(params[:design_center][:location]).name }
      end
      
    design_review.design_center_id = params[:design_center][:location]
    
    if design_review.update
      flash['notice'] = 'The design center has been updated.'
      
      create_comment(design_review, '', changes)

      TrackerMailer::deliver_design_review_modification(session[:user], design_review)

    else
      flash['notice'] = 'Error: The design center was not updated.'
    end
  
    redirect_to(:action => :view, :id => design_review.id)
  end
  
  


  ######################################################################
  #
  # review_attachments
  #
  # Description:
  # This method retrieves the design review and the documents associated with
  # the design review.
  #
  # Parameters from params
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
 
    @design_review = DesignReview.find(params[:design_review_id])
    document_types = DocumentType.find_all(nil, 'name ASC')

    @documents = []
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
  # Parameters from params
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
    @drd           = DesignReviewDocument.new
    @design_review = DesignReview.find(params[:design_review_id])
    @existing_drd  = DesignReviewDocument.find(params[:document_id])
    @document_type = DocumentType.find(@existing_drd.document_type_id)
  end
  
  
  ######################################################################
  #
  # save_update
  #
  # Description:
  # This method stores the document identified by the user.
  #
  # Parameters from params
  # [:document] - The document that will be stored.
  # [:design_review][:id] - Used to identify the design review.
  # [:doc_id] - Used to identify the document.
  # [:return_to] - Used to control the navigation.
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
                  :design_review_id => params[:design_review][:id],
                  :document_id      => params[:doc_id],
                  :return_to        => params[:return_to])
    elsif document.data.size >= Document::MAX_FILE_SIZE
      flash['notice'] = "Files must be smaller than #{Document::MAX_FILE_SIZE} characters"
      redirect_to(:action           => :update_documents,
                  :design_review_id => params[:design_review][:id],
                  :document_id      => params[:doc_id],
                  :return_to        => params[:return_to])
    else
      
      document.created_by       = session[:user].id
      
      if document.save
        
        design_review = DesignReview.find(params[:design_review][:id])
        board         = Board.find(design_review.design.board_id)
        existing_drd  = DesignReviewDocument.find(params[:doc_id])
        
        drd_doc.document_type_id = existing_drd.document_type_id
        drd_doc.board_id         = board.id
        drd_doc.design_id        = design_review.design_id
        drd_doc.document_id      = document.id
        drd_doc.save
        
        doc_type_name = DocumentType.find(drd_doc.document_type_id).name
        flash['notice'] = "The #{doc_type_name} document has been updated."
        if params[:return_to] == 'initial_attachments'
          redirect_to(:controller => 'design',
                      :action     => 'initial_attachments',
                      :design_id  => design_review.design_id)
        else
          redirect_to(:action           => :review_attachments,
                      :design_review_id => params[:design_review][:id])
        end
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
  # Parameters from params
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

    @document       = Document.new
    @document_types = DocumentType.find_all('active=1', 'name ASC')
    
    if params[:design_review] != nil
      design_review_id = params[:design_review][:id]
    else
      design_review_id = params[:design_review_id]
    end
   
   
    @design_review = DesignReview.find(design_review_id)
    @board = Board.find(params[:id])
    
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
  # Parameters from params
  # [:id] - Used to identify the board.
  # [:document_type][:id] - Identifies the type of document.
  # [:return_to] - Used to control navigation
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
    
    if params[:document_type][:id] == ''
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
      
        @document.created_by = session[:user].id

        if @document.save
          drd_doc = DesignReviewDocument.new
          
          drd_doc.document_type_id = params[:document_type][:id]
          drd_doc.board_id         = params[:board][:id]
          drd_doc.design_id        = DesignReview.find(params[:design_review][:id]).design_id
          drd_doc.document_id      = @document.id
          
          if drd_doc.save
          
            doc_type_name = DocumentType.find(drd_doc.document_type_id).name
            flash['notice'] = "File #{@document.name} (#{doc_type_name}) has been attached"
            save_failed = false
            
            TrackerMailer::deliver_attachment_update(drd_doc,
                                                     session[:user])
            
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
                  :id               => params[:id],
                  :design_review_id => params[:design_review][:id],
                  :return_to        => params[:return_to])
    elsif params[:return_to] == 'initial_attachments'
      redirect_to(:controller => 'design',
                  :action     => 'initial_attachments',
                  :design_id  => drd_doc.design_id)
    else
      redirect_to(:action           => :review_attachments,
                  :id               => params[:id],
                  :design_review_id => params[:design_review][:id])
    end
  end
  
  
  ######################################################################
  #
  # get_attachment
  #
  # Description:
  # This method retrieves the attachment selected by the user.
  #
  # Parameters from params
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
  rescue
  
   flash['notice'] = 'Can not retrieve the attachment without an ID'
   redirect_to(:controller => 'tracker', :action => 'index')
   
  end
  
  
  ######################################################################
  #
  # list_obsolete
  #
  # Description:
  # This method gathers the information to display a list of obsolete
  # documents.
  #
  # Parameters from params
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
  
    @design_review = DesignReview.find(params[:id])
    @docs = DesignReviewDocument.find_all("design_id='#{@design_review.design.id}' " +
                                          "and document_type_id='#{params[:document_type_id]}'")
                                          
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
  # Parameters from params
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

    @design_review = DesignReview.find(params[:design_review_id])
    @design        = @design_review.design

    # Grab the reviewer names, their functions and sort the list by the
    # reviewer's last name.
    reviewers = []
    @design_review.design_review_results.each do |review_result|
      reviewers.push({ :name      => review_result.reviewer.name,
                       :group     => review_result.role.name,
                       :last_name => review_result.reviewer.last_name,
                       :id        => review_result.reviewer_id })
    end
    @reviewers = reviewers.sort_by { |reviewer| reviewer[:last_name] }

    # Get all of the users who are in the CC list for the board.
    users_on_cc_list = []
    @design.board.users.each { |user| users_on_cc_list.push(user.id) }

    # Get all of the users, remove the reviewer names, and add the full name.
    users = User.find_all('active=1', 'last_name ASC')
    @reviewers.each { |reviewer| users.delete_if { |user| user.id == reviewer[:id] } }

    @users_copied     = []
    @users_not_copied = []
    users.each do |user|
      next if user.id == @design.designer_id
      if users_on_cc_list.include?(user.id)
        @users_copied.push(user)
      else
        @users_not_copied.push(user)
      end
    end
    
    details = {}
    details[:design]        = @design
    details[:design_review] = @design_review
    details[:reviewers]     = @reviewers
    details[:copied]        = @users_copied
    details[:not_copied]    = @users_not_copied
    details[:action]        = params[:action]
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
  # Parameters from params
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

    user = User.find(params[:id])

    # Update the database.
    details[:design].board.users << user
    
    # Update the history
    cc_list_history = CcListHistory.new
    cc_list_history.design_review_id = details[:design_review].id
    cc_list_history.user_id          = session[:user].id
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
    @action           = details[:action]
    
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
  # Parameters from params
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

    user = User.find(params[:id])

    # Update the database.
    details[:design].board.remove_users(user)
    
    # Update the history
    cc_list_history = CcListHistory.new
    cc_list_history.design_review_id = details[:design_review].id
    cc_list_history.user_id          = session[:user].id
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
    @action           = details[:action]

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
  # Parameters from params
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
    roles    = []
    params.each { |key, value|

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
      :comments         => params["post_comment"]["comment"],
      :design_review_id => params["design_review"]["id"],
      :roles            => roles,
      :priority         => params["priority"],
      :designer         => params["designer"],
      :peer             => params["peer"],
      :fab_houses       => params["fab_house"]
    }
    flash[:review_results] = review_results

    if roles .size == 0 && params["post_comment"]["comment"].strip == ""
      flash['notice'] = "No information was provided - no update was recorded"
      redirect_to(:action => 'view', :id => params["design_review"]["id"])
    elsif not rejected
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
  # Parameters from params
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def post_results

    ignore_rejection = params[:note] && params[:note] == 'ignore'

    review_results    = flash[:review_results]
    flash_msg         = ''
    fab_msg           = ''
    comment_update    = false
    review_complete   = false
    results_recorded  = 0
    result_update     = {}
    design_review     = DesignReview.find(review_results[:design_review_id])
    
    if review_results[:comments].size > 0
      dr_comment = DesignReviewComment.new
      dr_comment.comment          = review_results[:comments]
      dr_comment.user_id          = session[:user].id
      dr_comment.design_review_id = review_results[:design_review_id]
      dr_comment.create
      
      comment_update = true
    end

    # Check to see if the reviewer is PCB Design performing a Pre_Artwork review
    # Only the PCB Design Approval screen returns a non-nil value in
    # review_results[:priority].
    if (design_review.review_type.name == "Pre-Artwork" && review_results[:priority])
      results = post_pcb_design_results(design_review, review_results)
      design_review.reload
    end
    
    if review_results[:fab_houses]
      comment_update = post_fab_house_updates(design_review, review_results[:fab_houses])
    end

    if design_review.in_review?

      review_result_list = design_review.design_review_results

      rejection_entered = false
      review_results[:roles].each do |review_result|

        review_record = review_result_list.detect do |rr| 
          rr.role_id.to_s == review_result[:id]
        end

        if review_result[:result] != 'COMMENT' && review_record && !ignore_rejection
          review_record.result      = review_result[:result]
          review_record.reviewed_on = Time.now
          review_record.update
          results_recorded += 1

          result_update[review_record.role.name] = review_result[:result]

          rejection_entered = review_result[:result] == "REJECTED" || rejection_entered
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

      elsif review_results[:roles].size > 0

        # If all of the reviews have a positive response, the review is complete
        response = ['WITHDRAWN', 'No Response', 'REJECTED']
        outstanding_result = review_result_list.detect { |rr| response.include?(rr.result) }

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
    end
    
    if comment_update || (result_update && result_update.size > 0)
      TrackerMailer::deliver_design_review_update(session[:user], 
                                                  design_review,
                                                  comment_update,
                                                  result_update)
    end

    if review_complete
      TrackerMailer::deliver_design_review_complete_notification(design_review)
    end

    if results && !results[:success]
      flash_msg = results[:alternate_msg]
      flash_msg += " - Your comments have been recorded" if comment_update
    elsif (design_review.in_review? || design_review.review_complete?)
      updated    = comment_update || results || results_recorded > 0
      flash_msg  = 'Design Review updated with'  if updated
      flash_msg += ' comments'                   if comment_update
      flash_msg += ' and' if comment_update && results_recorded > 0
      flash_msg += ' the review result'     if results_recorded > 0
      flash_msg += 's'                      if results_recorded > 1
      flash_msg += ' ' + results[:alternate_msg]  if results
      flash_msg += ' ' + fab_msg                  if fab_msg != ''
      flash_msg += ' - mail was sent'
    else
      flash_msg  = "Design Review status is '#{design_review.review_status.name}': "
      if comment_update
        flash_msg += "comments were recorded and review results were discarded - mail was sent"
      else
        flash_msg += "the review results were discarded - no mail was sent"
      end
    end
    flash['notice'] = flash_msg
    
    redirect_to(:action => :view, :id => review_results[:design_review_id])
  end
  
  
  ######################################################################
  #
  # confirm_rejection
  #
  # Description:
  #
  # Parameters from params
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
    
    flash[:review_results] = review_results
    
    @design_review_id = review_results[:design_review_id]
    
  end


  ######################################################################
  #
  # reassign_reviewer
  #
  # Description:
  #
  # Parameters from params
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def reassign_reviewer

    review_results = DesignReviewResult.find_all_by_design_review_id(
                       params[:design_review_id])
    # Remove reviewer results if the reviewer has already completed the 
    # review. 
    review_results.delete_if { |rr| rr.complete? }

    @design_review_id = params[:design_review_id]
    @matching_roles = []
    for role in session[:roles]

      next if not role.reviewer?

      match = review_results.find { |rr| role.id == rr.role_id }
      if match
        if session[:user].id == match.reviewer_id
          peers = Role.find(match.role_id).users.delete_if { |u| u == session[:user] }
          peers.delete_if { |u| !u.active? }
          @matching_roles << { :design_review => match, :peers => peers }
        else
          @matching_roles << { :design_review => match }
        end
      end
    end

  end


  ######################################################################
  #
  # perform_ftp_notification
  #
  # Description:
  #   Creates the ftp notification that will be stored with the design 
  #   and sent to the interested parties.
  #
  # Parameters from params
  #   id - design identifier
  #
  ######################################################################
  #
  def perform_ftp_notification
  
    @design              = Design.find(params[:id])
    final_design_review  = @design.design_reviews.detect { |dr| dr.review_type.name == "Final" }
    @reviewers           = final_design_review.design_review_results.collect { |drr| User.find(drr.reviewer_id) }
    @divisions           = Division.find(:all, :conditions => "active=1")
    @design_centers      = DesignCenter.find(:all, :conditions => "active=1")
    @fab_houses          = FabHouse.find(:all, :conditions => "active=1")


    @ftp_notification = FtpNotification.new(:design_id => @design.id)

    if params[:division_id]
      @ftp_notification.division_id = params[:division_id].to_i
    elsif @design.board_design_entry
      @ftp_notification.division_id = @design.board_design_entry.division_id
    else
      @ftp_notification.division_id = 0
    end
    @ftp_notification.design_center_id = params[:design_center_id] ? params[:design_center_id].to_i : final_design_review.design_center_id
    if params[:vendor_id]
      @ftp_notification.fab_house_id = params[:vendor_id].to_i
    elsif @design.fab_houses.size > 0
      @ftp_notification.fab_house_id = @design.fab_houses[0].fab_house_id
    else
      @ftp_notification.fab_house_id = 0
    end
    
    @ftp_notification.assembly_bom_number = params[:assembly_bom_number] ? params[:assembly_bom_number] : ''
    @ftp_notification.revision_date       = params[:revision_date]       ? params[:revision_date]       : ''
    @ftp_notification.file_data           = params[:file_data]           ? params[:file_data]           : ''
    

    # Grab the reviewer names, their functions and sort the list by the
    # reviewer's last name.
    reviewers = []
    final_design_review.design_review_results.each do |review_result|
      reviewers.push({ :name      => review_result.reviewer.name,
                       :group     => review_result.role.name,
                       :last_name => review_result.reviewer.last_name,
                       :id        => review_result.reviewer_id })
    end
    @reviewers = reviewers.sort_by { |reviewer| reviewer[:last_name] }

    # Identify the unique members for the FTP Notification FTP list.
    if @design.board_design_entry
      ops_manager = @design.board_design_entry.board_design_entry_users.detect { |u| u.role.name == 'Operations Manager'}
    else
      flash['notice'] = "" if !flash['notice']
      flash['notice'] += "<br />WARNING: THE OPERATIONS MANAGER WAS NOT AUTOMATICALLY ADDED TO THE CC LIST"
    end
    ftp_cc_list = [User.find_by_login('ftpgrp'), User.find_by_login('cedftgrp')]
    ftp_cc_list << ops_manager.user if ops_manager
    ftp_cc_list.each { |cc| @design.board.users << cc if !@design.board.users.detect { |u| u.id == cc.id }}

    # Get all of the users who are in the CC list for the board.
    users_on_cc_list = []
    @design.board.users.each { |user| users_on_cc_list.push(user.id) }

    # Get all of the users, remove the reviewer names, and add the full name.
    users = User.find_all('active=1', 'last_name ASC')
    @reviewers.each { |reviewer| users.delete_if { |user| user.id == reviewer[:id] } }
    
    @users_copied     = []
    @users_not_copied = []
    users.each do |user|
      next if user.id == @design.designer_id
      if users_on_cc_list.include?(user.id)
        @users_copied.push(user)
      else
        @users_not_copied.push(user)
      end
    end
    
    details = {}
    details[:design]        = @design
    details[:design_review] = final_design_review
    details[:reviewers]     = @reviewers
    details[:copied]        = @users_copied
    details[:not_copied]    = @users_not_copied
    details[:action]        = params[:action]
    flash[:details]         = details

   end


  ######################################################################
  #
  # send_ftp_notification
  #
  # Description:
  #   Gathers the information for the ftp notification comment/message
  #
  # Parameters from params
  #   id - design review identifier
  #
  ######################################################################
  #
  def send_ftp_notification

    # Verify that all of the information has been provided before processing.
    if (params[:ftp_notification][:assembly_bom_number].strip == "" ||  
        params[:ftp_notification][:file_data].strip           == "" ||
        params[:ftp_notification][:revision_date].strip       == "" ||
        params[:ftp_notification][:fab_house_id]     == '0'         ||
        params[:ftp_notification][:division_id]      == '0'         ||
        params[:ftp_notification][:design_center_id] == '0')

      flash['notice'] = "Please provide all to the data requied for the FTP Notification.  The notification was not sent."
      redirect_to(:action              => "perform_ftp_notification", 
                  :id                  => params[:id],
                  :assembly_bom_number => params[:ftp_notification][:assembly_bom_number],
                  :file_data           => params[:ftp_notification][:file_data],
                  :revision_date       => params[:ftp_notification][:revision_date],
                  :division_id         => params[:ftp_notification][:division_id],
                  :design_center_id    => params[:ftp_notification][:design_center_id],
                  :vendor_id           => params[:ftp_notification][:fab_house_id])

    else

      design   = Design.find(params[:id])
      if !design.ftp_notification
      
        ftp_notification = FtpNotification.new(params[:ftp_notification])
        ftp_notification.design_id = design.id
        ftp_notification.create
        
        message  = "NO RESPONSE IS REQUIRED!\n"
        message += "NOTIFICATION THAT FILES HAVE BEEN FTP'D TO VENDOR FOR BOARD FABRICATION\n"
        message += "Date: " + Time.now.to_s + "\n"
        message += "Division: " + ftp_notification.division.name + "\n"
        message += "Assembly/BOM Number: " + ftp_notification.assembly_bom_number + "\n"
        message += "Design Files Located at: /hwnet/" + ftp_notification.design_center.pcb_path
        message += "/" + ftp_notification.design.name + "/public/\n"
        message += "Files Size, Date, and Name: " + ftp_notification.file_data + "\n"
        message += "Rev Date: " + ftp_notification.revision_date + "\n"
        message += "Vendor: " + ftp_notification.fab_house.name + "\n"
        
        TrackerMailer::deliver_ftp_notification(message, ftp_notification)

        # Save the FTP Notification in the design's final review.
        message += "\n\nThis notification was delivered to the following people.\n"
        message += " - all of the reviewers\n"
        design.board.users.each { |user| message += " - #{user.name}\n" }

        design_review = design.design_reviews.detect { |dr| dr.review_type.name == 'Final'}
        dr_comment = DesignReviewComment.new(:user_id          => session[:user][:id],
                                             :design_review_id => design_review.id,
                                             :highlight        => 1,
                                             :comment          => message).create
               
        
        flash['notice'] = "The FTP Notification has been sent"
      else
        flash['notice'] = "The FTP Notification has already been sent for this design.  " +
                          "The notification was not sent."
      end
        redirect_to(:controller => 'tracker', :action => 'index')
    end

  end


  ######################################################################
  #
  # update_review_assignments
  #
  # Description:
  #
  # Parameters from params
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def update_review_assignments

    design_review_id = params[:id]
    new_reviewers    = params[:user]
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
          is_reviewer = session[:user].id == design_review_result.reviewer_id
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
            TrackerMailer::deliver_reassign_design_review_to_peer(
                             session[:user],
                             peer,
                             designer,
                             design_review,
                             role)
          end
        end
      }
    end

    # Check to see if any "assign_to_self" box is check.
    params.each { |key, value|

      next if not key.include?("assign_to_self")
      next if value[session[:user].id.to_s] == 'no'

      role = Role.find(key.split('_')[1])
      design_review_result = DesignReviewResult.find_first("design_review_id='#{design_review_id}' and role_id='#{role.id}'")

      if design_review_result
        peer = User.find(design_review_result.reviewer_id)
        design_review_result.reviewer_id = session[:user].id
        design_review_result.update

        new_reviewer = session[:user].name
        if flash_msg == ''
          flash_msg = "You are assigned to the #{role.display_name} review"
        else
          flash_msg += " and you are assigned to the #{role.display_name} review"
        end

        TrackerMailer::deliver_reassign_design_review_from_peer(
                         session[:user],
                         peer,
                         designer,
                         design_review,
                         role)
      end

    }

    if flash_msg != ''
      flash['notice'] = flash_msg + ' - mail was sent'
    else
      flash['notice'] = 'Nothing selected - no assignments were made'
    end

    redirect_to(:action => :view, :id => design_review_id)

  end


  ######################################################################
  #
  # admin_update
  #
  # Description:
  # Gathers the data for the admin/manager update screen.
  #
  # Parameters from params
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def admin_update
    
    if session['flash'][:sort_order]
      session['flash'][:sort_order] = session['flash'][:sort_order]
    end
    
    @design_review = DesignReview.find(params[:id])
    
    @designers           = Role.find_by_name("Designer").active_users
    @peer_list           = @designers
    @pcb_input_gate_list = Role.find_by_name('PCB Input Gate').active_users
    @priorities          = Priority.find_all(nil, 'value ASC')
    @design_centers      = DesignCenter.get_all_active
    
    @review_statuses = []
    if @design_review.in_review? || @design_review.on_hold?
      @review_statuses << ReviewStatus.find_by_name('In Review')
      @review_statuses << ReviewStatus.find_by_name('Review On-Hold')
    end

    @pcb_input_gate    = @design_review.design.input_gate.name
    @pcb_input_gate_id = @design_review.design.pcb_input_id
    
    if @design_review.design.designer_id > 0
      @designer = @design_review.design.designer
    end

  end


  ######################################################################
  #
  # process_admin_update
  #
  # Description:
  # Updates the based on user input on the admin update screen.
  #
  # Parameters from params
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def process_admin_update

    if session['flash'][:sort_order]
      session['flash'][:sort_order] = session['flash'][:sort_order]
    end
    
    design_review  = DesignReview.find(params[:id])
    audit_skipped  = design_review.design.audit.skip?
    audit_complete = design_review.design.audit.is_complete?
    
    peer_id = params[:peer] ? params[:peer][:id] : design_review.design.peer_id

    if !params[:designer]

      for dsg_review in design_review.design.design_reviews
        dsg_review.design_center_id = params[:design_center][:id]
        dsg_review.update
      end

      flash['notice'] = "#{design_review.design.name} has been updated"
      if session[:return_to]
        redirect_to(session[:return_to])
      else
        redirect_to(:action => "index", :controller => "tracker" )
      end
   
    elsif (!audit_skipped  &&
           (params[:designer][:id] != peer_id  ||
            (params[:designer][:id] == '' &&
             peer_id                == '')))  ||
          audit_skipped 
          
      design = design_review.design

      # Keep track of the updates for the comment update
      changes = { }
      
      cc_list = []
      cc_list << design.designer.email if design.designer_id > 0
      cc_list << design.peer.email     if design.peer_id     > 0

      if (params[:priority][:id] != "" &&
          params[:priority][:id] != design.priority_id.to_s)
        changes[:priority] = { :old => design.priority.name, 
                               :new => Priority.find(params[:priority][:id]).name }
        design.priority_id = params[:priority][:id]
      end
      if (params[:design_center][:id] != "" &&
          params[:design_center][:id] != design_review.design_center_id.to_s)
        changes[:design_center] = { :old => design_review.design_center.name, 
                                    :new => DesignCenter.find(params[:design_center][:id]).name }
      end
      if (params[:designer]            &&
          params[:designer][:id] != "" &&
          params[:designer][:id] != design.designer_id.to_s)
        new_designer       = User.find(params[:designer][:id])
        changes[:designer] = { :old => design.designer.name, 
                               :new => new_designer.name }
        design.designer_id = new_designer.id
      end
      if (!audit_complete          && 
          !audit_skipped           &&
          params[:peer]            &&
          params[:peer][:id] != "" &&
          params[:peer][:id] != design.peer_id.to_s)
        new_peer       = User.find(params[:peer][:id])
        changes[:peer] = { :old => design.peer.name, 
                           :new => new_peer.name }
        design.peer_id = new_peer.id
      end
      
      design.update


      if (params[:review_status]            &&
          params[:review_status][:id] != "" &&
          params[:review_status][:id] != design_review.review_status_id.to_s)

        changes[:review_status] = { :old => design_review.review_status.name,
                                    :new => ReviewStatus.find(params[:review_status][:id]).name }

        on_hold = ReviewStatus.find_by_name('Review On-Hold')
        if params[:review_status][:id] == on_hold.id.to_s
          design_review.place_on_hold
        else
          design_review.remove_from_hold(params[:review_status][:id])
        end

      end
      
      # Update all design reviews that are not complete
      pre_art_review = ReviewType.find_by_name('Pre-Artwork')
      release_review = ReviewType.find_by_name('Release')
      design.design_reviews.each do |dr|
        if dr.review_status.name != 'Review Completed'
          if dr.review_type_id != pre_art_review.id
            if dr.review_type_id != release_review.id
              dr.designer_id = params[:designer][:id]
            end
          else
            if (params[:pcb_input_gate]            &&
                params[:pcb_input_gate][:id] != "" &&
                params[:pcb_input_gate][:id] != dr.designer_id.to_s)
              changes[:pcb_input_gate] = { :old => User.find(dr.designer_id).name, 
                                           :new => User.find(params[:pcb_input_gate][:id]).name }
              dr.designer_id         = params[:pcb_input_gate][:id]
              dr.design.pcb_input_id = params[:pcb_input_gate][:id]
              dr.design.update
              dr.design.reload
            end
            dr.designer_id = params[:pcb_input_gate][:id]
          end
          dr.priority_id = params[:priority][:id]
        end
        dr.design_center_id = params[:design_center][:id]
        dr.update

      end
     
      if changes.size > 0 || params[:post_comment][:comment].size > 0
        # Add a comment to the design review and send mail for the update
        create_comment(design_review, params[:post_comment][:comment], changes)

        TrackerMailer::deliver_design_review_modification(session[:user], 
                                                          design_review, 
                                                          cc_list)

        flash['notice'] = "#{design.name} has been updated - mail sent"
      end
      
      if session[:return_to]
        redirect_to(session[:return_to])
      else
        redirect_to(:action => "index", :controller => "tracker" )
      end
    else
      flash['notice'] = "The peer and the designer must be different - update not recorded"
      redirect_to(:action => "admin_update", :id => params[:id])
    end

  end


  ######################################################################
  #
  # get_review_result_details
  #
  # Description:
  # Retrieves the design review results for display.
  #
  # Parameters from params
  # id - the design review id
  #
  ######################################################################
  #
  def get_review_result_details
  
    @design_review   = DesignReview.find(params[:id])
    @design          = @design_review.design
    @review_results  = @design_review.review_results_by_role_name.dup
    @review_results.delete_if { |rr| rr.result == 'WAIVED' || rr.result == "APPROVED" }
    
    render(:layout => false)
    
  end 


  ######################################################################
  #
  # hide_review_result_details
  #
  # Description:
  # Empties out the area used by get_review_result_details() 
  #
  # Parameters from params
  # id - the design review id
  #
  ######################################################################
  #
  def hide_review_result_details
  
    @design_review = DesignReview.find(params[:id])
    @design        = @design_review.design
    
    render(:layout => false)
    
  end 


  ######################################################################
  #
  # skip_review
  #
  # Description:
  # Sets the design review to skipped and updates the phase of the design.
  #
  # Parameters from params
  # design_id - the design id
  #
  ######################################################################
  #
  def skip_review
  
    design = Design.find(params[:design_id])
    
    # Update the status of the review that is being skipped.
    skipped_review_status = ReviewStatus.find_by_name("Review Skipped")
    skipped_review = design.design_reviews.detect { |dr| 
                       dr.review_type_id == design.phase_id }
    skipped_review.review_status_id = skipped_review_status.id
    skipped_review.update
    
    # Set the phase of the design to the next non-skipped review.
    design.increment_review
    
    TrackerMailer::deliver_notify_design_review_skipped(skipped_review,
                                                        session)

    redirect_to(:controller => 'tracker', :action => 'index')
    
  end 


########################################################################
########################################################################
  private
########################################################################
########################################################################
  
  
  ######################################################################
  #
  # create_comment
  #
  # Description:
  # This method creates the comment for design review modifications made
  # by the managers and designers
  #
  # Parameters
  # design_review - the designer review that is being modified
  # post_comment  - the associated comment entered by the user
  # changes       - contains the modifications that were made to the 
  #                 design review
  #
  ######################################################################
  #
  def create_comment(design_review, post_comment, changes)
  
    msg = ''
    
    if changes[:designer]
      msg += "The Lead Designer was changed from #{changes[:designer][:old]} to #{changes[:designer][:new]}\n"
    end
    if changes[:peer]
      msg += "The Peer Auditor was changed from #{changes[:peer][:old]} to #{changes[:peer][:new]}\n"
    end
    if changes[:pcb_input_gate]
      msg += "The PCB Input Gate was changed from #{changes[:pcb_input_gate][:old]} to #{changes[:pcb_input_gate][:new]}\n"
    end
    if changes[:priority]
      msg += "The Criticality was changed from #{changes[:priority][:old]} to #{changes[:priority][:new]}\n"
    end
    if changes[:design_center]
      msg += "The Design Center was changed from #{changes[:design_center][:old]} to #{changes[:design_center][:new]}\n"
    end
    if changes[:review_status]
      msg += "The design review status was changed from #{changes[:review_status][:old]} to #{changes[:review_status][:new]}\n"
    end

    msg += "\n\n" + post_comment if post_comment.size > 0

    dr_comment = DesignReviewComment.new(:user_id          => session[:user][:id],
                                         :design_review_id => design_review.id,
                                         :highlight        => 1,
                                         :comment          => msg).create
  end
  
  
  ######################################################################
  #
  # pre_art_pcb
  #
  # Description:
  # This method determines if the design review is a Pre-Artwork design
  # review and if the role is PCB Design.
  # 
  # TODO: This should be moved to the design_review model
  #
  # Parameters
  # design_review  - the designer review
  # review_results - 
  #
  ######################################################################
  #
  def pre_art_pcb(design_review, review_results)
    return (review_results.find { |rr| rr.role.name == "PCB Design" } &&
            design_review.review_type.name == "Pre-Artwork")
  end


  ######################################################################
  #
  # post_fab_house_updates
  #
  # Description:
  # This method builds and stores the comment that is generated when
  # the fab houses are updated by SLM Vendor
  #
  # Parameters:
  # design_review  - the designer review that is being modified
  # fab_house_list - the list of fab_houses
  # 
  # Return Value:
  # A boolean that indicates that a comment was generated when true.
  #
  ######################################################################
  #
  def post_fab_house_updates(design_review, fab_house_list)
  
    comment_update = false
    
    # Check to see if the reviewer is an SLM-Vendor reviewer.
    # review_results[:fab_houses] will be non-nil.
    added   = ''
    removed = ''
    fab_house_list.each do |id, selected|

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
    end
    
    if added !=  '' || removed != ''
      fab_msg = 'Updated the fab houses '
        
      fab_msg += " - Added: #{added}"     if added   != ''
      fab_msg += " - Removed: #{removed}" if removed != ''
      
      dr_comment = DesignReviewComment.new(:comment          => fab_msg,
                                           :user_id          => session[:user].id,
                                           :design_review_id => design_review.id).create
      comment_update = true
    end
    
    comment_update
    
  end
  
  
  ######################################################################
  #
  # post_pcb_design_results
  #
  # Description:
  # This method builds and stores the comment that is generated when
  # PCB Design performs the Pre-Artwork design review.
  #
  # Parameters:
  # design_review  - the designer review that is being modified
  # review_results - the list of inputs provided by PCB Design for the
  #                  Pre-Artwork design review.
  # 
  # Return Value:
  # The message that will be loaded into flash['notice'] by the caller.
  #
  ######################################################################
  #
  def post_pcb_design_results(design_review, review_results)

    results = {:success       => true,
               :alternate_msg => 'The following updates have been made - '}

    audit_skipped = design_review.design.audit.skip?
    
    if !audit_skipped &&
       (review_results[:designer]["id"] == '' || 
        review_results[:peer]["id"] == '')
      results[:success]       = false
      results[:alternate_msg] = 'The Designer and Peer must be specified - results not recorded'
    elsif !audit_skipped &&
          (review_results[:designer]["id"] == 
           review_results[:peer]["id"])
      results[:success]       = false
      results[:alternate_msg] = 'The Designer and Peer must be different - results not recorded'
    elsif audit_skipped && review_results[:designer]["id"] == ''
      results[:success]       = false
      results[:alternate_msg] = 'The Designer must be specified - results not recorded'
    else

      designer = User.find(review_results[:designer]["id"])
      if !audit_skipped
        peer = User.find(review_results[:peer]["id"])
      else 
        peer = User.new
      end
      priority = Priority.find(review_results[:priority]["id"])

      design = design_review.design
      priority_update = design.priority_id != priority.id
      
      design.peer_id     = peer.id
      design.designer_id = designer.id
      design.priority_id = priority.id
      design.update

      for design_review in design.design_reviews
        design_review.priority_id = priority.id
        if (design_review.review_type.name != 'Release' &&
            design_review.review_type.name != 'Pre-Artwork')
          design_review.designer_id = designer.id
          design_review.design_center_id = designer.design_center_id
        end
        design_review.update
      end

      results[:alternate_msg] += "Criticality is #{priority.name}, " if priority_update
      results[:alternate_msg] += "the Designer is #{designer.name}"
      if !audit_skipped
        results[:alternate_msg] += " and the Peer is #{peer.name}"
      end

    end

    return results
    
  end
  
  

end
