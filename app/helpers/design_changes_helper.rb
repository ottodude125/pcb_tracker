########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_changes_helper.rb
#
# The methods added to this helper will be available to all 
# design changes templates.
#
# $Id$
#
########################################################################
module DesignChangesHelper


  # Determine how many rows of selection boxes should be desplayed on the
  # design changes creation form.
  # 
  # :call-seq:
  #   definition_rows() -> Integer
  #
  # Returns an integer that indicates how many rows of selection boxes to display.
  def definition_rows(design_change)
    if    @design_change.change_detail_set?
      4
    elsif @design_change.change_item_set?
      3
    elsif @design_change.change_type_set?
      2
    else
      1
    end
  end
  
  
  # Provide an english summary of the design change impact.
  # 
  # :call-seq:
  #   summarize() -> String
  #
  # Returns a string indicating the design change impact.
  def summarize(state, total_delta)
    statement   = state + ': '
    if total_delta < 0.5 && total_delta > -0.5
      statement += "No Impact to the Schedule"
    elsif total_delta > 0.0
      statement += total_delta.to_s + ' Hours Added to the Schedule'
    else
      total_delta *= -1
      statement += total_delta.to_s + ' Hours Removed from the Schedule'
    end
    statement
  end

  
end
