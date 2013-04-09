# This rake task is to fill some holes in the part_num descriptions. 
# Some part nums had not board_design_entry_id, they didn't get a descrition
# However the "board" table does have a description which we can import from
#
# This is a run once task

namespace :fill do
  desc "fill in missing part_num descriptions from design->board.description"
  task :descriptions => :environment do
    #Grab all the part_nums without a description 
    pnums = PartNum.find(:all, :conditions => ['description IS NULL'])
    puts "Found #{pnums.count} entries with no description"
    pnums.each { | pnum |
      description = pnum.design.board.description
      if ! description.blank?
        puts "#{pnum.name_string} -> #{description}"
        pnum_attributes = { :description => description }
        pnum.update_attributes!(pnum_attributes)
      else
        puts "#{pnum.name_string} - no description found"
      end
    }
  end 
 
end
