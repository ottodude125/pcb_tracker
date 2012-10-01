########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: report_helper.rb
#
# The methods added to this helper will be available to all 
# templates in the application.
#
# $Id$
#
########################################################################

module ReportHelper


  ######################################################################
  #
  # team_member
  #
  # Description:
  # This method returns the name of the team member.
  #
  # Parameters:
  # id - the id of the team member
  #
  # Returns:
  # The team leader's name if the id is non-zero.  Otherwise a string
  # indicating "All Team Members".
  #
  ######################################################################
  #
  def team_member(id)
    id == 0 ? 'All IDC Designers' : User.find(id).name
  end


  ######################################################################
  #
  # display_date
  #
  # Description:
  # This method returns the date formatted for display.
  #
  # Parameters:
  # date - the date to be formatted
  #
  # Returns:
  # A string with the formatted date.
  #
  ######################################################################
  #
  def display_date(date)
    date.to_time.format_month_dd_yyyy
  end


end
