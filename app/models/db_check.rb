class DbCheck < ActiveRecord::Base

  def self.master?
    r = ActiveRecord::Base.connection.exec_query("show slave status")
    r.first['Slave_IO_Running'] != "Yes" 
  end
  
  def self.exist?
    ! User.find_by_sql("SHOW TABLES").blank?
  end
  
end
