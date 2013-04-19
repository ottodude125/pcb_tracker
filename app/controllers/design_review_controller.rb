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
  # index
  #
  # Description:
  # A null stub to prevent an error message
  #
  ######################################################################
  #
  def index
      flash['notice'] = "No ID was provided - unable to access the design review"
      redirect_to(:controller => 'tracker', :action => 'index')
  end

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

    if params[:id]

      @design_review  = DesignReview.find(params[:id])
      @brd_dsn_entry  = BoardDesignEntry.find(:first,
        :conditions => "design_id='#{@design_review.design_id}'")
      @review_results = @design_review.review_results_by_role_name

      if @logged_in_user && @logged_in_user.is_reviewer?
        
        @my_review_results = []
        @review_results.each do |review_result|
          @my_review_results << review_result if review_result.reviewer_id == @logged_in_user.id
        end

        if pre_art_pcb(@design_review, @my_review_results)
          @designers  = Role.find_by_name("Designer").active_users
          @priorities = Priority.get_priorities
        else
          @designers  = nil
          @priorities = nil
        end

        if (@my_review_results.find { |rr| rr.role.name == "SLM-Vendor"})
          @design_fab_houses = {}
          @design_review.design.fab_houses.each { |dfh| @design_fab_houses[dfh.id] = dfh }
          
          @fab_houses = FabHouse.get_all_active

          #@fab_houses.each { |fh| fh[:selected] = design_fab_houses[fh.id] != nil }
        else
          @fab_houses = nil
        end

      end
    @review_type = ReviewType.find_by_id(@design_review.review_type_id)
    
    else

      flash['notice'] = "No ID was provided - unable to access the design review"
      redirect_to(:controller => 'tracker', :action => 'index')

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
  # Parameters from params
  # ['design_id']      - Used to identify the design that the user is posting
  #                      the review for.
  # ['review_type_id'] - Used to identify the review type.
  #
  ######################################################################
  #
  def posting_filter
