class DbCheck < ActiveRecord::Base

  def self.master?
    r = ActiveRecord::Base.connection.exec_query("show slave status")
    if r.first
      r.first['Slave_IO_Running'] != "Yes"
    else
      true #no slave status
    end   end
  
  def self.exist?
    ! User.find_by_sql("SHOW TABLES").blank?
  end
  
end
