########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_review.rb
#
# This file maintains the state for design reviews.
#
# $Id$
#
########################################################################

class DesignReview < ActiveRecord::Base

  belongs_to :design
  belongs_to :design_center
  belongs_to :priority
  belongs_to :review_status
  belongs_to :review_type

  has_many(:design_review_comments, :order => 'created_on DESC')
  has_many(:design_review_results)
  
  
  SUNDAY   = 0
  SATURDAY = 6


  ######################################################################
  #
  # review_name
  #
  # Description:
  # This method returns the review (type) name for the object.
  #
  # Parameters:
  # None
  #
  # Return value:
  # The review (type) name
  #
  ######################################################################
  #
  def review_name
    if self.review_type_id_2 == 0
      self.review_type.name
    else
      self.review_type.name + '/' + ReviewType.find(self.review_type_id_2).name
    end
  end
  
  
  ######################################################################
  #
  # time_on_hold
  #
  # Description:
  # This method returns the number of seconds that a design has been
  # on hold
  #
  # Parameters:
  # current_time - the current time
  #
  # Return value:
  # If the design_review is on hold then the number of second the design
  # has been on hold is return.  Otherwise, a 0 is returned
  #
  ######################################################################
  #
  def time_on_hold(current_time = Time.now)

    on_hold = ReviewStatus.find_by_name('Review On-Hold')

    return 0 if self.review_status_id != on_hold.id
    age_in_seconds(self.placed_on_hold_on, current_time)
   
  end
  
  
  ######################################################################
  #
  # time_on_hold_total
  #
  # Description:
  # This method returns the running total of the number of seconds that 
  # a design has been on hold
  #
  # Parameters:
  # current_time - the current time
  #
  # Return value:
  # The running total for the number of seconds that have elapsed while
  # the design review is on hold
  #
  ######################################################################
  #
  def time_on_hold_total(current_time = Time.now)
    (self.total_time_on_hold + self.time_on_hold(current_time))
  end
  

  ######################################################################
  #
  # place_on_hold
  #
  # Description:
  # This method sets the design_review status to on-hold sets the 
  # placed_on_hold_on field to the current time
  #
  # Parameters:
  # current_time - the current time
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def place_on_hold(current_time = Time.now)
    self.review_status_id  = ReviewStatus.find_by_name('Review On-Hold').id
    self.placed_on_hold_on = current_time
    self.update
  end
  
    
  ######################################################################
  #
  # remove_from_hold
  #
  # Description:
  # This method sets the design_review status to the value specified by the
  # review_status_id parameter and it updates the field that keeps track
  # the running total of time on hold for the design review
  #
  # Parameters:
  # review_status_id - the new status for the design review
  # current_time     - the current time
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def remove_from_hold(review_status_id, current_time = Time.now)
  
    if self.review_status_id == ReviewStatus.find_by_name('Review On-Hold').id
      self.review_status_id    = review_status_id
      self.total_time_on_hold += age_in_seconds(self.placed_on_hold_on, current_time)
      self.update
    end

  end
  
  
  ######################################################################
  #
  # age
  #
  # Description:
  # This method returns the number of work days since the design review
  # was originally posted.
  #
  # Parameters:
  # None
  #
  # Return value:
  # The number of workdays in seconds since the design review was posted.
  #
  ######################################################################
  #
  def age(end_time = Time.now)
    age_in_seconds(self.created_on, end_time)
  end
  
  
  ######################################################################
  #
  # review_results_by_role_name
  #
  # Description:
  # This method returns the review results sorted by the review role
  # for the design review object.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of design_review_result objects for the design review.
  #
  ######################################################################
  #
  def review_results_by_role_name
    self.design_review_results.sort_by { |rr| rr.role.display_name }
  end
  
  
  ######################################################################
  #
  # reviewers
  #
  # Description:
  # This method returns a list of user records.  The list is uniq and if
  # the sorted flag is set to TRUE it is sorted by the user's last name.
  #
  # Parameters:
  # reviewer_list - A list of user records.  The default value is an 
  #                 empty array
  # sorted        - A flag that indicates whether or not to sort the 
  #                 reviewer_list by the last names
  #
  # Return value:
  # A list of reviewers (user records) for the design review
  #
  ######################################################################
  #
  def reviewers(reviewer_list = [], sorted = false)
  
    self.design_review_results.each do |review_result|
      if not reviewer_list.detect { |reviewer| reviewer.id == review_result.reviewer_id }
        reviewer_list << User.find(review_result.reviewer_id)
      end
    end
    
    reviewer_list = reviewer_list.sort_by { |reviewer| reviewer.last_name } if sorted
    
    reviewer_list.uniq
    
  end
  
  
  ######################################################################
  #
  # generate_reviewer_selection_list
  #
  # Description:
  # This method returns a list review groups for the design review.
  # See "Return value" for the details.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of review groups containing the role display name and id,
  # the assigned reviewer's id, and a list of the reviewers for the 
  # role.
  #
  ######################################################################
  #
  def generate_reviewer_selection_list()
    self.design_review_results.sort_by { |rr| rr.role.display_name }
  end


  ######################################################################
  #
  # designer
  #
  # Description:
  # This method returns the user record for the designer who is 
  # listed for the design.  If there is no listed designer, a user
  # record is created and the name is set to 'Not Assigned'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A User record for the designer.
  #
  ######################################################################
  #
  def designer
  
    if self.designer_id > 0
      User.find(self.designer_id)
    else
      User.new(:first_name => 'Not', :last_name => 'Assigned')
    end
  
  end


  ######################################################################
  #
  # on_hold?
  #
  # Description:
  # This method checks to see if the design review is on hold
  #
  # Parameters:
  # None
  #
  # Return value:
  # A boolean value that indicates that design review is on hold
  # when TRUE
  #
  ######################################################################
  #
  def on_hold?
    self.review_status_id == ReviewStatus.find_by_name('Review On-Hold').id
  end
  
  
  ######################################################################
  #
  # pending_repost?
  #
  # Description:
  # This method checks to see if the design review is in the 
  # 'pending repost' state
  #
  # Parameters:
  # None
  #
  # Return value:
  # A boolean value that indicates that design review is pending repost
  # when TRUE
  #
  ######################################################################
  #
  def pending_repost?
    self.review_status_id == ReviewStatus.find_by_name('Pending Repost').id
  end
  
  
  ######################################################################
  #
  # in_review?
  #
  # Description:
  # This method checks to see if the design review is in the 
  # 'in review' state
  #
  # Parameters:
  # None
  #
  # Return value:
  # A boolean value that indicates that design review is in review
  # when TRUE
  #
  ######################################################################
  #
  def in_review?
    self.review_status_id == ReviewStatus.find_by_name('In Review').id
  end
  
  
  ######################################################################
  #
  # review_complete?
  #
  # Description:
  # This method checks to see if the design review is in the 
  # 'review completed' state
  #
  # Parameters:
  # None
  #
  # Return value:
  # A boolean value that indicates that design review is completed
  # when TRUE
  #
  ######################################################################
  #
  def review_complete?
    self.review_status_id == ReviewStatus.find_by_name('Review Completed').id
  end
  
  
  ######################################################################
  #
  # age_in_days
  #
  # Description:
  # This method returns the age of a design_review in work days
  #
  # Parameters:
  # current_time - the time stamp for the current time
  #
  # Return value:
  # A string representing the number of days between the time the 
  # design review was post and the current time.
  #
  ######################################################################
  #
  def age_in_days(current_time = Time.now)

    delta = age_in_seconds(self.created_on, current_time)

    sprintf("%4.1f", delta.to_f / 1.day)  

  end
  
  
  ######################################################################
  #
  # set_valor_reviewer
  #
  # Description:
  # This method assigns the valor review to the peer auditor
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def set_valor_reviewer

    valor_role = Role.find_by_name('Valor')
    valor_review_result = self.design_review_results.detect do |rr|
                            rr.role_id == valor_role.id
                          end

    if valor_review_result
      valor_review_result.reviewer_id = self.design.peer_id
      valor_review_result.update
    end

  end
  
  
  ######################################################################
  #
  # post_review?
  #
  # Description:
  # This method reports whether or not the design review can be 
  # posted.
  #
  # Parameters:
  # next_review - the next design review in the cycle
  # user        - the current user
  #
  # Return value:
  # A boolean value that indicates that the user can post the review 
  # when TRUE.
  #
  ######################################################################
  #
  def post_review?(next_review, user)

    (next_review                        && 
     !self.review_locked?               && 
     next_review.designer_id == user.id &&
     next_review.review_type_id == next_review.design.phase_id)

  end


  ######################################################################
  #
  # review_locked?
  #
  # Description:
  # This method determines whether or not the design review can be posted
  # for review.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A boolean value that indicates that the design review is locked when
  # TRUE.
  #
  ######################################################################
  #
  def review_locked?
  
    (self.review_type.name == "Final" && 
     (!(self.design.audit.skip? || self.design.audit.auditor_complete?) ||
      !self.design.work_assignments_complete?))

  end
  
  
  ######################################################################
  #
  # role_reviewer
  #
  # Description:
  # This method retrieves the reviewer for the role that is passed
  # in
  #
  # Parameters:
  # role - the role record
  #
  # Return value:
  # A user record for the role reviewer.  If the design review does not
  # have a reviewer for the identified role then nil is returned.
  #
  ######################################################################
  #
  def role_reviewer(role)
    result = self.design_review_results.detect { |result| result.role_id == role.id }
    return User.find(result.reviewer_id) if result
  end
  
  
  ######################################################################
  #
  # comments_by_role
  #
  # Description:
  # This method retrieves the design review comments for the roles 
  # identified in the role_list parameter.
  #
  # Parameters:
  # role_list - a list of role names
  #
  # Return value:
  # A list of design review comments associated with the design review 
  # and the roles identified in the role_list.
  #
  ######################################################################
  #
  def comments_by_role(role_list)

    role_names = (role_list.class == String) ? [role_list] : role_list
    
    role_users = []
    role_names.each { |name| role_users += Role.find_by_name(name).users }
    role_users.uniq!

    comment_list = []
    self.design_review_comments.each do |comment|
      comment_list << comment if role_users.detect { |ru| ru.id == comment.user_id }
    end
    
    comment_list
  
  end
  

