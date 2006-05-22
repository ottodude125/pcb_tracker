module TrackerHelper


  def audit_locked_for_peer(audit)

    total_design_checks = 
      audit.checklist.designer_only_count + audit.checklist.designer_auditor_count
      
    audit.designer_completed_checks < total_design_checks

  end


  def review_locked(design_review)
    if design_review
      audit = design_review.design.audit
      is_final = design_review.review_type.name == "Final"
      is_final && !(audit.designer_complete? && audit.auditor_complete?)
    else
      false
    end
  end


  def get_my_results(review_id)

    my_results = []

    review_results = DesignReviewResult.find_all_by_design_review_id(
                       review_id)
    my_review_results = review_results.delete_if { |r| 
      r.reviewer_id != @session[:user].id 
    }

    inlude_role = my_review_results.size > 1

    my_review_results.each { |result|
      my_result = []
      my_result.push(result.result)
      my_result.push(' (' + result.role.name + ')') if inlude_role
      my_results.push(my_result)
    }


    return my_results
    
  end


end
