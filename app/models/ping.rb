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
    active_reviews = DesignReview.find( :all,
                                        :conditions => "review_status_id=#{in_review.id}",
                                        :order      => "created_on" )
                                      
    # Remove design review that should not be pinged
=begin
    active_reviews.delete_if do |dr| 
      ((dr.priority.name == 'Medium' && dr.age/1.day != 0) ||  # was 2
        dr.priority.name == 'Low'    && dr.age/1.day != 0)    # was 3
    end
=end
    
    
    user_list = []
    active_reviews.each do |dr|
    
      # Remove the results if they have been addressed      
      dr.design_review_results.delete_if { |drr| drr.result != 'No Response' }
      
      dr.design_review_results.each do |drr|
        reviewer = drr.reviewer
        user_list << reviewer if !user_list.include?(reviewer)
        user = user_list.detect { |u| u.id == reviewer.id }
        user[:results] = [] if !user[:results]
        user[:results] << drr
      end
      
    end
    
    user_list = user_list.sort_by { |u| u.last_name }
    
    user_list.each do |reviewer|
      TrackerMailer::deliver_ping_reviewer(reviewer)
      sleep(1)
    end
    
    sleep(10)

    TrackerMailer::deliver_ping_summary(user_list, active_reviews)

  end


end
