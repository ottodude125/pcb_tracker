# lib/tasks/create_fir_issues.rake
#
# create the fir_issues for testing 
#
# rake task run "rake db:create_fir_issues RAILS_ENV=development"
#
# Jonathan Katon Apr 2015
#


# Add color to terminal output
module Colors
  def colorize(text, color_code)
    "\033[#{color_code}m#{text}\033[0m"
  end
  {
    :black => 30,
    :red => 31,
    :green => 32,
    :yellow => 33,
    :blue => 34,
    :magenta => 35,
    :cyan => 36,
    :white => 37
  }.each do |key, color_code|
    define_method key do |text|
      colorize(text, color_code)
    end
  end
end

module CreateFirIssues
  include Colors
 
  def self.create_issues()
    part_nums = ["617-699-00","623-486-00","623-487-00","959-160-50","625-116-00","622-976-00","618-055-00","624-701-00","622-716-00","623-648-00","624-633-00","624-631-00","624-634-00","625-142-00","625-123-00","625-130-00","625-132-00","604-134-00","622-255-01","628-322-00","628-320-00","618-559-03","603-172-03","621-939-01","624-632-00","628-175-00","282-023-05","625-309-00","625-387-00","615-567-02","625-112-00","618-142-01","628-908-00","628-907-00","626-963-00","627-236-00","625-019-01","625-389-00","625-391-00","601-129-06","617-417-03","624-883-02","629-389-00","621-940-02","626-678-00","626-680-00","626-682-00","627-096-00","627-098-00","616-993-02","626-998-00","626-999-00","626-798-00","622-980-01","627-073-00","627-345-00","627-351-00","626-097-00","625-172-00","627-098-01","627-934-00","615-565-04","615-569-02","615-571-02","616-674-02","628-487-00","628-491-00","624-571-01","624-632-01","628-996-00","625-387-10","628-322-01","628-371-00","618-488-02","629-551-00","932-420-61","606-102-61","932-421-62","959-462-60 ","629-652-00","604-533-62","629-959-00","610-618-62","628-320-01","625-019-02","630-066-00","630-064-00","617-559-02","628-489-00","601-129-07","629-812-00 ","632-096-00","627-096-01","630-686-00","630-919-00","632-193-00","630-754-00","628-491-01 ","604-533-65","610-618-65","631-936-00","631-807-00","602-916-01","631-896-00","631-308-00","628-491-02","959-160-60","627-351-10","631-426-00","632-193-01","628-491-03"]
    design_id = 1
    user_id = 1
    description = ""
    cause = ""
    resolution = ""
    documentation_issue = false
    received_on = "2014-05-08"
    clean_up_complete_on = ""

    full_rev_reqd = false
    bare_brd_change_reqd = false

    fab_deliverable_id = 1
    fab_failure_mode_id = 1
    
    resolved = true
    resolved_on = "" 
    
    # process each part number
    # parse number for 
    count = 0
    count2 = 0
    count3 = 0
    part_nums.each do |p|
      count += 1
      
      nums = p.split('-')
      partnum = PartNum.find_by_prefix_and_number_and_dash(nums[0].to_i,nums[1].to_i,nums[2].to_i)
      next unless !partnum.nil?
      count2 += 1
      
      (2...rand(3...8)).each do
        count3 += 1
        attributes = {}
        attributes['design_id'] = 1 
        attributes['user_id'] = 116 # Jans id
        attributes['description'] = ""
        attributes['cause'] = ""
        attributes['resolution'] = "" 
        attributes['received_on'] = ""
        attributes['fab_deliverable_id'] = ""
        attributes['documentation_issue'] = ""
        attributes['fab_failure_mode_id'] = "" 
        attributes['clean_up_complete_on'] = "" 
        attributes['full_rev_reqd'] = ""
        attributes['bare_brd_change_reqd'] = ""   
            
        attributes['full_rev_reqd'] = [true, false].sample
        if attributes['full_rev_reqd']
          attributes['bare_brd_change_reqd'] = false
        else
          attributes['bare_brd_change_reqd'] = [true, false].sample
        end
        
        attributes['design_id'] = partnum.design_id
        attributes['user_id'] = 116
        # Date final rev completed
        attributes['received_on'] = DesignReview.find_by_design_id_and_review_type_id(partnum.design_id, 1).completed_on.to_date
        # Set deliverable id to a random number from 2-13 inclusive - these are the current ids of all deliverables
        attributes['fab_deliverable_id'] = FabDeliverable.find(rand(2...13)).id
        
        # Set doc iss to true of false
        attributes['documentation_issue'] = [true, false].sample  
        # If doc issue true set failure mode id to 1-4 whichi s current ids of all modes
        if attributes['documentation_issue']
          attributes['fab_failure_mode_id'] = rand(1..4)
          attributes['clean_up_complete_on'] = attributes['received_on'] + rand(0..21).days
        end

        attributes['resolved'] = true
        attributes['resolved_on'] = attributes['clean_up_complete_on']
               
        #o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten 
        RandomWord.exclude_list << /_/     
        temp = RandomWord.nouns.next.capitalize rescue "The"
        attributes['description'] += temp + " "
        (3...rand(4..20)).each do
          temp2 = [RandomWord.adjs.next, RandomWord.nouns.next].sample rescue "and"
          attributes['description'] += temp2 + " "
          #(5...rand(6..10)).map { o[rand(o.length)] }.join + " " 
        end
        
        temp = RandomWord.nouns.next.capitalize rescue "The"
        attributes['cause'] += temp + " "
        (15...rand(16..40)).each do
          temp2 = [RandomWord.adjs.next, RandomWord.nouns.next].sample rescue "and"
          attributes['cause'] += temp2 + " " 
          #(5...rand(6..10)).map { o[rand(o.length)] }.join + " " 
        end      
        
        temp = RandomWord.nouns.next.capitalize rescue "The"
        attributes['resolution'] += temp + " "
        (15...rand(16..40)).each do
          temp2 = [RandomWord.adjs.next, RandomWord.nouns.next].sample rescue "and"
          attributes['resolution'] += temp2 + " " 
          #(5...rand(6..10)).map { o[rand(o.length)] }.join + " " 
        end
        
        #puts "\n\n" 
        #puts attributes
        @fab_issue = FabIssue.new(attributes)
        @fab_issue.save
      end
    end
    
    # Create Message Types
    puts "\e[33m" + "Creating Message Types" + "\e[32m"
 
    puts "\e[0m"
    puts count
    puts count2
    puts count3
  end

end

namespace :db do
  desc "Create Fir Issues"
  task :create_fir_issues, [:actions] => [:environment] do |t, args|
    CreateFirIssues.create_issues
  end
end


