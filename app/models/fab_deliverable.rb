class FabDeliverable < ActiveRecord::Base
  # attr_accessible :title, :body
  
  belongs_to :parent, class_name: "FabDeliverable" 

  has_many :children, class_name: "FabDeliverable", foreign_key: "parent_id"
  has_many :fab_issues                             
   
end
