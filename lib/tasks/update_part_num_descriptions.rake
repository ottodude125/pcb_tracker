# Rake task to 
# grab all the current active designs and update their pcb/pcba part number descriptions
# Send out email summary
# Create review comment for each number that has been updated

namespace :update_part_num do
  
  desc "Load the part number descriptions into the oracle_part_nums table"
  task :database => :environment do
    #STDERR.puts "Loading database"
    
    env = ActiveRecord::Base.configurations[Rails.env]
    table  = "oracle_part_nums"
        
    begin
      #Update the oracle part nums table
      con = Mysql2::Client.new( :username => env['username'], 
                                :password => env['password'], 
                                :database => env['database'],
                                :host     => env['host'], 
                                :port     => env['port']
                              )
      con.query("DROP TABLE IF EXISTS #{table}")
      con.query("CREATE TABLE #{table}(
        id INT PRIMARY KEY AUTO_INCREMENT,
        number      VARCHAR(15) ,
        description VARCHAR(80),
        INDEX (number) )")
      #insert an update marker
      con.query("INSERT IGNORE INTO #{table} (`number`,`description`)
        VALUES ('LOADED','#{Time.now}') ")                                           
      file = '/hwnet/dtg_devel/cis_mrp/descript_oracle.txt'    
      # partnum = first ten characters
      # description = rest of line
      #although it is slower, lets load one row at a time
      File.readlines(file).each do |line|
        parts = line.unpack('a10a*')
        partnum     = parts[0]
        description = parts[1]
        description = description.gsub("\n",'')
        description = description.gsub(/'/,"''")
        # next gsub preserves backslashes
        description = description.gsub("\\",'\\\\\\\\')
        con.query("INSERT IGNORE INTO #{table} (`number`,`description`)
          VALUES ('#{partnum}','#{description}') ")
      end
    rescue Mysql2::Error => e
      puts e.errno
      puts e.error

    ensure
      con.close if con
      
    end
  end # task: database

  desc "Update the part_nums data table from oracle_part_nums database table."
  # requires a load of the oracle data file first.
  task :descriptions => [ :environment, :database ] do 
    #STDERR.puts "Updating descriptions"
    # vars to hold statistical info and part nums data that was updated for email
    @numdes = 0
    @numparts = 0
    @numpartsup = 0
    @updated_part_nums = []
    @designers = []
    
    # Grab all designs which are not completed and go through each one
    incomplete_designs = Design.get_active_designs_for_auto_part_num_update#find(:all, :conditions => 'phase_id != "255"')
    
    incomplete_designs.each do |design|
      @numdes += 1
      part_nums = PartNum.find_all_by_design_id(design.id)
      
      # Grab all the part nums to each design and update their descriptions and create comment on current design review
      part_nums.each do |pn|
        @numparts += 1
        number = pn.prefix + "-" + pn.number + "-" + pn.dash 
        oracle_descrip = OraclePartNum.find_by_number(number)
        number = number + " " + pn.use
        
        # if there is an oracle entry for this partnum and the current description does not match oracle description 
        if oracle_descrip && (pn.description.strip != oracle_descrip.description.strip)
          @numpartsup += 1
          part_info = {}
          part_info[:old_descrip] = pn.description
          part_info[:number] = number
          part_info[:new_descrip] = oracle_descrip.description.strip
          part_info[:designer] = design.designer
          part_info[:design_review_id] = design.get_phase_design_review.id
          pn.description = oracle_descrip.description.strip
          pn.save
          @updated_part_nums << part_info
          
          # Create review comment
          design_review = design.get_phase_design_review
          user_id = User.find_by_login("Anonymous").id
          comment =  "Using teamcenter data the description for " + part_info[:number] + " was auto updated from " + part_info[:old_descrip] + " to " + part_info[:new_descrip]
          drcomment = DesignReviewComment.new(:design_review_id => design_review.id, :user_id => user_id, :comment => comment)
          drcomment.save
          
          # Add the designer to list of designers to get email
          @designers << design.designer
        end      
      end      
    end  # incomplete_designs.each

    # if there are part numbers that have been updated then send out email     
    if !@updated_part_nums.empty?
      TrackerMailer.part_num_update(@updated_part_nums, @designers, @numdes, @numparts, @numpartsup).deliver
      #puts " There were #{@numdes} designs and #{@numparts} part numbers and #{@numpartsup} partnums were updated"
    end
  end #task: descriptions
  
end

