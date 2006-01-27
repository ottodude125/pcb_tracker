########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_review_mailer.rb
#
# This file contains the methods to generate email for design reviews.
#
# $Id$
#
########################################################################

class DesignReviewMailer < ActionMailer::Base

  ######################################################################
  #
  # update
  #
  # Description:
  # This method generates the mail indicate that an update has been
  # made to a review.
  #
  # Parameters from @params
  #   user           - the user makeing the update
  #   design_review  - the design review that was updated
  #   comment_update - a flag to indicate if new comments were added
  #   result_update  - a flag to indicate if a result was entered
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def update(user, design_review, comment_update, result_update)

    updates  = ''
    updates  = 'Comments '      if comment_update
    updates += 'and '           if updates != '' && result_update
    updates += 'Review Results' if result_update

    @subject    = "#{design_review.design.name}: #{design_review.review_name} Review updated with #{updates}"

    @recipients = reviewer_list(design_review)
    @from       = Pcbtr::SENDER
    @sent_on    = Time.now
    @headers    = {}
    @cc         = copy_to(design_review)

    @body['user'] = user

    if comment_update
      design_review_comments =
        DesignReviewComment.find_all_by_design_review_id(design_review.id,
                                                         'created_on DESC')
      comments = Array.new
      count = design_review_comments.size < 4 ? design_review_comments.size : 4
      0.upto(count-1) { |i|
        comments[i] = {:comment => design_review_comments[i].comment,
                       :user    => User.find(design_review_comments[i].user_id).name,
                       :date    => design_review_comments[i].created_on}
      }

      @body['comments']      = comments

    end

    @body['result_update']    = result_update
    @body['design_review_id'] = design_review.id

  end


  def review_complete_notification(user, design_review)

    @subject    = "#{design_review.design.name}: #{design_review.review_name} Review is complete"

    @recipients = reviewer_list(design_review)
    @from       = Pcbtr::SENDER
    @sent_on    = Time.now
    @headers    = {}
    @cc         = copy_to(design_review)
    
    if design_review.review_type.name == "Release"
      @cc.push("STD_DC_ECO_Inbox@notes.teradyne.com")
    end
    
    @body['design_review_id'] = design_review.id

  end



  ######################################################################
  #
  # posting_notification
  #
  # Description:
  # This method generates the mail to alert the reviewers that a design
  # review has been posted or reposted.
  #
  # Parameters from @params
  #   design_review  - the design review that was posted
  #   comment        - the comment entered by the designer when posting
  #   repost         - a flag that indicates that the design review is
  #                    being reposted when true
  #
  ######################################################################
  #
  def posting_notification(design_review, 
                           comment, 
                           repost         = false)

    @subject    = "#{design_review.design.name}: " +
                  "The #{design_review.review_name} review has been "
    @subject += repost ? "reposted" : "posted"

    @recipients = reviewer_list(design_review)
    @from       = Pcbtr::SENDER
    @sent_on    = Time.now
    @headers    = {}
    @cc         = copy_to(design_review)

    @body['user']          = User.find(design_review.designer_id)
    @body['comments']      = comment
    @body['design_review'] = design_review
    @body['repost']        = repost

  end


  private


  def reviewer_list(design_review)

    logger.info "######################## reviewer_list(#{design_review.id})"
    reviewers = []
    design_review_results = 
      DesignReviewResult.find_all_by_design_review_id(design_review.id)
    logger.info "### FOUND #{design_review_results.size} REVIEWERS"
      
    for dr_result in design_review_results
      reviewer = User.find(dr_result.reviewer_id)
      reviewers << reviewer.email if reviewer.active?
      logger.info "### ADDED #{reviewer.name} TO THE ADDRESSEE LIST"
    end

    return reviewers.uniq
    
  end


  def copy_to(design_review)

    logger.info "######################## copy_to(#{design_review.id})"
    cc_list = User.find(design_review.designer_id).email.to_a
    logger.info "### ADDED #{User.find(design_review.designer_id).name} TO THE CC LIST"

    board = Board.find(design_review.design.board_id)
    logger.info "### BOARD #{design_review.design.board_id}"
    logger.info "### FOUND #{board.users.size} REVIEWERS"
    for cc in board.users
      next if not cc.active?
      cc_list << cc.email
      logger.info "### ADDED #{cc.name} TO THE CC LIST"
    end


    pcb_managers = Role.find_by_name('Manager')
    for manager in pcb_managers.users
      cc_list << manager.email
      logger.info "### ADDED #{manager.name} TO THE CC LIST"
    end
    
    return cc_list.uniq
    
  end


end
