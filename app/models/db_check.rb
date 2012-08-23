class DbCheck #< ActiveRecord::Base
  #self.abstract_class = true
  #@columns = []

  def self.master?
    User.find_by_sql("SHOW SLAVE STATUS").blank?
  end
  
  def self.exist?
    ! User.find_by_sql("SHOW TABLES").blank?
  end
  
end
