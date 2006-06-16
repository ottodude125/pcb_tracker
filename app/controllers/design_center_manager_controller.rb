########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_center_manager_controller.rb
#
# $Id$
#
########################################################################

class DesignCenterManagerController < ApplicationController


  before_filter :verify_admin_role


  ######################################################################
  #
  # design_center_assignment
  #
  # Description:
  # This method retrieves the designers and design centers for the 
  # form to make the designer/designer center assignments.
  #
  # Parameters from @params
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def design_center_assignment
    
    # Get all of the active designers.
    @designers = Role.find_by_name("Designer").active_users

    # Get all of the active design centers.
    @design_centers = DesignCenter.find_all('active=1')
    @design_centers.delete_if { |dc| dc.name.include? "Archive" }

  end

  
  ######################################################################
  #
  # assign_designers_to_centers
  #
  # Description:
  # This method updates designer records with their design center ids.
  #
  # Parameters from @params
  # None
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def assign_designers_to_centers

    # Go through the parameters passed back and assign the users to the
    # design centers.
    @params.each { |form_tag, design_center_id|

      next if (form_tag == "action" or form_tag == "controller")

      name, id = form_tag.split('_')
      designer          = User.find(id)
      next if (designer.design_center_id.to_s == design_center_id['id'])

      designer.password = ''
      designer.update_attribute('design_center_id', design_center_id['id'])

    }

    flash['notice'] = 'The Designer/Design Center assignments have been recorded'
    redirect_to(:action => 'design_center_assignment')
    
  end

end
