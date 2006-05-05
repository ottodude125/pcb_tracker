########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: tracker_mailer.rb
#
# This file contains the methods to generate email for the tracker.
#
# $Id$
#
########################################################################

class TrackerMailer < ActionMailer::Base


  ######################################################################
  #
  # peer_audit_complete
  #
  # Description:
  # This method generates the mail to the designer that indicates that
  # the peer has completed the audit.
  #
  # Parameters:
  #   audit   - the audit that is being processed
  #   sent_at - the timestamp for the mail header (defaults to Time.now)
  #
  ######################################################################
  #
  def peer_audit_complete(audit,
                          sent_at = Time.now)
    
    @subject    = "#{audit.design.name}: The peer auditor has completed the audit"

    designer = User.find(audit.design.designer_id)
    peer     = User.find(audit.design.peer_id)
    @recipients = designer.email
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    cc_list     = [peer.email] + add_role_members(['Manager', 'PCB Input Gate'])
    @cc         = cc_list.uniq
    @body       = { :audit    => audit,
                    :designer => designer,
                    :peer     => peer }
    
  end
  

  ######################################################################
  #
  # self_audit_complete
  #
  # Description:
  # This method generates the mail to the peer that indicates that
  # the designer has completed the self audit.
  #
  # Parameters:
  #   audit   - the audit that is being processed
  #   sent_at - the timestamp for the mail header (defaults to Time.now)
  #
  ######################################################################
  #
  def self_audit_complete(audit,
                          sent_at = Time.now)
    @subject    = "#{audit.design.name}: The designer has completed the self-audit"

    designer = User.find(audit.design.designer_id)
    peer     = User.find(audit.design.peer_id)
    @recipients = peer.email
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    cc_list     = [designer.email] + add_role_members(['Manager', 'PCB Input Gate'])
    @cc         = cc_list.uniq
    @body       = { :audit    => audit,
                    :designer => designer,
                    :peer     => peer }
    
  end
  

  ######################################################################
  #
  # design_review_update
  #
  # Description:
  # This method generates the mail indicate that an update has been
  # made to a review.
  #
  # Parameters:
  #   user           - the user making the update
  #   design_review  - the design review that was updated
  #   comment_update - a flag to indicate if new comments were added
  #   result_update  - a flag to indicate if a result was entered
  #   sent_at        - the timestamp for the mail header 
  #                    (defaults to Time.now)
  #
  # Additional information:
  #
  ######################################################################
  #
  def design_review_update(user, 
                           design_review, 
                           comment_update, 
                           result_update   = {},
                           sent_at         = Time.now)

    review_results = ''
    subject        = "#{design_review.design.name}::#{design_review.review_name}"

    if comment_update && result_update == {}
      @subject    = "#{subject} - Comments added"
    elsif result_update
      
      results = DesignReviewResult.find_all(
        "design_review_id=#{design_review.id} and reviewer_id='#{user.id}'")

      0.upto(results.size-1) { |i|
        review_results += "#{results[i].role.name} - #{results[i].result}"
        review_results += ', ' if results.size > 1 && i < (results.size-1)
        }

        if comment_update
          @subject    = "#{subject}  #{review_results} - See comments"
        else
          @subject    = "#{subject}  #{review_results} - No comments"
        end

    end

    @recipients = reviewer_list(design_review)
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
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
  
  
  ######################################################################
  #
  # design_review_complete_notification
  #
  # Description:
  # This method generates the mail indicate that a design review has 
  # completed.
  #
  # Parameters:
  #   design_review  - the design review that was completed
  #   sent_at        - the timestamp for the mail header (defaults to Time.now)
  #
  # Additional information:
  #
  ######################################################################
  #
  def design_review_complete_notification(design_review,
                                          sent_at        = Time.now)

    @subject    = "#{design_review.design.name}: #{design_review.review_name} Review is complete"

    @recipients = reviewer_list(design_review)
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    cc          = copy_to(design_review)

    case design_review.review_type.name
    when "Release"
      cc.push("STD_DC_ECO_Inbox@notes.teradyne.com")
    when "Final"
      pcb_admin = Role.find_by_name("PCB Admin")
      for user in pcb_admin.users
        cc.push(user.email) if user.active?
      end
    when 'Pre-Artwork'
      cc.push(User.find(design_review.design.pcb_input_id).email)
    end
    @cc = cc.uniq
    
    @body['design_review_id'] = design_review.id

  end


  ######################################################################
  #
  # design_review_posting_notification
  #
  # Description:
  # This method generates the mail to alert the reviewers that a design
  # review has been posted or reposted.
  #
  # Parameters:
  #   design_review  - the design review that was posted
  #   comment        - the comment entered by the designer when posting
  #   repost         - a flag that indicates that the design review is
  #                    being reposted when true
  #   sent_at        - the timestamp for the mail header (defaults to Time.now)
  #
  ######################################################################
  #
  def design_review_posting_notification(design_review, 
                                         comment, 
                                         repost         = false,
                                         sent_at        = Time.now)

    @subject    = "#{design_review.design.name}: " +
                  "The #{design_review.review_name} review has been "
    @subject += repost ? "reposted" : "posted"

    @recipients = reviewer_list(design_review)
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    @cc         = copy_to(design_review)

    if design_review.review_type.name == "Final"
      pcb_admin = Role.find_by_name("PCB Admin")
      for user in pcb_admin.users
        @cc.push(user.email) if user.active?
      end
    end
    @cc = @cc.uniq

    @body['user']          = User.find(design_review.designer_id)
    @body['comments']      = comment
    @body['design_review'] = design_review
    @body['repost']        = repost

  end


  ######################################################################
  #
  # ipd_update
  #
  # Description:
  # This method generates the mail indicate that an update has been
  # made to an In-Process Dialogue thread.
  #
  # Parameters:
  #   root_post - The root of the IPD thread.
  #   sent_at   - the timestamp for the mail header (defaults to Time.now)
  #
  ######################################################################
  #
  def ipd_update(root_post,
                 sent_at = Time.now)

    poster = User.find(root_post.user_id)
    
    @subject    = root_post.design.name + ' [IPD] - ' +
                   root_post.subject
    @body       = {:root_post => root_post}

    recipients = []
    if (root_post.design.designer_id > 0 &&
        root_post.design.designer_id != poster.id)
      designer = User.find(root_post.design.designer_id)
      recipients.push(designer.email)
    end

    pre_artwork = ReviewType.find_by_name("Pre-Artwork")
    pre_artwork_design_review = 
      DesignReview.find_by_design_id_and_review_type_id(root_post.design_id,
                                                        pre_artwork.id)
    hweng_role = Role.find_by_name("HWENG")
    hweng_pre_art_review_result = 
      DesignReviewResult.find_by_design_review_id_and_role_id(pre_artwork_design_review.id,
                                                              hweng_role.id)

    if hweng_pre_art_review_result.reviewer_id != poster.id
      hweng = User.find(hweng_pre_art_review_result.reviewer_id)
      recipients.push(hweng.email)
    end
    
    @recipients = recipients.uniq
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}

    cc         = [poster.email] + 
                   add_role_members(['Manager', 'PCB Input Gate'])
    
    pcb_input_gate_role = Role.find_by_name("PCB Input Gate")
    for pcb_input_gate in pcb_input_gate_role.users
      cc.push(pcb_input_gate.email)
    end

    for child in root_post.direct_children
      cc.push(child.user.email)
    end
    
    @cc = cc.uniq

  end

  ######################################################################
  #
  # user_password
  #
  # Description:
  # This method generates the mail to send the password to the user.
  #
  # Parameters:
  #   user    - The user record containing the email address and password.
  #   sent_at - the timestamp for the mail header (defaults to Time.now)
  #
  ######################################################################
  #
  def user_password(user,
                    sent_at = Time.now)

    @subject    = "Your password"
    @body       = {:password => user.passwd}
    @recipients = [user.email]
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    @cc         = []

  end


  ######################################################################
  #
  # ping_summary
  #
  # Description:
  # This method generates a summary of the reviewers that were pinged for
  # outstanding reviews.
  #
  # Parameters:
  #   ping_list - The list of reviewers who were pinged.
  #   sent_at   - the timestamp for the mail header (defaults to Time.now)
  #
  ######################################################################
  #
  def ping_summary(ping_list,
                   sent_at = Time.now)
  
    @subject    = 'Summary of reviewers who have not approved/waived design reviews'
    ping_list.to_a
    @body       = {:ping_list => ping_list}
    
    recipients = add_role_members(['Manager', 'PCB Input Gate'])
    
    @recipients = recipients.uniq
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    
  end


  ######################################################################
  #
  # ping_reviewer
  #
  # Description:
  # This method generates a summary of the reviewers that were pinged for
  # outstanding reviews.
  #
  # Parameters:
  #   review_result_list - A record for a reviewer with a list of the 
  #                        outstanding reviews.
  #   sent_at            - the timestamp for the mail header 
  #                        (defaults to Time.now)
  #
  ######################################################################
  #
  def ping_reviewer(review_result_list,
                    sent_at = Time.now)

    @subject    = 'Your unresolved Design Review(s)'
    @recipients = review_result_list[:reviewer].email
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}

    @body[:review_list] = review_result_list[:review_list]

  end
  
  ######################################################################
  #
  # reassign_design_review_to_peer
  #
  # Description:
  # This method generates the mail to a reviewer's peer indicating that
  # the reviewer has assigned the review to the peer.
  #
  # Parameters:
  #   user     - the reviewer's user object
  #   peer     - the peer's user object
  #   designer - the designer's user object
  #   design   - the design object
  #   role     - the role object
  #   sent_at  - the timestamp for the mail header 
  #              (defaults to Time.now)
  #
  ######################################################################
  #
  def reassign_design_review_to_peer(user, 
                                     peer, 
                                     designer,
                                     design,
                                     role,
                                     sent_at = Time.now)

    @subject    = "#{design.name}: You have been assigned to perform the #{role.name} review"
    @recipients = peer.email
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    
    cc_list =  [user.email]
    cc_list += add_role_members(['Manager', 
                                 'PCB Input Gate'])
    cc_list.delete_if { |recipient| recipient == peer.email }
    @cc = cc_list.uniq

    @body['user_name'] = user.name
    @body['peer_name'] = peer.name
    @body['role_name'] = role.name
    @body['design_name'] = design.name  

  end


  ######################################################################
  #
  # reassign_design_review_from_peer
  #
  # Description:
  # This method generates the mail to a reviewer's peer indicating that
  # the reviewer has take the review assignment from the review.
  #
  # Parameters:
  #   user     - the reviewer's user object
  #   peer     - the peer's user object
  #   designer - the designer's user object
  #   design   - the design object
  #   role     - the role object
  #   sent_at  - the timestamp for the mail header 
  #              (defaults to Time.now)
  #
  ######################################################################
  #
  def reassign_design_review_from_peer(user,
                                       peer,
                                       designer,
                                       design,
                                       role,
                                       sent_at = Time.now)

    @subject    = "#{design.name}: The #{role.name} review has been reassigned to #{user.name}"
    @recipients = peer.email
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}

    cc_list =  [user.email]
    cc_list += add_role_members(['Manager', 
                                 'PCB Input Gate'])
    cc_list.delete_if { |recipient| recipient == peer.email }
    @cc = cc_list.uniq

    @body['user_name'] = user.name
    @body['peer_name'] = peer.name
    @body['role_name'] = role.name
    @body['design_name'] = design.name  

  end
  
  
  private
  
  
  ######################################################################
  #
  # add_role_members
  #
  # Description:
  # Given a list of roles this method will return the email for
  # all of the members of that group.
  #
  # Parameters:
  #   role_list - a list of role names
  #
  ######################################################################
  #
  def add_role_members(role_list)
  
    cc_list = []
    for role_name in role_list
      for member in Role.find_by_name(role_name).users
        cc_list << member.email if member.active?
      end
    end
    
    return cc_list
    
  end
  
  
  ######################################################################
  #
  # reviewer_list
  #
  # Description:
  # Given a design review this method will return a list of the
  # reviewer emails
  #
  # Parameters:
  #   design_review - the design review to get the reviewers for.
  #
  ######################################################################
  #
  def reviewer_list(design_review)

    reviewers = []
    design_review_results = 
      DesignReviewResult.find_all_by_design_review_id(design_review.id)

    for dr_result in design_review_results
      reviewer = User.find(dr_result.reviewer_id)
      reviewers << reviewer.email if reviewer.active?
    end

    return reviewers.uniq
    
  end


  ######################################################################
  #
  # copy_to
  #
  # Description:
  # Given a design review this method will return a list of the
  # people who should be CC'ed on all mails
  #
  # Parameters:
  #   design_review - the design review to get the CC list for.
  #
  ######################################################################
  #
  def copy_to(design_review)

    cc_list = User.find(design_review.designer_id).email.to_a
 
    for cc in design_review.design.board.users
      cc_list << cc.email if cc.active?
    end

    cc_list += add_role_members(['Manager', 'PCB Input Gate'])
    return cc_list.uniq
    
  end
  
  
end
