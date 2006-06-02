class IpdPost < ActiveRecord::Base

  acts_as_threaded

  belongs_to :design
  belongs_to :user
  
  has_and_belongs_to_many :users
  
  
end
