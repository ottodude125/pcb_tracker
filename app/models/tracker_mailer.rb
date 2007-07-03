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

    designer = audit.design.designer
    peer     = audit.design.peer
    
    @recipients = designer.email
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    cc_list     = [peer.email] + add_role_members(['Manager', 'PCB Input Gate'])
    @cc         = cc_list.uniq
    @bcc        = blind_cc
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

    designer = audit.design.designer
    peer     = audit.design.peer

    @recipients = peer.email
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    cc_list     = [designer.email] + add_role_members(['Manager', 'PCB Input Gate'])
    @cc         = cc_list.uniq
    @bcc        = blind_cc
    @body       = { :audit    => audit,
                    :designer => designer,
                    :peer     => peer }
    
  end
  

  ######################################################################
  #
  # ftp_notification
  #
  # Description:
  # This method generates the mail to notify that the design data has
  # been ftp'd
  #
  # Parameters:
  #   message          - the user making the update
  #   ftp_notification - the record containing the ftp notification details
  #   sent_at          - the timestamp for the mail header (defaults to Time.now)
  #
  # Additional information:
  #
  ######################################################################
  #
  def ftp_notification(message,
                       ftp_notification,
                       sent_at         = Time.now)

    design_review = ftp_notification.design.design_reviews.detect { |dr| dr.review_type.name == "Final"}
    
    @subject    = "#{ftp_notification.design.name} Bare Board Files have been transmitted to #{ftp_notification.fab_house.name}"
    @recipients      = reviewer_list(design_review)
    @from            = Pcbtr::SENDER
    @sent_on         = sent_at
    @headers         = {}
    @bcc             = blind_cc
    @cc              = copy_to(design_review) - recipients
    @body['message'] = message

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
      
      results = DesignReviewResult.find(
                  :all,
                  :conditions => "design_review_id=#{design_review.id} AND " +
                                 "reviewer_id='#{user.id}'")

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
    @bcc        = blind_cc
    @cc         = copy_to(design_review) - @recipients
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
  # design_modifications
  #
  # Description:
  # This method generates the mail indicate that a design has been 
  # modifed
  #
  # Parameters:
  #   user    - the user making the update
  #   cc_list - contains the email addresses for the designer and the 
  #             peer auditor
  #   design  - the record for the design that has been modified   
  #   sent_at - the timestamp for the mail header (defaults to Time.now)
  #
  ######################################################################
  #
  def design_modification(user,
                          design,
                          comment,
                          cc_list = [],
                          sent_at = Time.now)

    design_review = design.get_phase_design_review
    @subject      = "The #{design.name} #{design_review.review_type.name} Design Review has been modified by #{user.name}"

    @recipients  = design_review.active_reviewers.collect { |r| r.email }
    design       = design_review.design
    
    @recipients << design.designer.email   if design.designer_id  > 0
    @recipients << design.peer.email       if design.peer_id      > 0
    @recipients << design.input_gate.email if design.pcb_input_id > 0
    @recipients  = @recipients.uniq
    @from        = Pcbtr::SENDER
    @sent_on     = sent_at
    @headers     = {}
    @bcc         = blind_cc
    @cc          = ((copy_to(design_review) + cc_list) - @recipients).uniq

    @body['user']             = user
    @body['comment']          = comment
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
    cc = copy_to(design_review) + copy_to_on_milestone(design_review.design.board)

    case design_review.review_type.name
    when "Release"
      cc.push("STD_DC_ECO_Inbox@notes.teradyne.com") if !Pcbtr::DEVEL_SERVER
    when "Final"
      pcb_admin = Role.find_by_name("PCB Admin")
      cc       += pcb_admin.active_users.collect { |u| u.email }
    when 'Pre-Artwork'
      cc.push(design_review.design.input_gate.email)
    end
    @cc = cc.uniq
    @bcc = blind_cc
    
    @body['design_review_id'] = design_review.id

  end


  ######################################################################
  #
  # final_review_warning
  #
  # Description:
  # This method generates the mail to alert the review community that the
  # final review will be posted soon.
  #
  # Parameters:
  #   design  - the design for which the final review will soon be posted.
  #   sent_at - the timestamp for the mail header (defaults to Time.now)
  #
  # Additional information:
  #
  ######################################################################
  #
  def final_review_warning(design, 
                           sent_at = Time.now)

    @subject    = "Notification of upcoming Final Review for #{design.name}"

    final_review = design.design_reviews.detect { |dr| dr.review_type.name == "Final" }
    @recipients  = final_review.design_review_results.collect { |rr|
                     User.find(rr.reviewer_id).email }.uniq
    @from        = Pcbtr::SENDER
    @sent_on     = sent_at
    @headers     = {}
    @bcc         = blind_cc
    cc           = copy_to(final_review) + copy_to_on_milestone(final_review.design.board)
    
    # Remove any duplicates as well as any people who were already inserted into the 
    # recipients list.
    @cc          = (cc - @recipients).uniq

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
    @bcc        = blind_cc
    cc = copy_to(design_review) + copy_to_on_milestone(design_review.design.board)

    if design_review.review_type.name == "Final"
      pcb_admin = Role.find_by_name("PCB Admin")
      cc += pcb_admin.active_users.collect { |u| u.email }
    end
    @cc = cc.uniq

    @body['user']          = design_review.designer
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
      recipients.push(root_post.design.designer.email)
    end

    pre_artwork = ReviewType.get_pre_artwork
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
    @bcc        = blind_cc

    cc         = [poster.email] + 
                   add_role_members(['Manager', 'PCB Input Gate']) +
                   add_board_reviewer(root_post.design.board,
                                      ['Hardware Engineering Manager'])
    
    for child in root_post.direct_children
      cc.push(child.user.email)
    end
    
    for user in root_post.users
      cc.push(user.email)
    end
    
    @cc = cc.uniq

  end

  ######################################################################
  #
  # audit_team_updates
  #
  # Description:
  # This method generates the mail to let people know that they have 
  # been added or removed from an audit team.
  #
  # Parameters:
  #   updated_by       - The user who made the updates.
  #   audit            - The record for the audit.  
  #   team_update_list - A list of users who have either been added or 
  #                      removed from the audit team.
  #   sent_at          - the timestamp for the mail header 
  #                      (defaults to Time.now)
  #
  ######################################################################
  #
  def audit_team_updates(updated_by,
                         audit,
                         team_update_lists,
                         sent_at = Time.now)

    @subject = "The audit team for the #{audit.design.name} has been updated"

    recipients = []
    team_update_lists.each { |key, list|
    
      team_update_lists[key] = list.sort_by { |t| t[:teammate].section.sort_order }

      for teammate in list
        recipients.push(teammate[:teammate].user.email)
      end
    }
    
    audit_team_lists = { 'self' => [], 'peer' => [] }
    for member in audit.audit_teammates
      key = member.self? ? 'self' : 'peer'
      audit_team_lists[key] << member
    end

    audit_team_lists.each { |key, list|

      audit_team_lists[key] = list.sort_by { |t| t.section.sort_order }

      for teammate in list
        recipients.push(teammate.user.email)
      end
    
    }

    @body = {:updated_by => updated_by,
             :audit      => audit,
             :updates    => team_update_lists,
             :audit_team => audit_team_lists}

    @recipients = recipients.uniq
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    @bcc        = blind_cc

    cc = [updated_by.email] + add_role_members(['Manager', 'PCB Input Gate'])
    
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
    @bcc        = blind_cc
    
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
    @bcc        = blind_cc

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
  #   user          - the reviewer's user object
  #   peer          - the peer's user object
  #   designer      - the designer's user object
  #   design_review - the design object
  #   role          - the role object
  #   sent_at       - the timestamp for the mail header 
  #                   (defaults to Time.now)
  #
  ######################################################################
  #
  def reassign_design_review_to_peer(user, 
                                     peer, 
                                     designer,
                                     design_review,
                                     role,
                                     sent_at = Time.now)

    @subject    = design_review.design.name +
                    ": You have been assigned to perform the #{role.display_name} review"
    @recipients = peer.email
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    @bcc        = blind_cc
    
    cc_list =  [user.email]
    cc_list += add_role_members(['Manager', 'PCB Input Gate'])
    cc_list.delete_if { |recipient| recipient == peer.email }
    @cc = cc_list.uniq

    @body['user_name']        = user.name
    @body['peer_name']        = peer.name
    @body['role_name']        = role.display_name
    @body['design_name']      = design_review.design.name
    @body['design_review_id'] = design_review.id  

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
  #   user          - the reviewer's user object
  #   peer          - the peer's user object
  #   designer      - the designer's user object
  #   design_review - the design object
  #   role          - the role object
  #   sent_at       - the timestamp for the mail header 
  #              (defaults to Time.now)
  #
  ######################################################################
  #
  def reassign_design_review_from_peer(user,
                                       peer,
                                       designer,
                                       design_review,
                                       role,
                                       sent_at = Time.now)

    @subject    = design_review.design.name +
                    ": The #{role.display_name} review has been reassigned to #{user.name}"
    @recipients = peer.email
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    @bcc        = blind_cc

    cc_list =  [user.email]
    cc_list += add_role_members(['Manager', 'PCB Input Gate'])
    cc_list.delete_if { |recipient| recipient == peer.email }
    @cc = cc_list.uniq

    @body['user_name']        = user.name
    @body['peer_name']        = peer.name
    @body['role_name']        = role.display_name
    @body['design_name']      = design_review.design.name
    @body['design_review_id'] = design_review.id 

  end


  ######################################################################
  #
  # notify_design_review_skipped
  #
  # Description:
  # This method generates the mail to notify the PCB Design team
  # that a design review has been skipped.
  #
  # Parameters:
  #   design_review - the design object
  #   session       - the session object
  #   sent_at       - the timestamp for the mail header 
  #                   (defaults to Time.now)
  #
  ######################################################################
  #
  def notify_design_review_skipped(design_review,
                                   session,
                                   sent_at = Time.now)

    @subject    = design_review.design.name +
                    ": The #{design_review.review_type.name} " +
                    "design review has been skipped"
    @recipients = add_role_members(['Manager', 'PCB Input Gate'])
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    @bcc        = blind_cc
    @cc         = [design_review.design.designer.email]

    @body['user_name']          = session[:user].name
    @body['design_name']        = design_review.design.name
    @body['design_review_name'] = design_review.review_type.name

  end


  ######################################################################
  #
  # tracker_invite
  #
  # Description:
  # This method generates the mail to a reviewer to let them know they
  # have been added to the tracker
  #
  # Parameters:
  #   user     - the reviewer's user object
  #
  ######################################################################
  #
  def tracker_invite(user,
                     sent_at = Time.now)

    @subject    = "Your login information for the PCB Design Tracker"
    @recipients = user.email
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    @cc         = []
    @bcc        = blind_cc

    @body['reviewer'] = user

  end
  
  
  ######################################################################
  #
  # attachment_update
  #
  # Description:
  # This method generates mail to indicate that a document has been
  # attached.
  #
  # Parameters:
  #   design_review_document - the design review document record
  #
  ######################################################################
  #
  def attachment_update(design_review_document,
                        user,
                        sent_at = Time.now)

    @subject    = "A document has been attached for the " +
                    "#{design_review_document.design.name} design"
    @recipients = []
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    @bcc        = blind_cc

    cc          = add_role_members(['Manager', 'PCB Input Gate'])
    
    design_users = design_review_document.design.get_associated_users()
    recipients = []
    recipients << design_users[:designer].email  if design_users[:designer]
    recipients << design_users[:peer].email      if design_users[:peer]
    recipients << design_users[:pcb_input].email if design_users[:pcb_input]
    recipients += design_users[:reviewers].collect { |reviewer| reviewer.email }

    @recipients = recipients.uniq
    
    @cc = cc.uniq
    cc.each do |copied_to|
      if recipients.detect { |sent_to| sent_to == copied_to }
        @cc.delete_if { |cc_mail| cc_mail == copied_to }
      end
    end
    
    @body['document']    = design_review_document
    @body['attached_by'] = user.name

  end
  
  
  ######################################################################
  #
  # audit_update
  #
  # Description:
  # This method generates mail to indicate that the peer auditor has entered
  # a comment that the designer needs to respond to.
  #
  # Parameters:
  #   design_review_document - the design review document record
  #
  ######################################################################
  #
  def audit_update(design_check,
                   comment,
                   designer,
                   peer,
                   sent_at = Time.now)

    @subject    = design_check.audit.design.name +
                    " PEER AUDIT: A comment has been entered that requires " +
                    "your attention"
    @recipients = designer.email
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    @bcc        = blind_cc
    @cc         = peer.email

    @body['design_check'] = design_check
    @body['check']        = design_check.check
    @body['comment']      = comment

  end
  
  
  ######################################################################
  #
  # originator_board_design_entry_deletion
  #
  # Description:
  # This method generates mail to indicate that the peer auditor has entered
  # a comment that the designer needs to respond to.
  #
  # Parameters:
  #   board_design_entry_name - the name of the board design entry
  #   originator              - the user record for the originator
  #   sent_at                 - the time of the event
  #
  ######################################################################
  #
  def originator_board_design_entry_deletion(board_design_entry_name,
                                             originator,
                                             sent_at = Time.now)

    @subject    = "The #{board_design_entry_name} has been removed from the" +
                  " PCB Engineering Entry list"
                  
    @recipients = add_role_members(['PCB Input Gate'])
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    @bcc        = blind_cc
    @cc         = [originator.email] + add_role_members(['Manager'])

    @body['entry_name'] = board_design_entry_name
    @body['originator'] = originator

  end
  
  
  ######################################################################
  #
  # board_design_entry_return_to_originator
  #
  # Description:
  # This method generates mail to indicate that the processor returned
  # the board design entry to the originator.
  #
  # Parameters:
  #   board_design_entry - the board design entry
  #   processor          - the user record for the PCB input gate
  #   sent_at            - the time of the event
  #
  ######################################################################
  #
  def board_design_entry_return_to_originator(board_design_entry,
                                              processor,
                                              sent_at = Time.now)

    @subject    = "The #{board_design_entry.design_name} design entry has been returned by PCB"
    
    originator  = User.find(board_design_entry.originator_id)          
    @recipients = [originator.email]
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    @bcc        = blind_cc
    @cc         = add_role_members(['PCB Input Gate', 'Manager'])

    @body['board_design_entry'] = board_design_entry
    @body['processor']          = processor

  end
  
  
  ######################################################################
  #
  # board_design_entry_submission
  #
  # Description:
  # This method generates mail to indicate that a board design entry has 
  # been submitted to PCB Design.
  #
  # Parameters:
  #   board_design_entry - the board design entry
  #   sent_at            - the time of the event
  #
  ######################################################################
  #
  def board_design_entry_submission(board_design_entry,
                                    sent_at = Time.now)
                                    
    originator = User.find(board_design_entry.originator_id)

    @subject    = "The #{board_design_entry.design_name} has been submitted for " +
                  "entry to PCB Design"
                  
    @recipients = add_role_members(['PCB Input Gate', 'Manager'])
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    @bcc        = blind_cc
    @cc         = [originator.email, 'lisa_austin@notes.teradyne.com']

    @body['board_design_entry'] = board_design_entry
    @body['originator']         = originator

  end
  
  
  ######################################################################
  #
  # snapshot
  #
  # Description:
  # This method generates mail to DTG whenever a user encounters an 
  # application error.
  #
  # Parameters:
  #   exception - the exception record
  #   trace     - to provide the backtrace information
  #   session   - to provide a dump of the session record
  #   params    - the params passed to the action
  #   env       - the http environment
  #
  ######################################################################
  #
  def snapshot(exception,
               trace,
               session,
               params,
               env,
               sent_on = Time.now)

    content_type "text/html"
    
    @recipients = ['paul_altimonte@notes.teradyne.com']
    @from       = Pcbtr::SENDER
    @subject    = "[Error] exception in #{env['REQUEST_URI']}"
    @sent_on    = sent_on
    
    @body['exception'] = exception
    @body['trace']     = trace
    @body['session']   = session
    @body['params']    = params
    @body['env']       = env
  
  end
  
  
  ######################################################################
  #
  # reviewer_modification_notification
  #
  # Description:
  # This method generates mail to let both the new review and the old
  # reviewer know that they design review has been reassigned.
  #
  # Parameters:
  #   design_review - the design review record
  #   role          - the role record
  #   old_reviewer  - the user record for the old reviewer
  #   new_reviewer  - the user record for the new reviewer
  #   sent_at            - the time of the event
  #
  ######################################################################
  #
  def reviewer_modification_notification(design_review, 
                                         role, 
                                         old_reviewer, 
                                         new_reviewer,
                                         user,
                                         sent_at = Time.now)
  
    @subject    = role.display_name + " reviewer changed for " +
                  design_review.design.name + ' ' + design_review.review_type.name +
                  " Design Review"
    
    @recipients = [new_reviewer.email]
    @from       = Pcbtr::SENDER
    @sent_on    = sent_at
    @headers    = {}
    @bcc        = blind_cc
    @cc         = [old_reviewer.email] + add_role_members(['PCB Input Gate', 'Manager'])

    @body['new_reviewer']  = new_reviewer.name
    @body['old_reviewer']  = old_reviewer.name
    @body['design_review'] = design_review
    @body['user']          = user
    @body['role']          = role
    
  end
  
  
  ######################################################################
  #
  # oi_assignment_notification
  #
  # Description:
  # This method generates mail to indicate that an outsource instruction
  # has been assigned.
  #
  # Parameters:
  #   oi_assignment_list - the outsource assignment list 
  #   sent_at            - the time of the event
  #
  ######################################################################
  #
  def oi_assignment_notification(oi_assignment_list,
                                 sent_on = Time.now)
  
    design = oi_assignment_list[0].oi_instruction.design
    
    assignment  = oi_assignment_list.size == 1 ? 'Assignment' : 'Assignments'
    @subject    = "Work #{assignment} Created for the " + design.name
    @recipients = oi_assignment_list[0].user.email
    @from       = Pcbtr::SENDER
    @sent_on    = sent_on
    @headers    = {}
    @bcc        = blind_cc
    @cc         = (add_role_members(['PCB Input Gate', 'Manager', 'HCL Manager']) +
                   [oi_assignment_list[0].oi_instruction.user.email]) - [@recipients]

    @body['lead_designer']      = oi_assignment_list[0].user
    @body['design']             = design
    @body['oi_assignment_list'] = oi_assignment_list
  
  end
  
  
  ######################################################################
  #
  # oi_task_update
  #
  # Description:
  # This method generates mail to indicate that an outsource instruction
  # assignment has been updated.
  #
  # Parameters:
  #   assignment - the assignment record that was just updated
  #   originator - the user record of the person who made the update
  #   completed  - a flag to indicate that the assignment has been set
  #                to complete when true
  #   reset      - a flag to indicate that the assignment has been reset
  #                when true
  #   sent_at    - the time of the event
  #
  ######################################################################
  #
  def oi_task_update(assignment, 
                     originator, 
                     completed, 
                     reset,
                     sent_on     = Time.now)
  
    @subject    = "#{assignment.oi_instruction.design.name}:: " + 
                  'Work Assignment Update'
    @subject   += " - Completed" if completed
    @subject   += " - Reopened"  if reset

    case
    when assignment.oi_instruction.user_id == originator.id
      @recipients = [assignment.user.email]
    when assignment.user_id == originator.id
      @recipients = [assignment.oi_instruction.user.email]
    end

    @from       = Pcbtr::SENDER
    @sent_on    = sent_on
    @headers    = {}
    @bcc        = blind_cc
    @cc         = (add_role_members(['PCB Input Gate', 'Manager', 'HCL Manager']) +
                   [originator.email]) - @recipients

    @body['assignment'] = assignment
    
                  
  end
  
  
  ######################################################################
  #
  # broadcast_message
  #
  # Description:
  # This method generates a broadcast mail message to the users in the
  # recipient list.
  #
  # Parameters:
  #   subject    - the mail subject
  #   message    - the mail message
  #   recipients - a list of users to send the message too
  #
  ######################################################################
  #
  def broadcast_message(subject,
                        message,
                        recipients,
                        sent_on     = Time.now)
  
    @subject         = subject
    @from            = Pcbtr::SENDER
    @sent_on         = sent_on
    @headers         = {}
    @bcc             = recipients.uniq.collect { |u| u.email }
    @body['message'] = message
    
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
    role_list.each do |role_name|
      cc_list += Role.find_by_name(role_name).active_users.collect do |member|
        member.email
      end
    end

    cc_list.uniq
    
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

    design_review_results.each do |dr_result|
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

    cc_list = [design_review.designer.email]

    design_review.design.board.users.each do |cc|
      cc_list << cc.email if cc.active?
    end

    cc_list += add_role_members(['Manager', 'PCB Input Gate'])
    return cc_list.uniq
    
  end


  ######################################################################
  #
  # copy_to_on_milestone
  #
  # Description:
  # Given a board this method will return a list of the
  # people who should be CC'ed on all milestone mails
  #
  # Parameters:
  #   board - the board to get the milestone CC list for.
  #
  ######################################################################
  #
  def copy_to_on_milestone(board)
    add_board_reviewer(board,
                       ['Program Manager',
                        'Hardware Engineering Manager'])
  end
  
  
  ######################################################################
  #
  # add_board_reviewer
  #
  # Description:
  # Given a board and a list of roles this function will load the
  # CC list with users associated with the role for that board.
  #
  # Parameters:
  #   board - the board record.
  #   roles - a list of roles.  The associated user's email will be
  #           added to the CC list.
  #
  ######################################################################
  #
  def add_board_reviewer(board, roles)
  
    cc_list   = []
    role_list = Role.find(:all)

    roles.each do |role|

      reviewer_role  = role_list.detect { |r| r.name == role }
      board_reviewer = board.board_reviewers.detect { |br| br.role_id == reviewer_role.id }

      if board_reviewer && board_reviewer.reviewer_id?
        cc_list << User.find(board_reviewer.reviewer_id).email
      end
    
    end
    
    return cc_list
    
  end
  
  
  ######################################################################
  #
  # blind_cc_list
  #
  # Description:
  # Provides the list of email address that belong on the blind CC list.
  #
  # Parameters:
  #   None
  #
  ######################################################################
  #
  def blind_cc
    ['paul_altimonte@notes.teradyne.com']
  end


end
