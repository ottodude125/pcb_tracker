########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_review.rb
#
# This file maintains the state for design reviews.
#
# $Id$
#
########################################################################

class TrackerFix < ActiveRecord::Base



  def self.check_original_design_review_posting(show_all = false)

    Design.find(:all).each do |design|

      suggested_design_created_at = design.created_at
      design_date_bad             = false
      puts
      puts '------------------------------------------------------------------'
      puts sprintf('%-20sCreated On: %-20s',
                   design.directory_name,
                   design.created_at.format_dd_mon_yy('stamp'))
      design.design_reviews.sort_by{ |dr| dr.review_type.sort_order }.each do |design_review|

        suggested_dr_created_at = design_review.created_at < design_review.reposted_at ? design_review.created_at : design_review.reposted_at
        suggested_design_created_at = design_review.created_at  if suggested_design_created_at > design_review.created_at
        suggested_design_created_at = design_review.reposted_at if suggested_design_created_at > design_review.reposted_at

        design_date_bad = suggested_design_created_at != design.created_at
        dr_date_bad     = suggested_dr_created_at     != design_review.created_at
        puts sprintf('  %-15s%-20sPosting Count: %-3s Original Posting: %-20s Last Reposting: %-20s',
                     design_review.review_type.name,
                     design_review.review_status.name,
                     design_review.posting_count.to_s,
                     design_review.created_at.format_dd_mon_yy('stamp'),
                     design_review.reposted_at.format_dd_mon_yy('stamp')) if show_all && (design_date_bad || dr_date_bad)

        if dr_date_bad
        puts '    =================================>'
        puts '    New Suggested Design Review Creation Date: ' + suggested_dr_created_at.format_dd_mon_yy('stamp')
        puts '    =================================>'
        end
      end

      if design_date_bad
        puts '--------------------------------->'
        puts 'New Suggested Design Creation Date: ' + suggested_design_created_at.format_dd_mon_yy('stamp')
        puts '--------------------------------->'
      end
    end

    DesignReview.find(:all).each do |design_review|
      #puts design_review.inspect
      if design_review.design_id == 1
        puts "Design ID is 1 for design review #{design_review.id.to_s}"
        next
      end
    end

    nil

  end


  def self.set_posting_timestamps(show_all = false)

    Design.find(:all).each do |design|

      suggested_design_created_at = design.created_at
      design_date_bad             = false

      puts
      puts '------------------------------------------------------------------'
      puts sprintf('%-5s%-20sCreated On: %-20s',
                   design_id,
                   design.directory_name,
                   design.created_at.format_day_mon_dd_yyyy_at_timestamp)
