module DesignReviewHelper


  def display_approval_options(review_status_id)

    review_status = ReviewStatus.find(review_status_id)

    in_review = ReviewStatus.find_by_name("In Review")
    review_outstanding = @review_results.find { |rr| 
      rr.reviewer_id == @session[:user].id && rr.result == 'No Response'
    }

    return ((review_status.name == "Pending Repost" ||
             review_status.name == "In Review") &&
            review_outstanding)

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
  
    return @session[:active_role] == 'Admin' || 
           @session[:active_role] == 'Designer'
  end
  
  
  def permitted_to_remove_self_from_cc_list
  
    return @users_copied.include?(@session[:user])
    
  end


  def permitted_to_add_self_to_cc_list
  
    return  !@users_copied.include?(@session[:user])
    
  end


  def pre_art_pcb(design_review, review_results)
      
    return (review_results.find { |rr| rr.role.name == "PCB Design" } &&
            design_review.review_type.name == "Pre-Artwork")
    
  end


end
