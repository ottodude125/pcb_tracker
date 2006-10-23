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

  has_many   :design_review_results


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
  # comments
  #
  # Description:
  # This method returns the comments for the design review object.
  #
  # Parameters:
  # order - specifies the sort order for the created_on field.  Either 
  #         'ASC' or 'DESC'
  #
  # Return value:
  # A list of comments for the design review.
  #
  ######################################################################
  #
  def comments(order = 'DESC')
    DesignReviewComment.find_all_by_design_review_id(self.id,
                                                     "created_on #{order}")
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
  # The number of workdays since the design review was posted.
  #
  ######################################################################
  #
  def age(end_time = Time.now)

    start_time = self.created_on

    workdays = end_time - start_time > 43200 ? 0 : -1

    while start_time <= end_time
      day         = start_time.strftime("%w").to_i
      workdays   += 1 if 0 < day && day < 6
      start_time += 86400                        # add a day's worth of seconds
    end
    
    workdays
    
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
    self.design_review_results.sort_by { |review_result| 
      review_result.role.display_name
    }
  end
  
  
  def reviewers(reviewer_list = [],
                sorted        = false)
  
    for review_result in self.design_review_results
      if not reviewer_list.detect { |reviewer| reviewer.id == review_result.reviewer_id }
        reviewer_list << User.find(review_result.reviewer_id)
      end
    end
    
    reviewer_list = 
      reviewer_list.sort_by { |reviewer| reviewer.last_name } if sorted
    
    reviewer_list.uniq
    
  end
  
  
  def generate_reviewer_selection_list()

    review_results = DesignReviewResult.find_all_by_design_review_id(self.id)
    review_results = review_results.sort_by { |rr| rr.role.display_name }

    reviewers = Array.new
    for review_result in review_results
      reviewers.push({ :group       => review_result.role.display_name,
                       :group_id    => review_result.role.id,
                       :reviewers   => review_result.role.active_users,
                       :reviewer_id => review_result.reviewer_id })
    end

    return reviewers
    
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


  def dump_design_review
  
    priority = Priority.find(self.priority_id)
    designer = User.find(self.designer_id)  if self.designer_id  > 0
    creator  = User.find(self.creator_id)   if self.creator_id   > 0
    
    logger.info "***********************DESIGN REVIEW **********************"
    logger.info "NAME: #{self.design.name}"
    logger.info "REVIEW TYPE: #{self.review_type.name}"
    logger.info "ID: #{self.id}"
    logger.info "POSTING COUNT: #{self.posting_count}"
    logger.info "STATUS: #{self.review_status.name}"
    logger.info "PRIORITY: #{priority.name}"

    if designer
      logger.info "DESIGNER: #{designer.name}"
    else
      logger.info "DESIGNER_ID: #{self.designer_id}"
    end
    if creator
      logger.info "CREATED BY: #{creator.name}"
    else
      logger.info "CREATED BY ID: #{self.created_by}"
    end
    logger.info "##########################################################"
  
  end
  
  
  
end
