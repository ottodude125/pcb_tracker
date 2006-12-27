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
  # team_leader
  #
  # Description:
  # This method returns the name of the team leader.
  #
  # Parameters:
  # id - the id of the team leader
  #
  # Returns:
  # The team leader's name if the id is non-zero.  Otherwise a string
  # indicating "All Teradyne Designers".
  #
  ######################################################################
  #
  def team_leader(id)
    id == 0 ? 'All Teradyne Designers' : User.find(id).name
  end


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
    id == 0 ? 'All Team Members' : User.find(id).name
  end


  ######################################################################
  #
  # category
  #
  # Description:
  # This method returns the name of the category.
  #
  # Parameters:
  # id - the id of the category
  #
  # Returns:
  # The category name if the id is non-zero.  Otherwise a string
  # indicating "All Categories".
  #
  ######################################################################
  #
  def category(id)
    id == 0 ? 'All Categories' : OiCategory.find(id).name
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
    date.to_time.strftime("%B %d, %Y")
  end


end
