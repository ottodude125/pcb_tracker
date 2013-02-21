#!/usr/local/bin/ruby

# This file load the part numbers and descriptions from the 
# nightly team center oracle dump and loads it into a
# table in the pcb tracker database


# load the oracle description file into a database table
file = '/hwnet/dtg_devel/cis_mrp/descript_oracle.txt'
host   = "mimir2"
port   = 3308
db     = "pcbtr3_development"
table  = "oracle_part_nums"
user   = "pcbtr"
passwd = "PcBtR"

# number = first ten characters
# description = rest of line

require 'mysql'


begin
  con = Mysql.new host, user, passwd, db, port
  con.query("DROP TABLE IF EXISTS #{table}")
  con.query("CREATE TABLE #{table}(id INT PRIMARY KEY AUTO_INCREMENT, 
                                       number VARCHAR(255) , 
                                       description VARCHAR(80),
                                       INDEX (number) )")
  #although it is slower, lets try one row at a time
  File.readlines(file).each do |line|
    parts = line.unpack('a10a*')
    partnum     = parts[0]
    description = parts[1]
    description = description.gsub(/'/,"''");
    con.query("INSERT IGNORE INTO #{table} (`number`,`description`)
      VALUES ('#{partnum}','#{description}') ")
  end
rescue Mysql::Error => e
  puts e.errno
  puts e.error
  
ensure
  con.close if con
  
end
