########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: ipd_post_mailer.rb
#
# This file contains the methods to generate email for In-Process Dialogue.
#
# $Id$
#
########################################################################

class IpdPostMailer < ActionMailer::Base


  ######################################################################
  #
  # update
  #
  # Description:
  # This method generates the mail indicate that an update has been
  # made to an In-Process Dialogue thread.
  #
  # Parameters from @params
  #   root_post - The root of the IPD thread.
  #
  ######################################################################
  #
  def update(root_post)
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
    @sent_on    = Time.now
    @headers    = {}

    cc         = [poster.email]
    manager_role = Role.find_by_name("Manager")
    for manager in manager_role.users
      cc.push(manager.email)
    end

    for child in root_post.direct_children
      cc.push(child.user.email)
    end
    @cc = cc.uniq
  end


end
