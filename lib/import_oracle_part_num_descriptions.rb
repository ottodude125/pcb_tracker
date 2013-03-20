#!/usr/local/bin/ruby

# This file loads the part numbers and descriptions from the
# nightly team center oracle dump and loads it into a
# table in the pcb tracker database
# Run file by: /hwnet/dtg_devel/web/beta-katon/applications/pcb_tracker/lib/import_oracle_part_num_descriptions.rb

# Detect hostname so we know if we are on mimir1 or mimir3 for cronjob
require 'socket'
hostname = Socket.gethostname
port = ""
db = ""


# information to connect to oracle part nums table
if (hostname == "mimir1") || (hostname == "mimir3")
  port   = 3307
  db     = "pcbtr3_production"
elsif hostname == "mimir2"
  port   = 3308
  db     = "pcbtr3_development"
end

file = '/hwnet/dtg_devel/cis_mrp/descript_oracle.txt'
host   = hostname
table  = "oracle_part_nums"
user   = "pcbtr"
passwd = "PcBtR"

# information to check status of mysql instance
mydb   = "information_schema"
myuser = "root"
mypswd = "connect"
mytbl  = "global_status"


require 'mysql'

# partnum = first ten characters
# description = rest of line
begin
  # Check if database is running in slave mode
  cona = Mysql.new host, myuser, mypswd, mydb, port
  result = cona.query("SELECT variable_value FROM #{mytbl} WHERE variable_name = ('SLAVE_RUNNING')")
  status = "ON" # Default status to ON as a safeguard just incase query fails
  result.each_hash do |row|
    status = row['variable_value']
  end

  # If database is not in slave mode then update the oracle part nums table
  if status == "OFF"
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
  end
rescue Mysql::Error => e
  puts e.errno
  puts e.error

ensure
  cona.close if cona
  con.close if con
  
end

