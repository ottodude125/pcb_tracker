class DbCheck < ActiveRecord::Base

  def self.master?
    sql = "select `variable_value` from " +
          "`information_schema`.`global_variables` " +
          "where `variable_name` = 'read_only';"
    r = ActiveRecord::Base.connection.exec_query( sql )
    if r.first
      r.first['variable_value'] == "OFF"
    else
      true #no slave status
    end   
  end
  
  def self.exist?
    ! User.find_by_sql("SHOW TABLES").blank?
  end
  
end
