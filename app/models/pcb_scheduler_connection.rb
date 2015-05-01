class PcbSchedulerConnection < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "pcb_scheduler_#{Rails.env}"
  
end

