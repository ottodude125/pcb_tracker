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
end
