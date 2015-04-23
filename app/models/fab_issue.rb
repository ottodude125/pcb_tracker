class FabIssue < ActiveRecord::Base
  # attr_accessible :title, :body
  
  belongs_to :user
  belongs_to :design
  belongs_to :fab_deliverable
  belongs_to :fab_failure_mode

end
