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


  def is_manager
    session[:roles].include?(Role.find_by_name("Manager"))
  end


  def is_admin
    session[:roles].include?(Role.find_by_name("Admin"))
  end


  def pre_artwork_complete(design)

    pre_art_review_type = ReviewType.find_by_name('Pre-Artwork')
    pre_art_design_review = design.design_reviews.detect { |dr| 
      dr.review_type_id == pre_art_review_type.id
    }

    done = ReviewStatus.find_by_name('Review Completed')
    done.id == pre_art_design_review.review_status_id
    
  end


end
