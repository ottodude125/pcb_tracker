class FabFailureMode < ActiveRecord::Base
  # attr_accessible :title, :body
  
  has_many :fab_issues
  
end
