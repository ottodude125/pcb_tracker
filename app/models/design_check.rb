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
  
  
  AUDITOR_COMPLETE_RESULTS   = %w(Verified N/A Waived)
  AUDITOR_INCOMPLETE_RESULTS = %w(None Comment)

 

  has_many(:audit_comments, :order => 'created_on DESC')
  
  
  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


  ######################################################################
  #
  # add
  #
  # Description:
  # Adds a design check to the database for the given audit / check 
  # pair
  # 
  # Parameters:
  # audit - the audit to associate the design check with
  # check - the check to associate the design check with 
  #
  # Return value:
  # None
  #
  ######################################################################
  #  
  def self.add(audit, check)
    dc = DesignCheck.new(:audit_id => audit.id, :check_id => check.id)
    fail 'Design check not saved' unless dc.save
  end
  
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################


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
  rescue
    User.new(:first_name => 'Not', :last_name => 'Assigned')
  end
  
  
  # Determine if the design check has a peer auditor.
  #
  # :call-seq:
  #   peer_auditor_assigned?() -> boolean
  #
  # Returns TRUE if the design check has a peer auditor assigned.
  # Otherwise FALSE is returned.
  def peer_auditor_assigned?
    self.auditor_id > 0
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
  rescue
    User.new(:first_name => 'Not', :last_name => 'Assigned')
  end
  
  
  # Determine if the design check has a self auditor.
  #
  # :call-seq:
  #   self_auditor_assigned?() -> boolean
  #
  # Returns TRUE if the design check has a self auditor assigned.
  # Otherwise FALSE is returned.
  def self_auditor_assigned?
    self.designer_id > 0
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
    check = Check.find(self.check_id)
    case 
      when designer_result == 'No'
        check.yes_no?
      when designer_result == 'Waived'
        check.designer_only? || check.designer_auditor?
      when auditor_result  == 'Waived'  || auditor_result == 'Comment'
        check.designer_auditor?
    end

  end

  ######################################################################
  #
  # update_designer_result
  #
  # Description:
  # Updates the design check with the designer's self audit results.
  # 
  # Parameters:
  # result - the result entered by the designer
  # user   - the designer's user record
  #
  # Return value:
  # None
  #
  ######################################################################
  #
 def update_designer_result(result, user)
    self.update_attributes(:designer_result     => result,
                           :designer_checked_on => Time.now,
                           :designer_id         => user.id)
  end

  
  ######################################################################
  #
  # update_auditor_result
  #
  # Description:
  # Updates the design check with the auditor's peer audit results.
  # 
  # Parameters:
  # result - the result entered by the peer auditor
  # user   - the auditor's user record
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def update_auditor_result(result, user)

    incr = 0
    if self.auditor_verified?
      incr = -1 if result == 'Comment'
    else
      incr = 1  if AUDITOR_COMPLETE_RESULTS.include?(result)
    end

    self.auditor_result     = result
    self.auditor_checked_on = Time.now
    self.auditor_id         = user.id
    self.save

    incr

  end

  
  # Indicate if the peer auditor has verified the design check.
  #
  # :call-seq"
  #   auditor_verified?() -> boolean
  #
  # If the peer auditor has verified the check then TRUE is returned,
  # otherwise FALSE is returned.
  def auditor_verified?
    AUDITOR_COMPLETE_RESULTS.include?(self.auditor_result)
  end
  
  
  # Indicate if the peer auditor has raised an issue that needs to
  # be addressed
  #
  # :call-seq"
  #   peer_auditor_issue?() -> boolean
  #
  # TRUE if there is an issue, otherwise FALSE.
  def peer_auditor_issue?
    self.auditor_result == 'Comment'
  end
  
  
end