x
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
z
    design_id = flash[:design_id]
    
    if params["combine"]["reviews"] == '1'

      design_reviews = DesignReview.find_all_by_design_id(design_id)
      placement_review = design_reviews.find { |dr| dr.review_type.name == 'Placement' }
      routing_review   = design_reviews.find { |dr| dr.review_type.name == 'Routing' }
      placement_results = placement_review.design_review_results

      #if there are routing reviews, create new review results based on them.
      if routing_review
        routing_review.design_review_results.each do |routing_result|
          if !placement_results.detect { |pr| pr.role_id == routing_result.role_id }
            DesignReviewResult.new(
              :design_review_id => placement_review.id,
              :reviewer_id      => routing_result.reviewer_id,
              :role_id          => routing_result.role_id,
              :result           => routing_result.result,
              :reviewed_on      => routing_result.reviewed_on).save
          end
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

    flash['notice'] = "Can't Post a design if it is on hold" if @design_review.on_hold?
    
    # Handle the combined Placement/Routing reviews    
    if params[:combine_placement_routing] == '1'

      routing_review = ReviewType.get_routing
      
      @design_review.review_type_id_2 = routing_review.id
      @design_review.save

      # Remove the routing design review and review results for this design
      routing_review = design_reviews.detect { |dr| dr.review_type_id == routing_review.id }
      if routing_review
        routing_review_results =
          DesignReviewResult.delete_all("design_review_id=#{routing_review.id}")
      end
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
    flash['notice'] = "Can't Repost a design if it is on hold" if @design_review.on_hold?


    render( :action => 'post_review' )

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
    design_review.save

    reviewer_list = {}
    params[:board_reviewers].each { |role_id, reviewer_id|
      reviewer_list[role_id.to_i] = reviewer_id.to_i
    }

    pre_art_review = ReviewType.get_pre_artwork
    
    if design_review.review_type.name == 'Pre-Artwork'
      design_review.design.board_design_entry.complete
    end

    design_review.design_review_results.each do |review_result|

      if reviewer_list[review_result.role_id] != review_result.reviewer_id
        review_result.reviewer_id = reviewer_list[review_result.role_id]
      end
      review_result.result      = 'No Response'
      review_result.reviewed_on = current_time
      review_result.save
      
      # Send an invitation to the reviewer if one has not been sent before
      reviewer = User.find(review_result.reviewer_id)
      if !reviewer.invited?
        UserMailer::tracker_invite(reviewer).deliver

        reviewer.password = ''
        reviewer.update_attribute(:invited, 1)
        reviewer.reload
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
        :user_id          => @logged_in_user.id,
        :design_review_id => design_review.id).save
    end


    # Let everybody know that the design has been posted.
    DesignReviewMailer::design_review_posting_notification(design_review,
      params[:post_comment][:comment]).deliver

    if design_review.design.design_center == @logged_in_user.design_center
      redirect_to(:action => 'index', :controller => 'tracker')
    else
      flash['notice'] = 'The design center is not set to your default location - ' +
        @logged_in_user.design_center.name
      redirect_to(:action => 'view', :id => design_review.id)
    end

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
    design_review.save

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
      review_result.save
    end
    

    # Store the comment if the designer entered one.
    if params[:post_comment][:comment] != ""
      DesignReviewComment.new(:comment          => params[:post_comment][:comment],
        :user_id          => @logged_in_user.id,
        :design_review_id => design_review.id).save
    end

    # Let everybody know that the design has been posted.
    DesignReviewMailer::design_review_posting_notification(design_review,
      params[:post_comment][:comment], true).deliver

    if design_review.design.design_center == @logged_in_user.design_center
      redirect_to(:action => 'index', :controller => 'tracker')
    else
      flash['notice'] = 'The design center is not set to your default location - ' +
        @logged_in_user.design_center.name
      redirect_to(:action => 'view', :id => design_review.id)
    end

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

    user_comment = params[:post_comment][:comment]
    if user_comment != ""
 
      design_review = DesignReview.find(params[:design_review][:id])
      comment       = DesignReviewComment.new(:comment => user_comment,
        :user_id => @logged_in_user.id)
      design_review.design_review_comments << comment

      DesignReviewMailer::design_review_update(
           @logged_in_user, design_review, true).deliver
                                                  
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
  # This method the input from the change design center form and updates
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

    updates = {}
    updates[:design_center]  = DesignCenter.find(params[:design_center][:location])
    
    flash['notice'] = design_review.design.admin_updates(updates, 
      '',
      @logged_in_user)
    redirect_to(:action => :view, :id => design_review.id)

  end
 
  ######################################################################
  #
  # change_design_dir
  #
  # Description:
  # This method gathers the data used to populate the change design
  # dir form.
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
  def change_design_dir
    @design_dirs     = DesignDirectory.get_active_design_directories
    @design_review   = DesignReview.find(params[:design_review_id])
    @brd_dsn_entry   = BoardDesignEntry.find(:first,
      :conditions => "design_id='#{@design_review.design_id}'")
  end


  ######################################################################
  #
  # update_design_dir
  #
  # Description:
  # This method the input from the change design directory form and updates
  # the database.
  #
  # Parameters from params
  # [:design_review][:id] - Used to identify the design review.
  # [:design_dir][:location] - The design center ID of the new design
  #                               directory.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def update_design_dir

    design_review = DesignReview.find(params[:design_review][:id])
    board_design_entry   = BoardDesignEntry.find(:first,
      :conditions => "design_id='#{design_review.design_id}'")
    design_directory_id = params[:design_dir][:location]
    design_directory    = DesignDirectory.find(design_directory_id)
    
    board_design_entry.design_directory_id = design_directory_id
    board_design_entry.save

    message = "Design directory changed to #{design_directory.name}"
    
    dr_comment = DesignReviewComment.new
    dr_comment.comment          = message
    dr_comment.user_id          = @logged_in_user.id
    dr_comment.design_review_id = design_review.id
    dr_comment.save

    flash['notice'] = message

    redirect_to(:action => :view, :id => design_review.id)

  end

  ######################################################################
  #
  # change_part_number
  #
  # Description:
  # This method gathers the data used to populate the change part number form.
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
  def change_part_numbers
    @design_review   = DesignReview.find(params[:id])
    if ! params['pnums'].blank?
      @rows = flash['rows']
    else
      @rows = PartNum.find(:all,
        :conditions => { :design_id => @design_review.design_id},
        :order => "'use','prefix','number','dash'" )
    end
    (@rows.size+1..5).each do
      @rows << PartNum.new( :use => "pcba",  :revision => "a" )
    end
    @heading = "#{@design_review.design.name} - Modify Part Numbers"
    @next_value    = "Update Part Numbers"
    @next_action   = { :action => 'update_part_numbers', :id => @design_review.id }
    @cancel_value  = "Return to Design Review"
    @cancel_action = { :action => 'view', :id => @design_review.id}
    render :template => 'shared/enter_part_numbers'
  end

  ######################################################################
  #
  # update_part_number
  #
  # Description:
  # This method updates the part numbers for the design.
  #
  # Parameters from params
  # id - Used to identify the design review.
  # Part number rows from form
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def update_part_numbers
    design_review   = DesignReview.find(params[:id])
    design_id        = design_review.design_id

    pnums = []
    params[:rows].values.each do |row| 
      if !row[:prefix].blank? || !row[:number].blank? || !row[:dash].blank?
         pnums << PartNum.new(row)
      end
    end

    # if no "pcb" entry, add one 
    pcb  = pnums.detect { |pnum| pnum.use == 'pcb' }
    unless pcb 
      pnums.unshift(PartNum.new( :use => "pcb",  :revision => "a" ) )
    end
    flash['rows'] = pnums  #to pass to "change_part_numbers"
    
    #check for a valid PCB part number
    unless pcb && pcb.valid_pcb_part_number?
      flash['notice'] = "A valid PCB part number like '123-456-78' must be specified"
      redirect_to( :action => 'change_part_numbers',
        :id => design_review.id,
        :pnums => 1 ) and return
    end

    #check all specified part numbers for validity
    fail = 0
    flash['notice'] = ''
    pnums.each do | pnum |
      unless pnum.valid_pcb_part_number?
          flash['notice'] += "Part number #{pnum.name_string} invalid<br>\n"
          fail = 1
      end
    end

    if fail == 1
      redirect_to( :action => 'change_part_numbers',
        :id => design_review.id,
        :pnums => 1 ) and return
    end
    
    #check for duplicates already assigned
    fail = 0
    flash['notice'] = ''
    
    design_pnum = PartNum.get_design_pcb_part_number(design_id) 
    
    pnums.each do | pnum |
      db_pnum = pnum.get_part_number
      if  ! db_pnum.blank?  && db_pnum.design_id != design_id 
          flash['notice'] += "Part number #{pnum.name_string} exists<br>\n"
          fail = 1
      end
    end
    if fail == 1      
      redirect_to( :action => 'change_part_numbers',
        :id => design_review.id,
        :pnums => 1  ) and return
    end

    # get current numbers to add to comment
    design = Design.find(design_id)
    old_pcb_num = design.pcb_number
    old_pcba_nums = design.pcbas_string

    # get the current board_design_entry_id
    bde_id = design_pnum.board_design_entry_id
    
    # delete the current part numbers for the design
    PartNum.delete_all(:design_id => design_id )

    #save and relate the part numbers to the design
    fail = 0
    flash['notice'] = ''
    pnums.each do |pnum|
      unless pnum[:prefix] == ""
        pnum.design_id = design_id
        pnum.board_design_entry_id = bde_id
        if ! pnum.save
          flash['notify'] += "Couldn't create part number #{pnum.name_string}"
          fail = 1
        end
      end
    end

    #create 'new' entries for comment
    new_pcb_num = design.pcb_number
    new_pcba_nums = design.pcbas_string

    if fail == 1
      redirect_to( :action => 'change_part_numbers',
        :id => design_review.id,
        :pnums => pnums  ) and return
    else
      change = 0
      dr_comment = DesignReviewComment.new
      dr_comment.comment          = "Part numbers changed.\n"
      if old_pcb_num != new_pcb_num
        dr_comment.comment = dr_comment.comment + "PCB part number:\nOld = " +
          old_pcb_num + "\nNew = " + new_pcb_num +"\n\n"
        change = 1
      end
      if old_pcba_nums != new_pcba_nums
        dr_comment.comment = dr_comment.comment + "PCBA part numbers:\nOld = " +
          old_pcba_nums + "\nNew = " + new_pcba_nums
        change = 1
      end
      dr_comment.user_id          = @logged_in_user.id
      dr_comment.design_review_id = design_review.id
      if change == 1
        dr_comment.save
        flash['notice'] = "The new part numbers have been assigned"
      else
        flash['notice'] = "The part numbers are unchanged"
      end
      redirect_to(:action      => 'view',
        :id          => design_review.id) and return
    end
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
  @design_review = DesignReview.find(params[:id])
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
  
  design_review_id = params[:design_review][:id]
  doc_id           = params[:doc_id]
  return_to        = params[:return_to]
  document = Document.new(params[:document]) if params[:document][:document] != ""
  if !document || document.data.size == 0
    if !document
      flash['notice'] = 'No file was specified - Please specify a document'
    else
      flash['notice'] = 'Empty file - The document was not stored'
    end
    redirect_to(:action           => :update_documents,
      :design_review_id => design_review_id,
      :document_id      => doc_id,
      :return_to        => return_to)
  else
    existing_drd  = DesignReviewDocument.find(doc_id)
    document_type = DocumentType.find(existing_drd.document_type_id)
    design_review = DesignReview.find(design_review_id)

    if document.attach(design_review, document_type, @logged_in_user)
      flash['notice'] = "The #{document_type.name} document has been updated."
      if params[:return_to] == 'initial_attachments'
        redirect_to(:controller => 'design',
          :action     => 'initial_attachments',
          :design_id  => design_review.design_id)
      else
        redirect_to(:action           => :review_attachments,
          :id => design_review_id)
      end
    else
      flash['notice'] = document.errors[:file_size]
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
  @document_types = DocumentType.get_active_document_types
    
  if params[:design_review] != nil
    design_review_id = params[:design_review][:id]
  else
    design_review_id = params[:design_review_id]
  end
   
   
  @design_review = DesignReview.find(design_review_id)
  @board = Board.find(params[:id])
    
  # Eliminate document types that are already attached.
  documents = DesignReviewDocument.find(:all,
    :conditions => "design_id='#{@design_review.design_id}'")
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

  @document   = Document.new(params[:document]) if params[:document][:document] != ""
  save_failed = true
  document_type_id = params[:document_type][:id]
  design_review_id = params[:design_review][:id]
  return_to        = params[:return_to]
  
  if params[:document_type][:id] == '' || !@document || @document.data.size == 0
    flash['notice'] = ''
    flash['notice'] += 'Please select the document type' if params[:document_type][:id] == ''
    if !@document
      flash['notice'] += '<br />' if flash['notice'].size > 0
      flash['notice'] += 'No name provided - Please specify a document'
    elsif @document.data.size == 0
      flash['notice'] += '<br />'  if flash['notice'].size > 0
      flash['notice'] += 'Empty file - The document was not stored'
    end
  else
    document_type = DocumentType.find(document_type_id)
    design_review = DesignReview.find(design_review_id)

    if @document.attach(design_review, document_type, @logged_in_user)
      flash['notice'] = "File #{@document.name} (#{document_type.name}) has been attached"
      save_failed     = false
    else
      flash['notice'] = @document.errors[:file_size]
    end
  end

  if save_failed
    redirect_to(:action           => :add_attachment,
      :id => design_review_id,
      :return_to        => return_to )
  elsif params[:return_to] == 'initial_attachments'
    redirect_to(:controller => 'design',
      :action     => 'initial_attachments',
      :design_id  => design_review.design_id)
  else
    redirect_to(:action           => :review_attachments,
      :id => design_review_id)
  end
