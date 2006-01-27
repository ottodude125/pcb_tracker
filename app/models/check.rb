class Check < ActiveRecord::Base

  belongs_to :section
  belongs_to :subsection

  has_one :design_check

end
