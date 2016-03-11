class ModelType < ActiveRecord::Base
  # attr_accessible :title, :body

  has_and_belongs_to_many :model_tasks

  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


  # Find active Model Types
  # 
  # :call-seq:
  #   ModelType.find_find_all_active() -> array
  #
  # Returns a list of active Model Types
  def self.find_active
    self.find(:all, :conditions => "active=1", :order => 'name')
  end
  
  
end
