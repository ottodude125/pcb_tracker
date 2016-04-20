class ModelComment < ActiveRecord::Base
  # attr_accessible :title, :body

  belongs_to :model_task
  belongs_to :user
  
end
