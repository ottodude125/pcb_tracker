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

    pre_art_review_type = ReviewType.find_by_name('Pre-Artwork')
    pre_art_design_review = design.design_reviews.detect { |dr| 
      dr.review_type_id == pre_art_review_type.id
    }

    done = ReviewStatus.find_by_name('Review Completed')
    done.id == pre_art_design_review.review_status_id
    
  end


  ######################################################################
  #
  # workdays
  #
  # Description:
  # Given a start and stop time, this method computes the work days 
  # between the 2 times.
  #
  # Parameters:
  # start_time - the beginning of the time slice
  # end_time   - the end of the time slice
  #
  # Returns:
  # The number of days between the 2 time stamps.
  #
  ######################################################################
  #
  def workdays (start_time, end_time)
    if end_time - start_time > 43200
      workdays = 0
    else
      workdays = -1
    end
    while start_time <= end_time
      day = start_time.strftime("%w").to_i
      workdays += 1 if day > 0 && day < 6
      # Add a day.
      start_time += 86400
    end
    workdays
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
    'http://etg.teradyne.com/surfboards/'  +
      design_review.design_center.pcb_path +
      '/'                                  +
      design_review.design.name            +
      '/public'
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
      User.find(design_review.design.pcb_input_id).name
    else
      User.find(design_review.designer_id).name
    end
  end


end
