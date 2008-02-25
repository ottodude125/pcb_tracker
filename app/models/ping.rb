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
    
    # Remove any design reviews that have not been posted long enough to be 
    # pinged.
    active_reviews.delete_if { |dr| dr.age < 3.days }
    active_reviews.each do |design_review|

      age = design_review.age/1.day
      
      # Remove any reaults that have reviewer responses
      design_review.design_review_results.delete_if { |drr| drr.result != 'No Response' }
      design_review.design_review_results.each do |review_result|

        if ((design_review.priority.name == 'High')                   ||
            (design_review.priority.name == 'Medium' && age % 2 == 0) ||
            (design_review.priority.name == 'Low'    && age % 3 == 0))
        
          if !ping_list[review_result.reviewer_id]
            ping_list[review_result.reviewer_id] = 
              {:reviewer    => review_result.reviewer,
               :review_list => []}
          end
      
          ping_info = {:design_review => design_review,
                       :role          => review_result.role.display_name,
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

    summary_reviewer_list = []
    reviewer_list.each do |entry|
      entry[:review_list].each do |review|
        summary_reviewer_list << { :reviewer      => entry[:reviewer],
                                   :design_review => review[:design_review],
                                   :role          => review[:role],
                                   :age           => review[:age] }
      end
    end
    
    sleep(60)

    summary_reviewer_list      = summary_reviewer_list.sort_by { |rr| rr[:reviewer].last_name }
    summary_design_review_list = summary_reviewer_list.sort_by { |rr| rr[:design_review].design.directory_name }
    TrackerMailer::deliver_ping_summary(summary_reviewer_list, summary_design_review_list)

  end


end
