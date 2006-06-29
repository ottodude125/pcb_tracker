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
  # list
  #
  # Description:
  # This method retrieves a list of designs from the database for
  # display.  The list is paginated and is limited to the number 
  # passed to the ":per_page" argument.
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
  def list

    @design_pages, @designs = paginate(:designs,
                                       :per_page => 15,
                                       :order_by => 'name')
  end



  ######################################################################
  #
  # add
  #
  # Description:
  # This form is used to initiate a revision of a design.  add() is the first
  # call in a series of calls that create a menu that is built based on the
  # previous entries in the form.  The list of designers is built to provide
  # a selection box for the lead designer.  The list of designers is saved 
  # for to provide a list to select the peers from.  Once the user has 
  # selected the lead designer, select_revision() is called.
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
  def add

    @board     = Board.find(@params[:board_id])
    @designs   = Design.find_all("board_id=#{@board.id}")

    details = Hash.new
    details[:board_id]    = @board.id
    details[:design_name] = @board.name
    details[:platform]    = @board.platform.name
    details[:project]     = @board.project.name
    flash[:details] = details

  end


  ######################################################################
  #
  # select_revision
  #
  # Description:
  # select_revision() follows add() in a series of calls that create 
  # a menu that is built based on the previous entries in the form.  
  #
  # The list of revisions is built based on the type that was selected in
  # in the previous step.  If new, then the list of revisions starts with
  # the next available revision.  The list is displayed in ascending order.
  # If the type is either Date Code or Dot Rev then the list of revisions 
  # represents only those boards that are already in the system.  The list
  # is displayed in descending order.
  #
  # NOTE: If there are no revisions in the system, then the entire list of
  #       of revisions is displayed in ascending order.
  #
  # Once the user has selected the revision, then select_complete() is called
  # if the type is 'New'.  Otherwise, selcect_suffix() is called.
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
  def select_revision

    designs = Design.find_all("board_id='#{flash[:details][:board_id]}' ", 
                              'revision_id ASC')

    if designs.size > 0
      
      design = designs.pop
      revision = Revision.find(design.revision_id)
      
      if @params[:type] == 'New'
        # If a new design was selected, then eliminate all of the revisions
        # that are already in the system as a possibility for selection.
        @revisions = Revision.find_all("name>'#{revision.name}'",
                                       'name ASC')
      else
        # Only allow the user to select revisions of boards that are already
        # in the system.
        @revisions = Revision.find_all("name<='#{revision.name}'",
                                       'name DESC')
      end
    else
      @revisions = Revision.find_all(nil, 'name ASC')
    end

    # Refresh the details in flash for the next call in the sequence.
    flash[:details] = flash[:details]

    # Add the new details from the last screen.
    flash[:details][:design_type] = @params[:type]

    render(:layout => false)

  end


  ######################################################################
  #
  # select_suffix
  #
  # Description:
  # select_suffix() follows select_revision() in a series of calls that create 
  # a menu that is built based on the previous entries in the form.  
  #
  # The list of suffixes is built for display.  The list of suffixes starts 
  # with the next available suffix.  The list is displayed in ascending order.
  #
  # NOTE: If there are no existing revisions in the system, then the entire 
  #       list of of suffixes is displayed in ascending order.
  #
  # Once the user has selected the suffix, then select_complete() is called.
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
  def select_suffix

    designs = Design.find_all("board_id='#{flash[:details][:board_id]}' and design_type='#{flash[:details][:design_type]}' and revision_id='#{@params[:id]}'", 
                              'created_on DESC')

    # If a new design was selected, then eliminate all of the revisions
    # that are already in the system as a possibility for selection.
    if designs.size > 0
      
      design = designs.pop
      suffix = Suffix.find(design.suffix_id)
      
      @suffixes = Suffix.find_all("name>'#{suffix.name}'",
                                  'name ASC')
    else
      @suffixes = Suffix.find_all(nil, 'name ASC')
    end

    # Refresh the details in flash for the next call in the sequence.
    flash[:details] = flash[:details]

    # Add the new details from the last screen.
    flash[:details][:revision_id] = @params[:id]
    flash[:details][:design_name] += Revision.find(@params[:id]).name

    # If setting up a "New" revision then get the review and reviewer
    # information - the suffix will be skipped.
    if flash[:details][:design_type] == 'New'
      @review_types = ReviewType.find_all('active=1', 'sort_order ASC')
      @reviewers    = Design.get_reviewers(flash[:details][:board_id])
    end

    render(:layout => false)

  end


  ######################################################################
  #
  # select_complete
  #
  # Description:
  # select_complete() follows either select_revision() when the type is 
  # 'New' or select_suffix().  select_complete is the final call to build
  # a menu that is built based on the previous entries in the form.  
  #
  # The review_type and reviewer lists are built for display.  
  # Once the user has selected/verified these entries on the menu (by 
  # opting to add the revision) the create() method is called to process
  # all of the information.
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
  def select_complete

    # Refresh the details in flash for the next call in the sequence.
    flash[:details] = flash[:details]

    # Add the new details from the last screen.
    if flash[:details][:design_type] == 'New'
      flash[:details][:revision_id] = @params[:id]
      flash[:details][:design_name] += Revision.find(@params[:id]).name
    end

    flash[:details][:suffix_id] = 
      @params[:suffix_id] if @params[:suffix_id] != nil

    if flash[:details][:design_type] == 'Date Code'
      flash[:details][:design_name] += '_eco' +
        Suffix.find(flash[:details][:suffix_id]).name
    elsif flash[:details][:design_type] == 'Dot Rev'
      flash[:details][:design_name] += 
        Suffix.find(flash[:details][:suffix_id]).name
    end

    @review_types   = ReviewType.find_all('active=1', 'sort_order ASC')
    @reviewers      = Design.get_reviewers(flash[:details][:board_id])
    @priority_list  = Priority.find_all(nil, 'value ASC')

    board_fab_houses = Board.find(flash[:details][:board_id]).fab_houses

    @fab_house_ids = Array.new
    for fab_house in board_fab_houses
      @fab_house_ids.push(fab_house.id)
    end
    @fab_houses = FabHouse.find_all('active=1', 'name ASC')

    render(:layout => false)

  end


  ######################################################################
  #
  # create
  #
  # Description:
  # Called after all of the design revision information is entered.
  # Creates the following
  # 
  #    - 1 design revision
  #    - a design_review table entry for each of the review types
  #      including the associated design review results
  #    - an entry in the audit table for the peer audit review.
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
  def create

    details = flash[:details]

    # Determine the first review in the cycle
    phase_id   = Design::COMPLETE
    sort_order = Design::COMPLETE
    @params[:review_type].each { |review, active|
      next if active == '0'

      review_type = ReviewType.find_by_name(review)
      if review_type.sort_order < sort_order
        phase_id   = review_type.id
        sort_order = review_type.sort_order
      end
    }

    design = Design.new
    design.phase_id     = phase_id
    design.board_id     = details[:board_id]
    design.revision_id  = details[:revision_id]
    design.suffix_id    = details[:suffix_id]
    design.design_type  = details[:design_type]
    design.pcb_input_id = @session[:user].id
    design.priority_id  = @params[:priority][:id].to_s
    design.save 

    if design.errors.empty?

      flash['notice'] = "Revision was created"

      # Go through each of the review types and set up a review.
      @params[:review_type].each { |review, active|

        review_type = ReviewType.find_by_name(review)

        design_review = DesignReview.new
        
        design_review.design_id        = design.id
        design_review.priority_id      = design.priority_id

        if review_type.name == "Pre-Artwork"
          design_review.designer_id      = design.pcb_input_id
          design_review.design_center_id = User.find(design.pcb_input_id).design_center_id
        elsif review_type.name == "Release"
          # NOTE: This assumes that there is only one PCB Admin.
          pcb_admin = Role.find_by_name("PCB Admin").users.pop
          design_review.designer_id      = pcb_admin.id
          design_review.design_center_id = pcb_admin.design_center_id
        end
        
        if active == '1'
          design_review.review_status_id =
            ReviewStatus.find_by_name('Not Started').id
        else
          design_review.review_status_id = 
            ReviewStatus.find_by_name('Review Skipped').id
        end
        design_review.review_type_id   = review_type.id
        design_review.creator_id       = @session[:user][:id]

        design_review.save

        # Check to make sure the review is going to happen before 
        # creating the entries for the design reviewers.
        # JPA: This is going to require some logic to set the reviewers 
        # up if the review does get added in.
        next if not active

        # Go through the board reviewers and create entries for the 
        # design reviewers
        @params[:board_reviewers].each { |reviewer_role, reviewer_id|

          next if @params[:reviewer][reviewer_role] == '0'

          role = Role.find_by_name(reviewer_role)

          if role.review_types.include?(review_type)
            design_review_result = DesignReviewResult.new
            
            design_review_result.design_review_id = design_review.id
            design_review_result.reviewer_id      = reviewer_id
            design_review_result.role_id          = role.id
            
            design_review_result.save

            # Check the role (group) to see if the reviewer's peers should
            # get copied on the mail.
            if design_review_result.role.cc_peers?
              cc_list = design_review_result.role.users
              for peer in cc_list
                if (peer.id == design_review_result.reviewer_id or
                    ! peer.active?                              or
                    design_review.design.board.users.include?(peer))
                  next
                end
                  design_review.design.board.users << peer
              end
            end
          end
        }  # each board reviewer
      }  # each review type

      # Create a peer audit.
      checklist = Checklist.find(:first,
                                  :conditions => ['released=1'],
                                  :order      => 'major_rev_number DESC')

      peer_audit = Audit.new
      peer_audit.design_id    = design.id
      peer_audit.checklist_id = checklist.id
      peer_audit.designer_complete         = 0
      peer_audit.auditor_complete          = 0
      peer_audit.designer_completed_checks = 0
      peer_audit.auditor_completed_checks  = 0
      peer_audit.save
      peer_audit.create_checklist

      # Set the fab house information
      @params['fab_house'].each { |fab_house_id, selected|
        design.fab_houses << FabHouse.find(fab_house_id) if selected == '1'
      }

    else
      flash['notice'] = "Revision was NOT created"
    end

    redirect_to(:action     => 'initial_cc_list',
                :design_id  => design.id)

  end


  def initial_cc_list

    @design = Design.find(@params[:design_id])

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
          :name      => reviewer.name,
          :group     => review_result.role.name,
          :last_name => reviewer.last_name,
          :id        => reviewer.id
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

    @design        = Design.find(@params[:design_id])
    document_types = DocumentType.find_all(nil, 'name ASC')
    @pre_art       = ReviewType.find_by_name("Pre-Artwork")
    @design_review = @design.design_reviews { |dr| dr.review_type_id == @pre_art.id }
    
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
