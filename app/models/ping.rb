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
  # workdays
  #
  # Description:
  # Given a start and stop time, this method computes the work days 
  # between the 2 times.
  #
  # Parameters:
  # start_time - the beginning of the time slice
  # end_time   - the end of the time slice
  #
  # Returns:
  # The number of days between the 2 time stamps.
  #
  ######################################################################
  #
  def self.workdays (start_time, end_time)
    if end_time - start_time > 43200
      workdays = 0
    else
      workdays = -1
    end
    while start_time <= end_time
      day = start_time.strftime("%w").to_i
      workdays += 1 if day > 0 && day < 6
      # Add a day.
      start_time += 86400
    end
    workdays
  end


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
        age = workdays(design_review.reposted_on, Time.now)

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
