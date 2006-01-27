class Revision < ActiveRecord::Base
  has_one :audit
end
