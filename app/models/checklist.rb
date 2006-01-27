class Checklist < ActiveRecord::Base
  has_many :sections
  has_many :subsections
  has_many :audits

  ######################################################################
  #
  # increment_checklist_counters
  #
  # Description:
  # This method is called to update the checklist counters when any
  # changes are made to a check or when a check is added or destroyed.
  #
  # Parameters:
  # new_check       - The check that is being added or destroyed.
  # increment_value - Either 1 or -1 depending on whether a check is 
  #                   being added or destroyed.
  #
  # Return value:
  # None
  #
  # Additional information:
  # None
  #
  ######################################################################
  #
  def self.increment_checklist_counters(new_check, increment_value)

    checklist = Checklist.find(new_check.section.checklist_id)

    if new_check.check_type == 'designer_auditor'
      checklist.designer_auditor_count    += 
	increment_value   if (new_check.full_review     == 1)
      checklist.dc_designer_auditor_count += 
	increment_value   if (new_check.date_code_check == 1)
      checklist.dr_designer_auditor_count += 
	increment_value   if (new_check.dot_rev_check   == 1)
    else
      checklist.designer_only_count       += 
	increment_value   if (new_check.full_review     == 1)
      checklist.dc_designer_only_count    +=
	increment_value   if (new_check.date_code_check == 1)
      checklist.dr_designer_only_count    += 
	increment_value   if (new_check.dot_rev_check   == 1)
    end

    checklist.update

  end

  
end
