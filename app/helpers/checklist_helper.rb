module ChecklistHelper

  def get_summary_data(checklist)

    subsection_count = 0
    check_count      = 0

    for section in checklist.sections
      subsection_count += section.subsections.size
      for subsection in section.subsections
        check_count += subsection.checks.size
      end
    end
    
    return subsection_count, check_count
  end
  
  def included_in?(review_type,
                   element)

    ((review_type == 'full')      && (element.full_review     == 1)) ||
    ((review_type == 'date_code') && (element.date_code_check == 1)) ||
    ((review_type == 'dot_rev')   && (element.dot_rev_check   == 1))

  end


end