exit


      design.design_reviews.sort_by{ |dr| dr.review_type.sort_order }.each do |design_review|

        next if design_review.posting_count == 0

        suggested_dr_created_at = design_review.created_at < design_review.reposted_at ? design_review.created_at : design_review.reposted_at
        suggested_design_created_at = design_review.created_at  if suggested_design_created_at > design_review.created_at
        suggested_design_created_at = design_review.reposted_at if suggested_design_created_at > design_review.reposted_at

        design_date_bad = suggested_design_created_at != design.created_at
        dr_date_bad     = suggested_dr_created_at     != design_review.created_at

        puts sprintf('  %-15s%-20sPosting Count: %-3s Original Posting: %-20s Last Reposting: %-20s',
                     design_review.review_type.name,
                     design_review.review_status.name,
                     design_review.posting_count.to_s,
                     design_review.created_at.simple_date_with_timestamp,
                     design_review.reposted_at.simple_date_with_timestamp) if show_all || design_date_bad || dr_date_bad

        design_review.set_posting_timestamp(suggested_dr_created_at)

        if design_review.posting_count > 1
          design_review.set_posting_timestamp(design_review.reposted_at)
        end

        design_review.reload
        design_review.posting_timestamps.each do |ts|
          puts ts.inspect
          puts("----******----> #{ts.posted_on.simple_date_with_timestamp}")
        end
        
      end

      if design_date_bad
        puts '--------------------------------->'
        puts 'New Suggested Design Creation Date: ' + suggested_design_created_at.simple_date_with_timestamp
        puts '--------------------------------->'
      end
    end

    DesignReview.find(:all).each do |design_review|
      #puts design_review.inspect
      if design_review.design_id == 1
        puts "Design ID is 1 for design review #{design_review.id.to_s}"
        next
      end
      #puts('*** WARNING ***') if design_review.created_at > design_review.reposted_at
      #puts sprintf('%-20s%-15sPosting Count: %-3s Original Posting: %-20s Last Reposting: %-20s Design Creation: %-20s',
      #             design_review.design.directory_name,
      #             design_review.review_type.name,
      #             design_review.posting_count.to_s,
      #             design_review.created_at.simple_date_with_timestamp,
      #             design_review.reposted_at.simple_date_with_timestamp,
      #             design_review.design.created_at.simple_date_with_timestamp)
    end

    nil

  end


  def self.check_posting_timestamps

    Design.find(:all).each do |design|

      puts
      puts '------------------------------------------------------------------'
      puts sprintf('%-20sCreated On: %-20s',
                   design.directory_name,
                   design.created_at.simple_date_with_timestamp)

      design.design_reviews.sort_by{ |dr| dr.review_type.sort_order }.each do |design_review|

        next if design_review.posting_count == 0
        puts sprintf('  %-15s%-20sPosting Count: %-3s Original Posting: %-20s Last Reposting: %-20s',
                     design_review.review_type.name,
                     design_review.review_status.name,
                     design_review.posting_count.to_s,
                     design_review.created_at.simple_date_with_timestamp,
                     design_review.reposted_at.simple_date_with_timestamp)

        if design_review.posting_timestamps.size > 0
          puts "  !!!!!! POSTING COUNT DOES NOT MATCH TIMESTAMP COUNT" if design_review.posting_timestamps.size != design_review.posting_count
          design_review.posting_timestamps.each { |ts| puts "  ------ #{ts.posted_on.simple_date_with_timestamp}"}
        else
          puts("  ****** NO POSTING TIMESTAMPS")
        end


      end

    end

    nil

  end


  def self.posting_timestamps

    Design.find(:all).each do |design|

      puts
      puts '------------------------------------------------------------------'
      puts sprintf('%-20sCreated On: %-20s',
                   design.directory_name,
                   design.created_at.simple_date_with_timestamp)

      timestamp_value = Time.now - 10.year
      design.design_reviews.sort_by{ |dr| dr.review_type.sort_order }.each do |design_review|

        next if design_review.posting_count == 0
        puts sprintf('  %-15s%-20sPosting Count: %-3s',
                     design_review.review_type.name,
                     design_review.review_status.name,
                     design_review.posting_count.to_s)

        if design_review.posting_timestamps.size > 0
          puts "  !!!!!! POSTING COUNT DOES NOT MATCH TIMESTAMP COUNT" if design_review.posting_timestamps.size != design_review.posting_count
          design_review.posting_timestamps.each do |ts|
            puts "  ------ #{ts.posted_on.simple_date_with_timestamp}"
            if ts.posted_on.to_i <= timestamp_value.to_i
              puts 'TIMESTAMP ISSUE'
            end
            timestamp_value = ts.posted_on
          end
        else
          puts("  ****** NO POSTING TIMESTAMPS")
        end


      end

    end

    nil

  end


  def self.check_design_centers

    Design.find(:all).each do |design|

      design_centers_match = true
      design_center        = nil
      design.design_reviews.each do |design_review|
        design_center        = design_review.design_center if !design_center
        design_centers_match = design_center == design_review.design_center
        break if !design_centers_match
      end

      if !design_centers_match

        puts
        puts '------------------------------------------------------------------'
        puts sprintf('%-20s', design.directory_name)

        design.design_reviews.each do |design_review|
          puts '  *** ' + design_review.review_type.name
          if design_review.design_center
            puts '    *** ' + design_review.design_center.name
          else
            puts '    *** NO DESIGN CENTER'
          end

        end
      end

    end

    nil

  end


  def self.check_data_links_and_set_design(active_only = false, skip_update = true, print_all = false)

    # print_all - if false, only prints the designs that could not be found, otherwise all are printed
    # skip_update - set to false to update the database
    # active_only - set to true to update the designs that are active
    #
    puts
    puts '************************************************'
    puts '* Checking the accuracy of the design centers. *'
    puts '************************************************'
    puts
    
    all_design_centers = DesignCenter.get_all_active
    board_vault        = DesignCenter.find_by_name('Vault')
    info               = []
    design_center      = nil
    unknown_design_center = DesignCenter.find_by_name "Unknown"

    # Output the header
    puts 'Design ID,Directory Name,Phase,Original Assigned Design Center,' +
         'Found, Design Center Count, Where Found, Location, Final Assigned Design Center'
    Design.find(:all).each_with_index do |design, i|

      print_line = print_all

      next if active_only && design.phase_id == 255

      info << design.id.to_s
      info << design.directory_name
      info << design.phase.name
      unless design.design_center_id == 0
        info << design.design_center.name
        info << design.data_location_correct? ? 'YES' : 'NO'
      else
        info << 'DESIGN SETTING EMPTY'
        info << 'NO'
      end

      
      next if design.data_location_correct?

      link_good = false
      location  = nil
      link      = ''

      # Get a list of the listed pcb paths
      design.design_reviews.delete_if { |dr| !dr.design_center }
      design_centers = design.design_reviews.collect { |dr| dr.design_center }.compact.uniq

      design_centers << board_vault
      unlisted_design_centers = all_design_centers - design_centers

      # First try the listed design centers
      checked = "LISTED DESIGN CENTER"
      design.design_reviews.delete_if { |dr| !dr.design_center }.uniq!
      info << design_centers.uniq.size.to_s
      design.design_reviews.uniq.each do |dr|
        link_good = dr.data_found?
        link      = link_good ? dr.surfboards_path : 'NOT FOUND'
        if link_good
          design_center = dr.design_center
          break
        end
      end

      if !link_good
        # Try the board vault ...
        checked          = "BOARD VAULT"
        dr               = design.design_reviews.first
        design_center    = board_vault
        dr.design_center = board_vault
        link_good = dr.data_found?
        link      = link_good ? dr.surfboards_path : 'NOT FOUND'

        if !link_good

          # Try the unlisted design centers.
          unlisted_design_centers.each do |dc|
            checked = "UNLISTED DESIGN CENTERS"
            dr.design_center = dc
            link_good = dr.data_found?
            link      = link_good ? dr.surfboards_path : 'NOT FOUND'
            if link_good
              design_center = dr.design_center
              break
            end
          end
        end

      end

      info << checked
      design.design_center = design_center if design_center
      unless design.design_center_id == 0
        info << design.design_center.name
        if design.data_location_correct?
          info << design.surfboards_path
        else
          design.design_center = unknown_design_center
          print_line = true
          info << 'DESIGN SETTING EMPTY'
        end
      else
        design.design_center = unknown_design_center
        print_line = true
        info << 'DESIGN SETTING EMPTY'
      end
      info << design.design_center.name
      design.save unless skip_update

      puts info.join(', ') if print_line
      info.clear
    end

    nil

  end


