class DesignCheck < ActiveRecord::Base

  belongs_to :audit
  belongs_to :check
 

  has_many :audit_comments
end
