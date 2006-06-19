########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: check.rb
#
# This file maintains the state for checks.
#
# $Id$
#
########################################################################

class Check < ActiveRecord::Base

  belongs_to :section
  belongs_to :subsection

  has_one :design_check
  
  
  ######################################################################
  #
  # yes_no?
  #
  # Description:
  # This method looks at the check_type and returns TRUE if it is
  # set to 'yes_no'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the check is a 'Yes/No' check, FALSE otherwise.
  #
  ######################################################################
  #
  def yes_no?
    self.check_type == 'yes_no'
  end
  
  
  ######################################################################
  #
  # designer_only?
  #
  # Description:
  # This method looks at the check_type and returns TRUE if it is
  # set to 'designer_only'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the check is a 'designer_only' check, FALSE otherwise.
  #
  ######################################################################
  #
  def designer_only?
    self.check_type == 'designer_only'
  end
  
  
  ######################################################################
  #
  # designer_auditor?
  #
  # Description:
  # This method looks at the check_type and returns TRUE if it is
  # set to 'designer_auditor'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the check is a 'designer_auditor' check, FALSE otherwise.
  #
  ######################################################################
  #
  def designer_auditor?
    self.check_type == 'designer_auditor'
  end

end