end
  
######################################################################
#
# delete_attachment
#
# Description:
# This method deletes the attachment that the user selected.
#-
# Parameters from params
# [:document_id] - Identifies the document.
# [:return_to] - Used to control navigation
#
# Return value:
# None
#
# Additional information:
# Only "other" documents can be deleted
#
######################################################################
#  
def delete_document
  
  drd_id           = params[:drd_id]
  design_review_id = params[:design_review_id]
  return_to        = params[:return_to]
  
  drd = DesignReviewDocument.find(drd_id)
  document = Document.find(drd.document_id)
  doc_name = document.name
  
  if drd.document_type.name == "Other"
    drd.remove
    flash['notice'] = "File #{doc_name} has been deleted"
  else
    flash['notice'] = "Only 'OTHER' document types can be deleted. File #{doc_name} has not been deleted"    
  end
  redirect_to(:action => :review_attachments,
     :id => design_review_id )
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
  if @document.unpacked == 1
    send_data(@document.data.lines.to_a.pack("H*"),
      :filename    => @document.name,
      :type        => @document.content_type,
      :disposition => "inline")
  else
    send_data(@document.data,
      :filename    => @document.name,
      :type        => @document.content_type,
      :disposition => "inline")
  end


   
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
  @design_review      = DesignReview.find(params[:id])
  document_type       = DocumentType.find(params[:document_type_id])
  @document_type_name = document_type.name
  @docs = @design_review.design.board.get_obsolete_document_list(document_type).reverse
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

  @design_review = DesignReview.find(params[:id])

  results = @design_review.design.get_mail_lists(@design_review.id)
  @reviewers        = results[:reviewers]
  @users_copied     = results[:copied]
  @users_not_copied = results[:not_copied]

