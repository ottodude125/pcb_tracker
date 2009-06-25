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
      dr.design_review_results.delete_if { |drr| drr.result != 'No Response' &&
                                                 drr.result != 'Commented'}
      
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
  def self.send_summary()

    in_review      = ReviewStatus.find_by_name("In Review")
    active_reviews = DesignReview.find( :all,
                                        :conditions => "review_status_id=#{in_review.id}",
                                        :order      => "created_on" )

    user_list = []
    active_reviews.each do |dr|
    
      # Remove the results if they have been addressed
      dr.design_review_results.delete_if { |drr| ! drr.no_response? }
      #drr.result != 'No Response' and drr.result != 'Commented'

      dr.design_review_results.each do |drr|
        reviewer = drr.reviewer
        user_list << reviewer if !user_list.include?(reviewer)
        user = user_list.detect { |u| u.id == reviewer.id }
        user[:results] = [] if ! user[:results]
        user[:results] << drr
      end

    end

    user_list = user_list.sort_by { |u| u.last_name }
    
    TrackerMailer::deliver_ping_summary(user_list, active_reviews)

  end

  def self.check_design_centers

    new_release = false
    h = Net::HTTP::new("boarddev.teradyne.com") if !new_release

    if Time.now.strftime("%A") == "Monday"  && "Fred" == "Barney"
      designs = Design.find(:all)
    else
      designs = Design.find_all_active
    end

    summary = { :link_good => [], :link_bad => [] }
    designs.each do |design|
      next unless design.design_center
      next unless design.design_center.pcb_path
      if new_release
        if design.design_center.data_found?
          summary[:link_good] << design
        else
          summary[:link_bad]  << design
        end
      else
        #review = design.design_reviews.detect { |r| r.review_type.name == design.phase.name }
        #if review
          link = "/surfboards/#{design.design_center.pcb_path}/#{design.directory_name}/public/"
        #else
        #  link = '/no_good/'
        #end
        if h.get(link).code == "200"
          summary[:link_good] << design
        else
          summary[:link_bad]  << design
        end
      end
    end

    summary[:link_good].sort_by { |d| d.directory_name }
    summary[:link_bad].sort_by  { |d| d.directory_name }
    TrackerMailer::deliver_ping_design_center_summary(summary)

  end


end
