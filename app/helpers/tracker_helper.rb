########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: tracker_helper.rb
#
# This contains the helper methods for tracker views.
#
# $Id$
#
########################################################################
#
module TrackerHelper


  ######################################################################
  #
  # audit_locked_for_peer
  #
  # Description:
  # Returns true if the audit is not yet available for the peer 
  # reviewers.
  #
  ######################################################################
  #
  def audit_locked_for_peer(audit)

    if audit[:self]
      false
    else
      total_design_checks = 
        audit.checklist.designer_only_count + audit.checklist.designer_auditor_count
      
      audit.designer_completed_checks < audit.check_count[:designer]
    end
    
  end
  
  
  def assignment_info(row)
  
    assignment_list = row[1]
    design          = assignment_list[0].oi_instruction.design
    
    completed = 0
    assignment_list.each { |a| completed += 1 if a.complete? }
    
    return design, assignment_list.size, completed
  
  end


  ######################################################################
  #
  # get_my_results
  #
  # Description:
  # Returns a list of the user's results for the design review.
  #
  ######################################################################
  #
  def get_my_results(review_id)

    my_results = []

    review_results = DesignReviewResult.find_all_by_design_review_id(review_id)
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
  
  
  ######################################################################
  #
  # post_next_review_prompt?
  #
  # Description:
  # Returns a flag that indicates that the link to the next review 
  # in the cycle should be displayed
  #
  ######################################################################
  #
  def post_next_review_prompt?(design)
    
    # Get the design review identified by the phase id
    next_design_review = design.design_reviews.detect { |dr| design.phase_id == dr.review_type_id }
    
    review_states = ['In Review',
                     'Pending Repost',
                     'Review Completed',
                     'Review On-Hold']
    !next_design_review                                          ||
    !review_states.detect { |rs| rs == next_design_review.review_status.name }
     
  end
  
  
  ######################################################################
  #
  # final_review_locked?
  #
  # Description:
  # Returns a flag that indicates that the final review is locked when
  # TRUE.
  #
  ######################################################################
  #
  def final_review_locked?(design)

    if design.phase_id != Design::COMPLETE

      phase_review_type = ReviewType.find(design.phase_id)

      if phase_review_type.name != "Final"
        false
      else
        design.reload
        final_design_review = design.design_reviews.detect { |dr| dr.review_type_id == phase_review_type.id }
        final_design_review.review_locked?
      end
      
    else
      false
    end
    
  end


end