end

######################################################################
#
# change_cc_list
#
# Description:
# This method updates the CC list depending on the user to be
# added or removed.
#
# Parameters from params
# [:id] - Identifies the user to be added/removed to the CC list.
# [:mode] - Indicates "add_name" or "remove_name"
#
# Displays a partial containing the two selection lists.
#
# Return value:
# None
#
# Additional information:
#
######################################################################
#
def xchange_cc_list
  @design_review = DesignReview.find(params[:id])
  mode = params[:mode]
  user = User.find(params[:user_id])

  design = Design.find(@design_review.design_id)

  # update the data base
  if ( mode == "add_name")
    design.board.users << user
    flash[:ack]     = "Added #{user[:name]} to the CC list"
    action = "Added"
  end
  if ( mode == "remove_name")
    design.board.users.delete(user)
    flash[:ack]     = "Removed #{user[:name]} from the CC list"
    action = "Removed"
  end
  # Update the history
  cc_list_history = CcListHistory.new
  cc_list_history.design_review_id = @design_review.id
  cc_list_history.user_id          = @logged_in_user.id
  cc_list_history.addressee_id     = user.id
  cc_list_history.action           = action
  cc_list_history.save

  results = @design_review.mail_lists
  @reviewers = results[:reviewers]
  @users_copied = results[:copied]
  @users_not_copied = results[:not_copied]

  render(:partial => "display_mail_lists")
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

  roles    = []
  params.each { |key, value|
    if key.include?("role_id")
      result = value.to_a

      design_review_result = DesignReviewResult.find(result[0][0])

      if design_review_result.result != result[0][1]
        roles << { :id                      => key.split('_')[2],
          :design_review_result_id => result[0][0],
          :result                  => result[0][1] }
      end
    end
  }

  # Aggregate the parameters so we can pass them to other functions 
  review_results = {
    :comments         => params["post_comment"]["comment"],
    :design_review_id => params["design_review"]["id"],
    :roles            => roles,
    :priority         => params["priority"],
    :designer         => params["designer"],
    :peer             => params["peer"],
    :fab_houses       => params["fab_house_ids"]
  }

  if roles.size == 0 && params["post_comment"]["comment"].strip == "" &&
    params["fab_house_ids"].blank?
    flash['notice'] = "No information was provided - no update was recorded"
    redirect_to(:action => 'view', :id => params["design_review"]["id"]) and return
  end

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
    dr_comment.user_id          = @logged_in_user.id
    dr_comment.design_review_id = review_results[:design_review_id]
    dr_comment.save
      
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
    # post_fab_house_updates creates a comment
    comment_update = post_fab_house_updates(design_review, review_results[:fab_houses])
  end

  if design_review.in_review?

    review_result_list = design_review.design_review_results

    rejection_entered = false
    review_results[:roles].each do |review_result|

      review_record = review_result_list.detect do |rr|
        rr.role_id.to_s == review_result[:id]
      end

      if review_result[:result] != 'COMMENTED' && review_record 
        review_record.result      = review_result[:result]
        review_record.reviewed_on = Time.now
        review_record.save
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
          review_result.save
        end
      end

      pending_repost = ReviewStatus.find_by_name('Pending Repost')
      design_review.review_status_id = pending_repost.id
      design_review.save

    elsif review_results[:roles].size > 0

      # If all of the reviews have a positive response, the review is complete
      response = ['WITHDRAWN', 'No Response', 'REJECTED', 'COMMENTED']
      outstanding_result = review_result_list.detect { |rr| response.include?(rr.result) }

      if not outstanding_result
        review_completed = ReviewStatus.find_by_name('Review Completed')
        design_review.review_status_id = review_completed.id
        design_review.completed_on     = Time.now
        design_review.save
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
        design.save
      end
    end
  end
  
  # If the status of a review has changed add a comment
  if result_update && result_update.size > 0
    dr_comment = DesignReviewComment.new
    dr_comment.comment          = "Review Status Changed: "
    result_update.each do | role, result|
      dr_comment.comment << (role + "-" + result + ",   ")
    end
    dr_comment.user_id          = @logged_in_user.id
    dr_comment.design_review_id = review_results[:design_review_id]
    dr_comment.save
      
    comment_update = true 
  end
      
  if comment_update || (result_update && result_update.size > 0)
    DesignReviewMailer::design_review_update(@logged_in_user,
      design_review, comment_update, result_update).deliver
  end

  if review_complete
    DesignReviewMailer::design_review_complete_notification(design_review).deliver
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
    #flash_msg += ' ' + fab_msg                  if fab_msg != ''
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

  @design_review = DesignReview.find(params[:design_review_id])

  # Remove reviewer results if the reviewer has already completed the
  # review.
  @design_review.design_review_results.delete_if { |rr| rr.complete? }

  @matching_roles = []
  @logged_in_user.roles.each do |role|

    next if not role.reviewer?

    match = @design_review.design_review_results.detect { |rr| role.id == rr.role_id }
    if match
      if @logged_in_user.id == match.reviewer_id
        peers = role.active_users - [@logged_in_user]
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
  board_users          = @design.board.users.uniq

  flash['notice'] = ""
  
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
    @ftp_notification.fab_house_id = @design.fab_houses[0].id
  else
    @ftp_notification.fab_house_id = 0
  end
    
  @ftp_notification.assembly_bom_number = params[:assembly_bom_number] ? params[:assembly_bom_number] : ''
  @ftp_notification.revision_date       = params[:revision_date]       ? params[:revision_date]       : ''
  @ftp_notification.file_data           = params[:file_data]           ? params[:file_data]           : ''
    

  # Add the Operations Manager from the design_entry to the boards_users data
  if @design.board_design_entry
    ops_manager = @design.board_design_entry.board_design_entry_users.detect { |u| u.role.name == 'Operations Manager'}
    if ops_manager.nil?  || ops_manager.user_id == 0
     flash['notice'] += "<br />WARNING: AN OPERATIONS MANAGER WAS NOT AUTOMATICALLY ADDED TO THE CC LIST"
    else
     @design.board.users << User.find(ops_manager.user_id) unless board_users.detect { |u| u.id == ops_manager.user_id }
    end
  end

  #Add the default users from the FTP Notify role to the boards_users data
  role = Role.find(:first, :conditions => {:name => 'ftp_notify'})
  role.active_users.each { |user|
       @design.board.users << user unless board_users.include?(user)
  }

  results = final_design_review.mail_lists
  @reviewers = results[:reviewers]
  @users_copied = results[:copied]
  @users_not_copied = results[:not_copied]

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

  ftp_notification           = FtpNotification.new(params[:ftp_notification])
  ftp_notification.design_id = params[:id]

  # Verify that all of the information has been provided before processing.
  notice = ""
  if ftp_notification.assembly_bom_number.strip == "" 
    notice += "<br> * Assembly/BOM Number missing"
  end
  if ftp_notification.file_data.strip == ""
    notice += "<br> * File data missing"
  end
  if ftp_notification.division_id == 0
    notice += "<br> * Division not selected"
  end
  if ftp_notification.design_center_id == 0
    notice += "<br> * Design File Location not selected"
  end
  if ftp_notification.fab_house_id == 0
    notice += "<br> * Vendor not selected"
  end

