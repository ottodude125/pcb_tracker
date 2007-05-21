########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_check.rb
#
# This file maintains the state for design checks.
#
# $Id$
#
########################################################################

class DesignCheck < ActiveRecord::Base

  belongs_to :audit
  belongs_to :check
 

  has_many(:audit_comments, :order => 'created_on DESC')
  
  
  ######################################################################
  #
  # peer_auditor
  #
  # Description:
  # Provides a user record for the peer auditor
  #
  # Return value:
  # A user record
  #
  ######################################################################
  #
  def peer_auditor
    if self.auditor_id > 0 
      User.find(self.auditor_id)
    else
      User.new(:first_name => 'Not', :last_name => 'Assigned')
    end
  end
  
  
  ######################################################################
  #
  # self_auditor
  #
  # Description:
  # Provides a user record for the self auditor
  #
  # Return value:
  # A user record
  #
  ######################################################################
  #
  def self_auditor
    if self.designer_id > 0
      User.find(self.designer_id)
    else
      User.new(:first_name => 'Not', :last_name => 'Assigned')
    end
  end
  

  ######################################################################
  #
  # self_auditor_checked?
  #
  # Description:
  # Indicates if the self audit design check is complete
  #
  # Return value:
  # TRUE if the self auditor has completed the design check, FALSE 
  # otherwise.
  #
  ######################################################################
  #
  def self_auditor_checked?
    self.designer_result != 'None'
  end
  

  ######################################################################
  #
  # peer_auditor_checked?
  #
  # Description:
  # Indicates if the peer audit design check is complete
  #
  # Return value:
  # TRUE if the peer auditor has completed the design check, FALSE 
  # otherwise.
  #
  ######################################################################
  #
  def peer_auditor_checked?
    !(self.auditor_result == 'None' || self.auditor_result == 'Comment')
  end
  
  
  ######################################################################
  #
  # comment_required?
  #
  # Description:
  # Indicates if a comment is recquired for the update.
  # 
  # Parameters:
  # designer_result - the result entered by the designer
  # auditor_result  - the result entered by the auditor
  #
  # Return value:
  # TRUE if the peer auditor has completed the design check, FALSE 
  # otherwise.
  #
  ######################################################################
  #
  def comment_required?(designer_result, auditor_result)

    # Checking the check for the check type is overkill.
    case 
      when designer_result == 'No'
        self.check.yes_no?
      when designer_result == 'Waived'
        self.check.designer_only? || self.check.designer_auditor?
      when auditor_result  == 'Waived'  || auditor_result == 'Comment'
        self.check.designer_auditor?
    end

  end
  
  
end
