class IpdPost < ActiveRecord::Base

  acts_as_threaded

  belongs_to :design
  belongs_to :user
  
end
