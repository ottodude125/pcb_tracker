class Subsection < ActiveRecord::Base
  belongs_to :checklist
  belongs_to :section
  has_many   :checks
end