if notice != ""

    flash['notice'] = "Please provide all the data requied for the FTP Notification.  The notification was not sent."
    flash['notice'] += notice
    redirect_to(:action              => "perform_ftp_notification",
      :id                  => params[:id],
      :assembly_bom_number => ftp_notification.assembly_bom_number,
      :file_data           => ftp_notification.file_data,
      :division_id         => ftp_notification.division_id,
      :design_center_id    => ftp_notification.design_center_id,
      :vendor_id           => ftp_notification.fab_house_id)

  else

    design   = Design.find(params[:id])
    if !design.ftp_notification
      
      ftp_notification.save
        
      message  = "NO RESPONSE IS REQUIRED!\n"
      message += "NOTIFICATION THAT FILES HAVE BEEN FTP'D TO VENDOR FOR BOARD FABRICATION\n"
      message += "Date: " + Time.now.to_s + "\n"
      message += "Division: " + ftp_notification.division.name + "\n"
      message += "Assembly/BOM Number: " + ftp_notification.assembly_bom_number + "\n"
      message += "Design Files Location -\n"
      message += "   UNIX:     /hwnet/" + ftp_notification.design_center.pcb_path
      message += "/" + ftp_notification.design.directory_name + "/public/\n"
      message += "   WINDOWS:  \\\\ter.teradyne.com\\hwnet\\" + ftp_notification.design_center.pcb_path
      message += "\\" + ftp_notification.design.directory_name + "\\public\\\n"
      message += "Files Size, Date, and Name: " + ftp_notification.file_data + "\n"
      message += "Vendor: " + ftp_notification.fab_house.name + "\n"
        
      DesignReviewMailer::ftp_notification(message, ftp_notification).deliver

      # Save the FTP Notification in the design's final review.
      message += "\n\nThis notification was delivered to the following people.\n"
      message += " - all of the reviewers\n"
      design.board.users.uniq.each { |user| message += " - #{user.name}\n" }

      final_design_review = design.get_design_review('Final')
      dr_comment = DesignReviewComment.new(:user_id          => @logged_in_user.id,
        :design_review_id => final_design_review.id,
        :highlight        => 1,
        :comment          => message).save
               
        
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
# Skip FTP notification
#
# Description:
#
# Parameters design.id
#
# Return value:
# None
#
# Additional information:
#
######################################################################
#
def skip_ftp_notification
  design              = Design.find(params[:id])
  FtpNotification.new(:design_id => design.id).save
  redirect_to(:controller => 'tracker', :action => 'index')
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
      next if user_id == '' || user_id == '0'
      role = Role.find_by_name(role_name)
      design_review_result = DesignReviewResult.find(
        :first,
        :conditions => "design_review_id='#{design_review_id}' and " +
          "reviewer_id='#{@logged_in_user.id}' and "     +
          "role_id='#{role.id}'")

      if design_review_result
        is_reviewer = @logged_in_user.id == design_review_result.reviewer_id
        design_review_result.reviewer_id = user_id
        design_review_result.save
        peer         = User.find(user_id)
        new_reviewer = peer.name

        design_review.record_update(role.display_name,
          @logged_in_user.name,
          peer.name,
          @logged_in_user)
                                      
        if flash_msg == ''
          flash_msg = "#{new_reviewer} is assigned to the #{role.display_name} review"
        else
          flash_msg += " and #{new_reviewer} is assigned to the #{role.display_name} review"
        end

        if is_reviewer
          Mailer::reassign_design_review_to_peer(
            @logged_in_user, peer, designer, design_review, role).deliver
        end
      end
    }
  end

  # Check to see if any "assign_to_self" box is check.
  params.each { |key, value|

    next if not key.include?("assign_to_self")
    next if value[@logged_in_user.id.to_s] == 'no'

    role = Role.find(key.split('_')[1])
    design_review_result = DesignReviewResult.find(:first,
      :conditions => "design_review_id='#{design_review_id}' and" +
        " role_id='#{role.id}'")

    if design_review_result
      peer = User.find(design_review_result.reviewer_id)
      design_review_result.reviewer_id = @logged_in_user.id
      design_review_result.save
        
      design_review.record_update(role.display_name,
        peer.name,
        @logged_in_user.name,
        @logged_in_user)

      new_reviewer = @logged_in_user.name
      if flash_msg == ''
        flash_msg = "You are assigned to the #{role.display_name} review"
      else
        flash_msg += " and you are assigned to the #{role.display_name} review"
      end

      DesignReviewMailer::reassign_design_review_from_peer(
        @logged_in_user, peer, designer, design_review, role).deliver
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
    
  if session['flash']  && session['flash'][:sort_order]
    session['flash'][:sort_order] = session['flash'][:sort_order]
  end
    
  @design_review = DesignReview.find(params[:id])
    
  @designers           = Role.active_designers
  @designer_list       = @designers - [@design_review.design.peer]
  @peer_list           = @designers - [@design_review.design.designer]
  @pcb_input_gate_list = Role.find_by_name('PCB Input Gate').active_users
  @priorities          = Priority.get_priorities
  @design_centers      = DesignCenter.get_all_active
    
  @review_statuses = []
  if @design_review.in_review? || @design_review.on_hold?
    @review_statuses << ReviewStatus.find_by_name('In Review')
    @review_statuses << ReviewStatus.find_by_name('Review On-Hold')
  end

  @release_poster = nil
  if ( @design_review.design.get_design_review('Release') )
      @release_poster = @design_review.design.get_design_review('Release').designer
  end
  selects = { :designer  => @design_review.design.designer.id,
    :peer      => @design_review.design.peer.id}
  flash[:selects] = selects

end


####################################################################
#
# update_fab_houses
#
# Description:
# Up dates the fab houses associated with a design
# Parameters from params
# id - the design review
#
######################################################################
#
def update_fab_houses

  session[:return_to] = {:controller => 'design_review',
    :action     => 'view',
    :id         => params[:id]}

  if params[:id]
    @design_review  = DesignReview.find(params[:id])
    @design_fab_houses = {}
    @design_review.design.fab_houses.each { |dfh| @design_fab_houses[dfh.id] = dfh }

    @fab_houses = FabHouse.get_all_active

  else

    flash['notice'] = "No ID was provided - unable to access the design review"
    redirect_to(:controller => 'tracker', :action => 'index')
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
    
  # Normally this logic would go in the model.  But the admin update
  # screen is designed to prevent the user from designating the same
  # person as both the designer and the peer auditor.  There is a remote
  # chance that the user could select the same person for both roles.
  # Since the chance is remote I am dealing with it here.
  if params[:peer] && params[:peer][:id] != "" &&
     params[:peer][:id] == params[:designer][:id]
    redirect_to(:action => 'admin_update', :id => params[:id])
    flash['notice'] = 'The peer and the designer must be different - update not recorded'
    return
  end
    
  design = DesignReview.find(params[:id]).design

  updates = {}
  if params[:pcb_input_gate]
    updates[:pcb_input_gate] = User.find(params[:pcb_input_gate][:id])
  end
  if params[:designer] && params[:designer][:id] != ''
    updates[:designer]       = User.find(params[:designer][:id])
  end
  if params[:peer] && params[:peer][:id] != ''
    updates[:peer]           = User.find(params[:peer][:id])
  end
  if params[:review_status]
    updates[:status]         = ReviewStatus.find(params[:review_status][:id])
  end
  if params[:release_poster]
    updates[:release_poster] = User.find(params[:release_poster][:id])
  end

  updates[:design_center]  = DesignCenter.find(params[:design_center][:id])
  updates[:criticality]    = Priority.find(params[:priority][:id]) if params[:priority]
  updates[:eco_number]     = params[:eco_number]
    
  flash['notice'] = design.admin_updates(updates,
    params[:post_comment][:comment],
    @logged_in_user)
   
  if session[:return_to]
    redirect_to(session[:return_to])
  else
    redirect_to(:action => "index", :controller => "tracker" )
  end
    
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
  skipped_review.completed_on     = Time.now
  skipped_review.save
    
  # Set the phase of the design to the next non-skipped review.
  design.increment_review
    
  DesignReviewMailer::notify_design_review_skipped(
            skipped_review, @logged_in_user).deliver

  redirect_to(:controller => 'tracker', :action => 'index')
    
end
  
  
######################################################################
#
# display_designer_select
#
# Description:
# Redisplays the designer selection box with the name of the peer
# that was selected removed from the list of designers.
# 
# This method is called in response to an AJAX call when the user
# makes a selection from the Peer Select box.
#
# Parameters from params
# id - the user id of the peer that was selected.
#
######################################################################
#
def display_designer_select
  designers       = Role.active_designers
  selects         = flash[:selects]
  peer            = designers.detect { |d| d.id==params[:id].to_i}
  selects[:peer]  = peer.id
  flash[:selects] = selects
  
  @designers   = designers - [peer]
  @designer_id = selects[:designer]
    
  render(:layout => false)
  
end
  

######################################################################
#
# display_peer_auditor_select
#
# Description:
# Redisplays the peer selection box with the name of the designer
# that was selected removed from the list of peers.
# 
# This method is called in response to an AJAX call when the user
# makes a selection from the Designer Select box.
#
# Parameters from params
# id - the user id of the designer that was selected.
#
######################################################################
#
def display_peer_auditor_select
  
  designers          = Role.active_designers
  selects            = flash[:selects]
  designer           = designers.detect { |d| d.id==params[:id].to_i}
  selects[:designer] = designer.id
  flash[:selects]    = selects
    
  @peer_list = designers - [designer]
  @peer_id   = selects[:peer]
    
  render(:layout => false)
  
end


######################################################################
#
# process_update_fab_houses
#
# Description:
#   Updates the FAB houses - called from admin button on review form
# Parameters from params
# id         - the review id
# fab_houses - list of fab house from review
#
######################################################################
#
def process_update_fab_houses

  design_review = DesignReview.find(params[:design_review][:id])
  fab_msg = post_fab_house_updates(design_review, params["fab_house_ids"] )

  redirect_to(:action => :view, :id => params[:design_review][:id])
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

  dr_comment = DesignReviewComment.new(:user_id          => @logged_in_user.id,
    :design_review_id => design_review.id,
    :highlight        => 1,
    :comment          => msg).save
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

  # get current fab houses in join design table
  design_fab_houses = design_review.design.fab_houses

  # check if there are any fab houses in the list. if there are then process them to update comment and join tables
  if fab_house_list != nil
    
    # if list of fab houses passed in includes items not in join table then add them to added comment
    fab_house_list.each do |fbl|
      fab_house = FabHouse.find(fbl)
      if !design_fab_houses.include? fab_house
        if added == ''
          added = fab_house.name
        else
          added += ', ' + fab_house.name
        end
      end
    end

    # if join table includes items which are not in the fab house list passed in then add them to removed comment 
    design_fab_houses.each do |fb2|
      if !fab_house_list.include? fb2.id.to_s
        if removed == ''
          removed = fb2.name
        else
          removed += ', ' + fb2.name
        end
      end
    end
        
    # update the design and board fab houses join tables
    design_review.design.fab_houses = FabHouse.find(fab_house_list) if fab_house_list
    design_review.design.board.fab_houses = FabHouse.find(fab_house_list) if fab_house_list 
  
  # Otherwise the user has submitted a form with no vendors selected
  else
    # Just add all items in the join table to the removed list
    design_fab_houses.each do |fab_house|
      if removed == ''
        removed = fab_house.name
      else
        removed += ', ' + fab_house.name
      end
    end
    
    # update the design and board fab houses join tables
    design_review.design.fab_houses -= design_fab_houses
    design_review.design.board.fab_houses -= design_fab_houses
  end  

  # parse together the comment to be posted
  if added !=  '' || removed != ''
    fab_msg = 'Updated the fab houses '

    fab_msg += " - Added: #{added}"     if added   != ''
    fab_msg += " - Removed: #{removed}" if removed != ''

    dr_comment = DesignReviewComment.new(:comment          => fab_msg,
      :user_id          => @logged_in_user.id,
      :design_review_id => design_review.id).save
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
    design = design_review.design

    designer = User.find(review_results[:designer]["id"])
    design.designer_id      = designer.id
    
    priority = Priority.find(review_results[:priority]["id"])
    priority_update = design.priority_id != priority.id
    design.priority_id      = priority.id

    if !audit_skipped
      peer = User.find(review_results[:peer]["id"])
      design.peer_id          = peer.id
    end
    
    design.save
      
    if !audit_skipped
      if peer.is_a_role_member?("Valor")
        # set Valor reviewer as peer
        design.set_role_reviewer(Role::find_by_name("Valor"), peer, @logged_in_user)
      else
        results[:alternate_msg] += "Peer, #{peer.name}, does not have Valor reviewer role and was not assigned. "  
      end
    else
      results[:alternate_msg] += 'No Valor reviewer set (Audit Skipped) - '
    end

    for review in design.design_reviews
      review.priority_id = priority.id
      if (review.review_type.name != 'Release' &&
            review.review_type.name != 'Pre-Artwork')
        review.designer_id = designer.id
      end
      review.save
    end

    results[:alternate_msg] += "Criticality is #{priority.name}, " if priority_update
    results[:alternate_msg] += "The Designer is #{designer.name}"
    if !audit_skipped
      results[:alternate_msg] += " and the Peer is #{peer.name}"
    end

  end

  return results
    
end
  
  

end
