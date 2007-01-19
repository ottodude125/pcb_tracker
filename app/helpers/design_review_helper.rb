module DesignReviewHelper


  def display_approval_options(review_status_id)

    review_status = ReviewStatus.find(review_status_id)

    in_review = ReviewStatus.find_by_name("In Review")
    review_outstanding = @review_results.find { |rr| 
      rr.reviewer_id == session[:user].id && rr.result == 'No Response'
    }

    return ((review_status.name == "Pending Repost" ||
             review_status.name == "Review On-Hold" ||
             review_status.name == "In Review") &&
            review_outstanding)

  end


  def design_review_reassignable(design_review)

    incomplete = ['No Response', 'WITHDRAWN']
    reassignable = false
    role_ids = []
    @session[:user].roles.each { |role| role_ids.push(role.id) }
    review_results = DesignReviewResult.find_all_by_design_review_id(
                       design_review.id)
    for review_result in review_results
      if role_ids.include?(review_result.role_id)
        reassignable = incomplete.include?(review_result.result)
      end
      break if reassignable
    end
   
    return reassignable
  end


  def display_role(review_result)
    review_result[:result] == "No Response"
  end


  def pending_repost(review_status_id)
    review_status = ReviewStatus.find(review_status_id)
    return review_status.name == "Pending Repost"
  end



  def reviewer_peer(review_results)

    for my_role in @session[:roles]
      is_peer = review_results.find { |rr| rr.role_id == my_role.id }
      break if is_peer
    end

    return is_peer

  end
  
  
  def permitted_to_update_cc_list
  
    return session[:active_role].name == 'Admin'     || 
           session[:active_role].name == 'Designer'  ||
           session[:active_role].name == 'PCB Admin' ||
           is_manager
  end
  
  
  def permitted_to_remove_self_from_cc_list
  
    return @users_copied.include?(@session[:user])
    
  end


  def permitted_to_add_self_to_cc_list(reviewer_list)
  
    return ( !@users_copied.include?(@session[:user]) &&
             !reviewer_list.find { |r| r[:id] == @session[:user].id } )
    
  end


  def pre_art_pcb(design_review, review_results)
      
    return (review_results.find { |rr| rr.role.name == "PCB Design" } &&
            design_review.review_type.name == "Pre-Artwork")
    
  end


  def get_design_info(design)

    # Find the first design review that is not a Pre-Artwork
    pre_art = ReviewType.find_by_name("Pre-Artwork")
    
    for design_review in design.design_reviews

      next if design_review.review_type_id == pre_art.id
      break
      
    end

    return {:priority_id => design_review.priority_id,
            :designer_id => design_review.designer_id}
  end


end
