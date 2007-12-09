########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: application_helper.rb
#
# The methods added to this helper will be available to all 
# templates in the application.
#
# $Id$
#
########################################################################

module ApplicationHelper


  ######################################################################
  #
  # split_into_cols
  #
  # Description:
  # This method uses the list and column number passed in to compute 
  # the slices of the list that will be displayed into each column.
  #
  # Parameters:
  # list    - the list that will be divided into columns
  # columns - the number of columns to split the list into for display
  #
  # Returns:
  # An array of slices that define the range of the list that are
  # to be displayed in each column.
  #
  ######################################################################
  #
  def split_into_cols(list, columns)

    cols = [{:empty => true}]

    if list.size <= columns
      columns.downto(1) { |i|
        if i > list.size
	  cols[i] = {:empty => true}
	else
	  cols[i] = {:empty => false, :start => (i-1), :stop => (i-1)}
	end
      }
    else
      items_remaining = list.size
      items_per_col = items_remaining/columns

      start = 0
      1.upto(columns) { |i|

        items_per_col = items_remaining if i == columns
        
        stop = start + items_per_col - 1

        if i < (columns - 1)
          stop += 1 if list.size.remainder(columns) > 0
        end

        cols[i] = {:empty => false, :start => start, :stop => stop}
        start = stop + 1
        items_remaining -= items_per_col
      }
    end

    return cols
    
  end


  ######################################################################
  #
  # is_manager
  #
  # Description:
  # This method determines if the user is a manager.  The information
  # stored in the session data is used to make the determination.
  #
  # Parameters:
  # None
  #
  # Returns:
  # True if the user is a manager, false otherwise.
  #
  ######################################################################
  #
  def is_manager
    session[:roles].include?(Role.find_by_name("Manager"))
  end


  ######################################################################
  #
  # is_admin
  #
  # Description:
  # This method determines if the user is a tracker admin.  The information
  # stored in the session data is used to make the determination.
  #
  # Parameters:
  # None
  #
  # Returns:
  # True if the user is a tracker admin, false otherwise.
  #
  ######################################################################
  #
  def is_admin
    session[:roles].include?(Role.find_by_name("Admin"))
  end


  ######################################################################
  #
  # pre_artwork_complete
  #
  # Description:
  # This method determines if a design's pre-artwork design review
  # is complete.
  #
  # Parameters:
  # design - provides access to the pre-artwork design review that the
  #          caller is interested in.
  #
  # Returns:
  # True if the pre-artwork design review is complete, false otherwise.
  #
  ######################################################################
  #
  def pre_artwork_complete(design)

    pre_art_review_type = ReviewType.get_pre_artwork
    pre_art_design_review = design.design_reviews.detect { |dr| 
      dr.review_type_id == pre_art_review_type.id
    }

    done = ReviewStatus.find_by_name('Review Completed')
    done.id == pre_art_design_review.review_status_id
    
  end


  ######################################################################
  #
  # design_center_path
  #
  # Description:
  # Given a design review, creates the url to access the design.
  #
  # Parameters:
  # design_review - provides access to the design to create the url.
  #
  # Returns:
  # The url to get to the design data.
  #
  ######################################################################
  #
  def design_center_path(design_review)
    'http://etg.teradyne.com/surfboards/' + 
    design_review.design_center.pcb_path  + '/' +
    design_review.design.directory_name + '/public'
    
  end


  ######################################################################
  #
  # poster_name
  #
  # Description:
  # Returns the name that should be displayed in the "Poster" field.  If the
  # review is a Pre-Artwork review then the name of the person who created the 
  # design should be displayed.  Otherwise the name of the designer assigned to
  # the review should be displayed.
  #
  # Parameters:
  # design_review - provides access to the design review.
  #
  # Returns:
  # The name of the poster
  #
  ######################################################################
  #
  def poster_name(design_review)
    if design_review.review_type.name == "Pre-Artwork"
      design_review.design.input_gate.name
    else
      design_review.designer.name
    end
  end
  
  
  def auditor_name(section_id, teammate_list, lead)
    teammate = teammate_list.detect { |teammate| teammate.section_id == section_id }
    if teammate
      teammate.user.name
    else
      lead.name
    end
  end
  
  
  def audit_radio_button(check, 
                         audit,
                         tag_value,
                         disabled)
                         
    if audit.is_self_audit?
      attribute = 'designer_result'
      checked = check[:design_check][:designer_result] == tag_value ? true : nil
    else
      attribute = 'auditor_result'
      checked = check[:design_check][:auditor_result] == tag_value ? true : nil
    end
    
    radio_button("check_#{check.id}",
                 attribute,
                 tag_value,
                 {:checked  => checked,
                  :disabled => disabled})
  end
  
  
end