######################################################################
######################################################################
private
######################################################################
######################################################################


  ######################################################################
  #
  # age_in_seconds
  #
  # Description:
  # This method computes the number of seconds between the start_time 
  # and the end_time.
  #
  # Parameters:
  # start_time - the beginning of the time interval
  # end_time   - the end of the time interval
  #
  # Return value:
  # The number of seconds (representing work days) between the 
  # start_time and the end_time.
  #
  ######################################################################
  #
  def age_in_seconds(start_time, end_time)

    return 0 if start_time >= end_time
    
    # If the start time is a weekend, initialize the delta to 
    # zero.  Otherwise, initialize delta to the number of seconds
    # between the start time and midnight of the next day.
    day = start_time.strftime("%w").to_i
    if day == SUNDAY || day == SATURDAY
      delta = 0
    else
      #delta = start_time.midnight.tomorrow - start_time
      midnight_tomorrow = start_time.tomorrow.midnight
      if end_time > midnight_tomorrow
        delta = midnight_tomorrow - start_time
      else
        delta = end_time - start_time
      end
    end

    # Advance start time to midnight.
    start_time = start_time.tomorrow.midnight
    
    while (end_time - start_time) >= 1.day
      day         = start_time.strftime("%w").to_i
      # Only increment for a weekday
      delta      += 1.day if SUNDAY < day && day < SATURDAY 
      start_time += 1.day
    end
    
    if end_time > start_time
      # Pick up the remaining time
      day    = start_time.strftime("%w").to_i
      delta += end_time - start_time if SUNDAY < day && day < SATURDAY 
    end
    
    delta.to_i
  
  end


end