#  def self.set_data_links(active_only = false, skip_update = true)
#
#    all_design_centers = DesignCenter.get_all_active
#    board_vault        = DesignCenter.find_by_name('Vault')
#    info               = []
#
#    h = Net::HTTP::new("boarddev.teradyne.com")
#
#    Design.find(:all).each_with_index do |design, i|
#
#      next if active_only && design.phase_id == 255
#
#      info << design.id.to_s
#      info << design.directory_name
#
#      link_good = false
#      location  = nil
#      link      = ''
#
#      # Get a list of the listed pcb paths
#      design.design_reviews.delete_if { |dr| !dr.design_center }
#      design_centers = design.design_reviews.collect { |dr| dr.design_center }.compact.uniq
#
#      TrackerFix.dump_design(design, 'Initial values: ')
#      puts design.directory_name + ' has multiple design centers **********************************' if design_centers.size > 1
#      design_centers << board_vault
#      unlisted_design_centers = all_design_centers - design_centers
#
#      design_center = nil
#      checked = ''
#      (design_centers + unlisted_design_centers).each_with_index do |design_center, i|
#
#        if i == 0
#          checked = "CHECKED LISTED DESIGN CENTERS"
#        elsif i == design_centers.size-1
#          checked = "CHECKED BOARD VAULT"
#        elsif i == design_centers.size
#          checked = "CHECKED UNLISTED DESIGN CENTERS"
#        end
#        pcb_path = design_center.pcb_path
#        link     = "/surfboards/#{pcb_path}/#{design.directory_name}/"
#        response = h.get(link)
#
#
#        link_good = response.code == '200'
#        result = link_good ? ' ***  PASSED' : ' !!!  FAILED  !!!!!!!!!!!!!!!'
#        # puts '  ' + link + result
#        break if link_good
#
#      end
#
#
#      info << checked
#      if link_good
#        design_center        = board_vault if design_center.pcb_path == 'board_vault'
#        design.design_center = design_center
#        design.save unless skip_update
#        TrackerFix.dump_design(design, 'Link Set:      ')
#
#        pcb_path = design.design_center.pcb_path
#        link     = "/surfboards/#{pcb_path}/#{design.directory_name}/"
#        response = h.get(link)
#
#        if response.code == '200'
#        else
#          puts "WARNING: LINK IS BAD"
#        end
#
#        info << link
#      else
#        info << '!!!!! NOT FOUND'
#      end
#
#      #puts info.join(',')
#      info.clear
#    end
#  end




  
  def self.dump_design(design, tag)
    design.reload
    puts '***  ' + tag + " ID: #{design.id}   Directory: #{design.directory_name}    Timestamp: #{design.created_on.format_dd_mm_yy_at_timestamp} "
    puts '---> ' + design.design_center.name if design.design_center
  end

  
  def self.set_fields(list, from_fields, to_fields)

    from_fields.each_index { |i| puts(" ** Copying from #{from_fields[i].to_s} field to the #{to_fields[i].to_s} field") }

    original_values = {}

    list.each do |r|
      from_fields.each_index do |i|
        line = r.id ? "\tID: #{r.id.to_s}": ''
        r[to_fields[i]] = r[from_fields[i]]
        next if !r[from_fields[i]]
        line += "\t#{from_fields[i].to_s}: #{r[from_fields[i]].simple_date_with_timestamp}"
        puts line + "\t->\t#{to_fields[i].to_s}: #{r[to_fields[i]].simple_date_with_timestamp}"
      end
      r.save
    end

  end


end

