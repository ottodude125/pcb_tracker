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
  has_many(:posting_timestamps,     :order => 'posted_at')
  has_many(:design_review_results)
  has_many(:design_updates)
  
  
  SUNDAY   = 0
  SATURDAY = 6


  def self.http_object
    @@h = @@h ||= Net::HTTP::new("boarddev.teradyne.com")
    @@h
  end


  # Retrieve a list of all active design reviews
  #
  # :call-seq:
  #   active_design_reviews(user) -> [design_reviews]
  #
  #  Returns a list of design reviews.
  #
  def self.active_design_reviews
    status_in_review      = ReviewStatus.find_by_name('In Review')
    status_pending_repost = ReviewStatus.find_by_name('Pending Repost')
    status_on_hold        = ReviewStatus.find_by_name('Review On-Hold')

    @active_design_reviews = DesignReview.find(:all,
                                               :conditions => "review_status_id='#{status_in_review.id}'      OR " +
                                                              "review_status_id='#{status_pending_repost.id}' OR " +
                                                              "review_status_id='#{status_on_hold.id}'")
    @active_design_reviews = @active_design_reviews.sort_by { |dr| [dr.priority.value, -dr.age] }
    @active_design_reviews
  end


  # Retrieve a list of all active processed reviews for which the user is
  # assigned to perform at least one of the role reviews
  #
  # :call-seq:
  #   my_processed_reviews(user) -> [design_reviews]
  #
  #  Returns a list of design reviews.
  #
  def self.my_processed_reviews(user)
    DesignReview.active_design_reviews #unless @active_design_reviews
    my_processed_reviews = @active_design_reviews.to_ary.find_all { |dr| dr.is_reviewer?(user) }
    my_processed_reviews.delete_if { |dr| !dr.reviewer_is_complete?(user) }
    my_processed_reviews
  end


  # Retrieve a list of all active unprocessed reviews for which the user is
  # assigned to perform at least one of the role reviews
  #
  # :call-seq:
  #   my_unprocessed_reviews(user) -> [design_reviews]
  #
  #  Returns a list of design reviews.
  #
  def self.my_unprocessed_reviews(user)
    DesignReview.active_design_reviews #unless @active_design_reviews
    my_unprocessed_reviews = @active_design_reviews.to_ary.find_all { |dr| dr.is_reviewer?(user) }
    my_unprocessed_reviews.delete_if { |dr| dr.reviewer_is_complete?(user) }
  end

  
  # Retrieve a list of all active reviews for which the user is not assigned to
  # perform any of the role reviews
  #
  # :call-seq:
  #   reviews_assigned_to_peers(user) -> [design_reviews]
  #
  #  Returns a list of design reviews.
  #
  def self.reviews_assigned_to_peers(user)
    DesignReview.active_design_reviews #unless @active_design_reviews
    @active_design_reviews.to_ary.find_all { |dr| !dr.is_reviewer?(user) && dr.my_roles(user) != [] }
  end


  # Retrieve all design reviews that have been posted at least once.
  #
  # :call-seq:
  #   summary_data() -> {design_reviews}
  #
  #  Returns a hash of design reviewx accessed by the year and quarter.
  #
  def self.summary_data
    
    design_reviews = self.find( :all,
                                :conditions => "posting_count > 0" )
    
    sorted_by_quarter = {}
    
    design_reviews.each do |design_review|
      quarter = 'Q' + design_review.created_on.current_quarter.to_s
      year    = design_review.created_on.strftime("%Y")
      key     = year + quarter
      sorted_by_quarter[key] = [] if !sorted_by_quarter[key]
      sorted_by_quarter[key] << design_review
    end
    
    sorted_by_quarter

  end


  # Retrieve a list of design reviews that are active.
  #
  # :call-seq:
  #   in_process_design_reviews() -> [design_reviews]
  #
  #  Returns a list of design reviewx that are active
  #
  def self.in_process_design_reviews
    status_in_review = ReviewStatus.find(:first, :conditions => "name='In Review'")
    status_waived    = ReviewStatus.find(:first, :conditions => "name='Review Waived'")
    DesignReview.find(:all,
                      :conditions => "review_status_id='#{status_in_review.id}' OR " +
                                     "review_status_id='#{status_waived.id}'")
  end


  # Checks if design review review type is "Release"
  #
  # :call-seq:
  #   is_release_review?() -> [design_reviews]
  #
  #  Returns true or false if is "Release" review
  #
  def is_release_review?
    release_review = ReviewType.get_release
    self.review_type_id == release_review.id
  end

  # Checks if design review review type is "Final"
  #
  # :call-seq:
  #   is_final_review?() -> [design_reviews]
  #
  #  Returns true or false if is "Final" review
  #
  def is_final_review?
    final_review = ReviewType.get_final
    self.review_type_id == final_review.id
  end

  # Retrieve the roles that the user is a member of for the the review.
  #
  # :call-seq:
  #   my_roles(user) -> [role]
  #
  # Returns a list of role records 
  #
  def my_roles(user)
    user.roles & self.design_review_results.collect { |drr| drr.role }
  end


  # Retrieve the roles that the user is assigned to for the review
  #
  # :call-seq:
  #   my_assigned_roles(user) -> [role]
  #
  # Returns a list of role records
  #
  def my_assigned_roles(user)
    roles = []
    self.my_roles(user).each do |role|
      design_review_result = self.design_review_results.detect { |drr| drr.role == role }
      roles << role if design_review_result.reviewer == user
    end
    roles
  end


  # Retrieve the results for the roles that the user is assigned to for the review
  #
  # :call-seq:
  #   my_results(user) -> [design_review_result]
  #
  # Returns a list of design_review_result records
  #
  def my_results(user)
    self.design_review_results.to_ary.find_all { |drr| drr.reviewer == user }
  end


  # Retrieve the results for the peers of the user for the review
  #
  # :call-seq:
  #   my_peer_results(user) -> [design_review_result]
  #
  # Returns a list of design_review_result records
  #
  def my_peer_results(user)
    results = []
    (self.my_roles(user) - self.my_assigned_roles(user)).each do |role|
      results << self.design_review_results.detect { |drr| drr.role == role }
    end
    results
  end


  # Indicate if the reviewer has completed the review for all of the assigned
  # roles
  #
  # :call-seq:
  #   reviewer_is_complete?(user) -> boolean
  #
  # Returns a flag that indicate whether or not the user has completed the
  # review.
  #
  def reviewer_is_complete?(user)

    complete = true

    self.my_assigned_roles(user).each do |my_role|
      my_review_result = self.design_review_results.detect { |drr| drr.role == my_role }
      complete = my_review_result.positive_response?
      break if !complete
    end

    complete

  end


  # Indicate if the design review is active based the value in the review
  # status field
  #
  # :call-seq:
  #   active?() -> boolean
  #
  # The flag is set to true if the review status indicates that the design
  # review is active.
  #
  def active?
    name = self.review_status.name
    name == 'In Review' || name == 'Pending Repost' || name == 'Review On-Hold'
  end

  
  # Retrieve the comments entered by the user
  #
  # :call-seq:
  #   comments(user) -> [design_review_comment]
  #
  # A list of design_review_comments entered by the user
  #
  def comments(user)
    self.design_review_comments.to_ary.find_all { |comment| comment.user == user }
  end


  #
  # NOTE: inactive_reviewers?, results_with_inactive_users, and inactive_reviewers
  #       all depend on or set the @results_with_inactive_users global variable.
  #       This variable is set in inactive_reviewers.  The other two metheds that
  #       use it depend on it being set and will call inactive_reviewers to set it
  #       if it is not set.  This was done to cache the information.
  #

  # Indicate if there are inactive reviewers assigned to active design reviews
  #
  # :call-seq:
  #   inactive_reviewers?() -> boolean
  #
  # The flag is set to true if there are any inactive reviewers assigned to
  # active reviews
  #
  def inactive_reviewers?
    self.inactive_reviewers unless @results_with_inactive_users
    @results_with_inactive_users.size > 0
  end


  # Provide a list of reviewer results with inactive reviewers that are assigned
  # to active design reviews
  #
  # :call-seq:
  #   results_with_inactive_users() -> [design_review_result]
  #
  # An array of design review result records.  One for each of the inactive
  # reviewers assigned to the review
  #
  def results_with_inactive_users
    self.inactive_reviewers unless @results_with_inactive_users
    @results_with_inactive_users
  end

  # Provide a list with users on the cc_list and those eligible for the list
  #
  # :call-seq:
  #   results_with_inactive_users() -> [design_review_result]
  #
  # An hash of containing 3 arrays of users
  #   :reviewers  => {:name, :group, :last_name, :id }
  #   :copied     => [users]
  #   :not_copied => [users]
  #
  def mail_lists

    design = self.design
    # get the reviewer names, their functions and sort the list by the
    # reviewer's last name.
    reviewers_data = []
    reviewers = []
    self.design_review_results.each do |review_result|
      reviewers_data.push({ :name      => review_result.reviewer.name,
                       :group     => review_result.role.name,
                       :last_name => review_result.reviewer.last_name,
                       :id        => review_result.reviewer_id })
      user = User.find(review_result.reviewer_id)
      reviewers << user
    end
    reviewers.uniq

    #create the cc and not on cc lists
    users_on_cc_list = []
    #  start with all design users
    design.board.users.uniq.each { |user| users_on_cc_list << user unless reviewers.include?(user) }

    # Get all of the users, remove the reviewer names, and add the full name.
    users = User.find(:all,
      :conditions => 'active=1')

    users_copied     = []
    users_not_copied = []
    # see if each user is associated with the design
    # if so, they are on the cc list
    # otherwise, they are on the not_copied list
    users.each do |user|
      next if user.id == design.designer_id
      if users_on_cc_list.include?(user)
        users_copied.push(user)
      else
        users_not_copied.push(user)
      end
    end
    { :reviewers  => reviewers_data.sort_by { |r| r[:last_name] },
      :copied     => users_on_cc_list.sort_by { |u| u.last_name },
      :not_copied => users_not_copied.sort_by { |u| u.last_name }
    }
  end

  # Provide a list of inactive reviewers assigned to active design reviews
  #
  # :call-seq:
  #   inactive_reviewers() -> [user]
  #
  # An array of user records.  One for each of the inactive reviewers assigned
  # to the review
  #
  def inactive_reviewers
    unless @results_with_inactive_users
      @results_with_inactive_users =
        self.design_review_results.select { |drr| drr.reviewer && !drr.reviewer.active? }
    end
    @results_with_inactive_users.collect { |drr| drr.reviewer }
  end


  # Provide a list of review results that have not been processed
  #
  # :call-seq:
  #   unprocessed_results() -> [design_review_result]
  #
  # An array of design review result records
  #
  def unprocessed_results
    unprocessed_results = []
    self.design_review_results.each do |drr|
      unprocessed_results << drr unless drr.complete?
    end
    unprocessed_results.sort_by { |result| result.reviewer.last_name }
  end


  ######################################################################
  #
  # get_review_result
  #
  # Description:
  # This method returns the design review result for the role identified
  # by name.
  #
  # Parameters:
  # name - the role name
  #
  # Return value:
  # The design review result record for the desired role.
  #
  ######################################################################
  #
  def get_review_result(name)
    self.design_review_results.detect { |drr| drr.role.name == name }
  end
  
  
  # Determine if the user record passed is one of the reviewers.
  #
  # :call-seq:
  #   is_reviewer?(user) -> boolean
  #
  # Returns the TRUE if the user record passed in represents one 
  # of the reviewers.
  #
  def is_reviewer?(user)
    review_result = self.design_review_results.detect { |drr| drr.reviewer == user }
    review_result != nil
  end
  
  
  ######################################################################
  #
  # add_reviewers
  #
  # Description:
  # This method adds reviewers to a design review.
  #
  # Parameters:
  # board_team_list - a collection of users that are on the board team
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def add_reviewers(board_team_list)

    pcb_input_gate_role = Role.find(:first,
                                    :conditions => "name='PCB Input Gate'")
    
      board_team_list.each do |reviewer|
 
        next if !(reviewer.role.reviewer? && reviewer.required? && reviewer.user_id?)
        next if !reviewer.role.included_in_design_review?(self.design)
        next if !reviewer.role.review_types.include?(self.review_type)
        
        if reviewer.role_id == pcb_input_gate_role.id 
          reviewer_id = self.design.created_by
        else
          reviewer_id = reviewer.user_id
        end
          
        drr = DesignReviewResult.new(:reviewer_id => reviewer_id, :role_id => reviewer.role_id)
        self.design_review_results << drr

        # If the role (group) is set to have the peers CC'ed then update the 
        # design review.
        if reviewer.role.cc_peers?
          drr.role.users.each do |peer|
            next if (peer.id == drr.reviewer_id ||
                     !peer.active?              ||
                     self.design.board.users.include?(peer))
            self.design.board.users << peer
          end
        end

      end

  end
  
  
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

    on_hold = ReviewStatus.find(:first,
                                :conditions => "name='Review On-Hold'")

    return 0 if self.review_status_id != on_hold.id
    current_time.age_in_seconds(self.placed_on_hold_on)

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
    self.review_status     = ReviewStatus.find(:first, 
                                               :conditions => "name='Review On-Hold'")
    self.placed_on_hold_on = current_time
    self.save
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

    if self.review_status.name == 'Review On-Hold'
      self.review_status       = ReviewStatus.find(review_status_id)
      self.total_time_on_hold += current_time.age_in_seconds(self.placed_on_hold_on)
      self.save
      self.reload
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
  def reviewers(reviewer_list = [], sorted = true)
  
    reviewers = self.design_review_results.collect { |drr| drr.reviewer }
    if reviewer_list.size > 0
      new_reviewers  = reviewers - reviewer_list
      reviewer_list += new_reviewers
    else
      reviewer_list = reviewers
    end
    
    if sorted
      reviewer_list.sort_by { |reviewer| reviewer.last_name }
    else
      reviewer_list
    end

  end
  
  
  ######################################################################
  #
  # active_reviewers
  #
  # Description:
  # This method takes the list returned from reviewers and removes the
  # users who are no longer active and returns the results to the 
  # caller.
  #
  # Parameters:
  # sorted        - A flag that indicates whether or not to sort the 
  #                 reviewer_list by the last names
  #
  # Return value:
  # A list of active reviewers (user records) for the design review
  #
  ######################################################################
  #
  def active_reviewers(sorted = false)
    self.reviewers.delete_if { |r| !r.active? }
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
    rescue
      return User.new(:first_name => 'Unknown', :last_name => 'User')
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
    self.review_status_id == ReviewStatus.find(:first,
                                               :conditions => "name='Review On-Hold'").id
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
    self.review_status_id == ReviewStatus.find(:first,
                                               :conditions => "name='Pending Repost'").id
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
    self.review_status_id == ReviewStatus.find(:first,
                                               :conditions => "name='In Review'").id
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
    self.review_status_id == ReviewStatus.find(:first,
                                               :conditions => "name='Review Completed'").id
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
    delta = current_time.age_in_days(self.created_on)
    sprintf("%4.1f", delta)  
  end
  
  
  ######################################################################
  #
  # display_age_in_days
  #
  # Description:
  # This method returns a formatted string of the age of a design_review 
  # in work days.
  #
  # Parameters:
  # current_time - the time stamp for the current time
  #
  # Return value:
  # A string representing the number of days between the time the 
  # design review was post and the current time.  If the age is greater 
  # than the threshold then the font is formatted to be bold and red.
  #
  ######################################################################
  #
  def display_age_in_days(current_time = Time.now)
    delta = current_time.age_in_days(self.created_on)
    age   = sprintf("%4.1f", delta)
    if delta.to_i < 3
      return age
    else
      return '<font color="red"><b>' + age + '</b></font>'
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
    result = self.design_review_results.detect { |r| r.role_id == role.id }
    return User.find(result.reviewer_id) if result
  end
  
  
  # Set the reviewer for the design review/role
  #
  # :call-seq:
  #   set_reviewer(role, user) -> nil
  #
  #  Locates the review result for the role and updates the reviewer.  If no
  #  review result is found for the role, no action is taken.
  #
  # Exception
  #   ArgumentError - indicates that the user is not a member of the group (role).
  def set_reviewer(role, user)
    review_result = self.design_review_results.detect { |drr| drr.role_id == role.id }
    if review_result  && !review_result.complete?
      review_result.set_reviewer(user)
    end
  rescue
    raise
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
  #
  # reviewer_locked_in?
  #
  # Description:
  # This method checks the design review status and indicates whether
  # or not the reviewer is locked 
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the design review is closed, otherwise FALSE. 
  #
  ######################################################################
  #
  def reviewer_locked_in?
    ReviewStatus.closed_reviews.include?(self.review_status)
  end
  
  
  ######################################################################
  #
  # update_criticality
  #
  # Description:
  # This method updates the criticality (priority) attribute and 
  # records the  update.
  #
  # Parameters:
  # criticality - the new value for the criticality attribute
  # user        - the use who made the update
  #
  # Return value:
  # TRUE if the attribute was updated, otherwise FALSE.
  #
  ######################################################################
  #
  def update_criticality(criticality, user)
  
    if criticality && self.priority_id != criticality.id &&
       self.review_status.name != "Review Completed"
       
      self.record_update('Criticality', 
                         self.priority.name, 
                         criticality.name,
                         user)

      self.priority = criticality
      self.save
      
      true
    else
      false
    end
    
  end
  
  
  ######################################################################
  #
  # update_review_status
  #
  # Description:
  # This method updates the review status attribute and records the
  # update.
  #
  # Parameters:
  # status - the new value for the review status attribute
  # user   - the use who made the update
  #
  # Return value:
  # TRUE if the attribute was updated, otherwise FALSE.
  #
  ######################################################################
  #
  def update_review_status(status, user)
  
      if status && status.id != self.review_status_id &&
         (self.review_status.name == 'Review On-Hold' ||
          self.review_status.name == 'In Review')

        self.record_update('Review Status', 
                           self.review_status.name, 
                           status.name,
                           user)

        if self.review_status.name == 'Review On-Hold'
          self.remove_from_hold(status.id)
        elsif self.review_status.name == 'In Review'
          self.place_on_hold
        end
        self.save
        
        true
      else
        false
      end 
    
  end
  
  
  ######################################################################
  #
  # update_pcb_input_gate
  #
  # Description:
  # This method updates the designer attribute of a Pre-Artwork review
  # and records the update.
  #
  # Parameters:
  # pcb_input_gate - the new value for the designer (pcb_input_gate)
  #                  attribute
  # user           - the use who made the update
  #
  # Return value:
  # TRUE if the attribute was updated, otherwise FALSE.
  #
  ######################################################################
  #
  def update_pcb_input_gate(pcb_input_gate, user)

    if self.review_type.name == "Pre-Artwork" && 
       self.review_status.name != "Review Completed" &&
       pcb_input_gate && self.designer_id != pcb_input_gate.id

      self.record_update('Pre-Artwork Poster', 
                          self.designer.name, 
                          pcb_input_gate.name,
                          user)

      self.designer_id = pcb_input_gate.id
      self.save
        
      true
    else
      false
    end
  end
  
  
  ######################################################################
  #
  # update_release_review_poster
  #
  # Description:
  # This method updates the designer attribute of a Release review
  # and records the update.
  #
  # Parameters:
  # release_reviewer - the new value for the designer (release poster)
  #                    attribute
  # user             - the use who made the update
  #
  # Return value:
  # TRUE if the attribute was updated, otherwise FALSE.
  #
  ######################################################################
  #
  def update_release_review_poster(release_reviewer, user)

    if self.review_type.name == "Release" &&
       self.review_status.name != "Review Completed" &&
       release_reviewer && self.designer_id != release_reviewer.id

      self.record_update('Release Poster', 
                         self.designer.name, 
                         release_reviewer.name,
                         user)

      self.designer_id = release_reviewer.id
      self.save
      
      true
    else
      false
    end

  end


  ######################################################################
  #
  # update_reviews_designer_poster
  #
  # Description:
  # This method updates the designer attribute of a design review.
  #
  # Parameters:
  # release_reviewer - the new value for the designer attribute
  # user             - the use who made the update
  #
  # Return value:
  # TRUE if the attribute was updated, otherwise FALSE.
  #
  ######################################################################
  #
  def update_reviews_designer_poster(designer, user)

    if self.review_type.name != "Pre-Artwork" && 
       self.review_type.name != "Release"     &&
       self.review_status.name != "Review Completed" &&
       designer && self.designer_id != designer.id

      self.record_update('Designer', 
                         self.designer.name, 
                         designer.name,
                         user)
      self.designer_id = designer.id
      self.save

      true
    else
      false
    end

  end


  ######################################################################
  #
  # record_update
  #
  # Description:
  # This method stores the design review update
  #
  # Parameters:
  # what      - the attribute that is being updated 
  # user      - the user that made the update
  # old_value - the value of the attribute before the update
  # new_value - the value of the attribute afer the update
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def record_update(what, old_value, new_value, user)
    self.design_updates << DesignUpdate.new(:what      => what,
                                            :user_id   => user.id,
                                            :old_value => old_value,
                                            :new_value => new_value)
  end


  # Generate an informational display header string for the design review.
  #
  # :call-seq:
  #   display_header() -> string
  #
  # Returns the informational display header in the following form.
  #
  #  pcb###_###_##_x - platform_name / project_name
  #
  def display_header
    self.design.directory_name + ' - ' +
    self.design.board.platform.name + ' / ' + self.design.board.project.name
  end


  def set_posting_timestamp(timestamp = Time.now)
    self.posting_timestamps << PostingTimestamp.new(:posted_at => timestamp)
  end
  

  def surfboards_path
    "/surfboards/#{self.design_center.pcb_path}/#{self.design.directory_name}/"
  end


  def data_found?
    #puts "\t\t\t\t\t\t\tCHECKING #{self.design_center.name} (#{self.surfboards_path})"
    DesignReview.http_object.get(self.surfboards_path).code == '200'
  end

  ######################################################################
  #
  # reviewer_list
  #
  # Description:
  # Given a design review this method will return a list of the
  # reviewer emails
  #
  # Parameters:
  #   design_review - the design review to get the reviewers for.
  #
  ######################################################################
  #
  def reviewer_list

    reviewers = []
    design_review_results =
      DesignReviewResult.find_all_by_design_review_id(self.id)

    design_review_results.each do |dr_result|
      reviewer = User.find(dr_result.reviewer_id)
      reviewers << reviewer.email if reviewer.active?
    end
    
    return reviewers.uniq

  end

  ######################################################################
  #
  # copy_to
  #
  # Description:
  # Given a design review this method will return a list of the
  # people who should be CC'ed on all mails
  #
  # Parameters:
  #   design_review - the design review to get the CC list for.
  #
  ######################################################################
  #
  def copy_to

    cc_list = [self.designer.email]
    cc_list << self.design.designer.email if self.design.designer_id > 0

    self.design.board.users.each do |cc|
      cc_list << cc.email if cc.active?
    end

    cc_list += Role.add_role_members(['Manager', 'PCB Input Gate'])
    return cc_list.uniq

  end

  ######################################################################
  #
  # reviewer_list
  #
  # Description:
  # Given a design review this method will return a list of the
  # reviewer emails
  #
  # Parameters:
  #   design_review - the design review to get the reviewers for.
  #
  ######################################################################
  #
  def reviewer_list

    reviewers = []
    design_review_results =
      DesignReviewResult.find_all_by_design_review_id(self.id)

    design_review_results.each do |dr_result|
      reviewer = User.find(dr_result.reviewer_id)
      reviewers << reviewer.email if reviewer.active?
    end

    return reviewers.uniq

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
