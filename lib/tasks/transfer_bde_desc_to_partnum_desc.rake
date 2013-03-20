# This rake task is really only here for a one time use. This will be used when I transfer over my code from beta to production
# The need for this has come up because the description columns in the Board and Board Design Entry tables
# Are being obsoleted. Instead of a single description now each pcb/pcba number will have its own description
# Therefore this file copies all the descriptions over to the part_num table to initialize it. Once these
# descriptions are pulled over once they will never be pulled over again. 2/20/13

namespace :transfer do
  desc "Transfer data from description column in BDE table to description column in PartNum table"
  task :descriptions => :environment do
    # Grab all the board design entries
    @board_design_entries = BoardDesignEntry.all
    
    @total = @board_design_entries.length
    @current = 0
    
    # Go thru each one and get all the part numbers associated with it
    @board_design_entries.each do |bde|
      @part_nums = PartNum.find_all_by_board_design_entry_id(bde.id)
      @descrip = bde.bde_description ? bde.bde_description : ""

      # Go thru each part number and update the description
      @part_nums.each do |pn|
        pn_attributes = {
          :description => @descrip
        }
        pn.update_attributes!(pn_attributes)          
      end

    @current += 1
    puts "#{((@current/@total)*100).to_i}% done# Updating description: #{@descrip}"        
    end  
  end
end