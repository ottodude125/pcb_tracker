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
require 'net/http'

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
    review_list = Hash.new
    
    active_reviews.each do |dr|
    
      # Remove the results if they have been addressed      
      dr.design_review_results.delete_if { |drr| drr.result != 'No Response' &&
                                                 drr.result != 'Commented'}
     
      dr.design_review_results.each do |drr|
        reviewer = drr.reviewer
                
        if !review_list.include?(reviewer.id)
          review_list[reviewer.id] = {:user => reviewer, :results => []}
        end

        review_list[reviewer.id][:results] << drr
      end     
    end
    
    
    review_list = review_list.sort_by { |userid, result| result[:user].last_name }
    
    count = 0
    
    review_list.each do |userid, data|
      #PingMailer::ping_reviewer(data).deliver    
      #sleep(1)
    end
    
    #sleep(10)

    PingMailer::ping_summary(review_list, active_reviews).deliver

  end

  ######################################################################
  #
  # send_summary
  #
  # Description:
  # Goes through all of the design reviews and sends a summary to the 
  # managers and PCB input gates.  Called at the end of "send_message".
  #
  ######################################################################
  #
  def self.send_summary()

    in_review      = ReviewStatus.find_by_name("In Review")
    active_reviews = DesignReview.find( :all,
                                        :conditions => "review_status_id=#{in_review.id}",
                                        :order      => "created_on" )

    review_list = Hash.new
    active_reviews.each do |dr|
    
      # Remove the results if they have been addressed
      dr.design_review_results.delete_if { |drr| ! drr.no_response? }
      #drr.result != 'No Response' and drr.result != 'Commented'

      dr.design_review_results.each do |drr|
        reviewer = drr.reviewer
                
        if !review_list.include?(reviewer.id)
          review_list[reviewer.id] = {:user => reviewer, :results => []}
        end

        review_list[reviewer.id][:results] << drr
      end     
    end

    review_list = review_list.sort_by { |userid, result| result[:user].last_name }
    
    PingMailer::ping_summary(review_list, active_reviews).deliver

  end

  def self.check_design_centers
    designs = Design.find_all_active

    summary = { :link_good => [], :link_bad => [] }
    
    designs.each do |design|
      next unless design.design_center
      next unless design.design_center.pcb_path
      code = ""
      
      Net::HTTP.start('boarddev.teradyne.com') do |http|
        response = http.get("/surfboards/#{design.design_center.pcb_path}/#{design.directory_name}/")
        code = response.code
      end
      
      if code == "200" || code == "301"
        summary[:link_good] << design
      else
        summary[:link_bad]  << design
      end
    end

    summary[:link_good].sort_by { |d| d.directory_name }
    summary[:link_bad].sort_by  { |d| d.directory_name }
    
    PingMailer::ping_design_center_summary(summary).deliver
  
  end
  
  ######################################################################
  #
  # send_test
  #
  # Description:
  # Sends a test message to the users specified in the argument list
  #
  ######################################################################
  #
  def self.send_test(*addresses)
      PingMailer::send_test(addresses).deliver    
    end
end
