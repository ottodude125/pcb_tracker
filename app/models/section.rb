class Section < ActiveRecord::Base
  belongs_to :checklist
  has_many   :checks
  has_many   :subsections
end
