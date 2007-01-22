########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: ping.rb
#
# This file maintains the state for ping
#
# $Id$
#
########################################################################

class Ping < ActiveRecord::Base


  ######################################################################
  #
  # send_message
  #
  # Description:
  # Goes through all of the design reviews and sends a reminder to the
  # reviewer.  A summary is sent to the managers and PCB input gates.
  #
  ######################################################################
  #
  def self.send_message()

    in_review      = ReviewStatus.find_by_name("In Review")
    active_reviews = DesignReview.find_all_by_review_status_id(in_review.id,
                                                               "created_on ASC")

    ping_list   = {}
    for design_review in active_reviews
      for review_result in design_review.design_review_results
        next if review_result.result != "No Response"
        design_review = review_result.design_review
        age = design_review.age/1.day

        if ((age > 3)                                                 &&
            (design_review.priority.name == 'High')                   ||
            (design_review.priority.name == 'Medium' && age % 2 == 0) ||
            (design_review.priority.name == 'Low'    && age % 3 == 0))
            
          if !ping_list[review_result.reviewer_id]
            ping_list[review_result.reviewer_id] = 
              {:reviewer    => User.find(review_result.reviewer_id),
               :review_list => []}
          end
          
          ping_info = {:design_review => design_review,
                       :role          => review_result.role.name,
                       :age           => age}
          ping_list[review_result.reviewer_id][:review_list].push(ping_info)
        end
      end
    end

    reviewer_list = []
    ping_list.each { |user_id, review_result_list|
      review_result_list[:review_list] =
        review_result_list[:review_list].sort_by{ |rr| rr[:age] }.reverse
      reviewer_list.push(review_result_list)
      TrackerMailer::deliver_ping_reviewer(review_result_list)
    }

    reviewer_list = reviewer_list.sort_by { |rr| rr[:reviewer].last_name }
    TrackerMailer::deliver_ping_summary(reviewer_list)

  end


end
