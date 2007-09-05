########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: review_manager_controller.rb
#
# $Id$
#
########################################################################

class ReviewManagerController < ApplicationController


  before_filter :verify_admin_role


  ######################################################################
  #
  # review_type_role_assignment
  #
  # Description:
  # This method retrieves the review type role information to 
  # display for the user to modify.
  #
  # Parameters from params
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def review_type_role_assignment

    # Get all of the reviewer roles.
    @roles        = Role.get_manager_review_roles + Role.get_review_roles
    @review_types = ReviewType.get_active_review_types

    @roles.each do |role|

      rtypes = {}
      role.review_types.each do |rtype|
        rtypes[rtype.name] = rtype.id
      end

      role[:review_types] = rtypes
    end

  end



  ######################################################################
  #
  # assign_groups_to_reviews
  #
  # Description:
  # This method make the assignments of the review groups to the review
  # types.
  #
  # Parameters from params
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def assign_groups_to_reviews

    # Go through the parameters and extract the role id and review id
    # from the keys.
    params[:review_type].each { | key, value |

      role_id, review_type_id = key.split('_')

      role = Role.find(role_id)
      review_type = ReviewType.find(review_type_id)

      if review_type.roles.include?(role)
	   review_type.roles.delete(role) if value == '0'
      else
	    review_type.roles << role     if value == '1'
      end
    }

    flash['notice'] = 'Assignments have been updated'
    redirect_to(:action => 'review_type_role_assignment')

  end

end
