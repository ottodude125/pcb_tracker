########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: debug_controller.rb
#
# This contains the logic that handles events from the outside world
# (user input), to generate the debug screens.
#
# $Id$
#
########################################################################

class DebugController < ApplicationController

require 'net/http'

before_filter(:verify_admin_role, :except => [:cycle_time])

  def audits
    @audits = Audit.find(:all)
  end
  
  
  ######################################################################
  #
  # view_change
  #
  ######################################################################
  #
  def view_change
    @change_classes = ChangeClass.find(:all, :order => :position)
  end
  
  
  ######################################################################
  #
  # view_checklist_details
  #
  ######################################################################
  #
  def view_checklist_details
    @audit              = Audit.find(params[:id])
    @filtered_audit     = Audit.find(params[:id])
    @trimmed_self_audit = Audit.find(params[:id])
    @trimmed_self_audit.trim_checklist_for_self_audit
    @trimmed_peer_audit = Audit.find(params[:id])
    @trimmed_peer_audit.trim_checklist_for_peer_audit
  end
  
  
  ######################################################################
  #
  # view_new_design_dangling_checks
  #
  ######################################################################
  #
  def view_new_design_dangling_checks
    
    @audit = Audit.find(params[:id])
    
    @audit.checklist.sections.each do |section|
      section.subsections.each do |subsection|
        subsection.checks.delete_if { |check| check.full_review?}
      end
    end
    
    design_checks = DesignCheck.find(:all, :conditions => "audit_id=#{@audit.id}")
    
    @audit.checklist.each_check do |check|
     check.design_check = design_checks.detect { |dc| dc.check_id == check.id }      
    end
    
  end
  
  
  ######################################################################
  #
  # boards
  #
  # Description:
  # Displays a list of boards in the system with links to the 
  # individual boards.
  #
  ######################################################################
  #
  def boards
    @boards = Board.find(:all)
  end


  ######################################################################
  #
  # design
  #
  # Description:
  # Displays a list of designs for a particular board with links to the 
  # individual designs
  #
  ######################################################################
  #
  def design
    @board   = Board.find(params[:id])
    @designs = Design.find_all_by_board_id(@board.id)
  end


  ######################################################################
  #
  # design_reviews
  #
  # Description:
  # Displays a list of design reviewss for a particular design with links
  # to the individual design reviews.
  #
  ######################################################################
  #
  def design_reviews
    @design = Design.find(params[:id])
    @board  = Board.find(@design.board_id)

    @design_reviews = DesignReview.find_all_by_design_id(@design.id).sort_by { |dr|
      dr.review_type.sort_order
    }

  end


  ######################################################################
  #
  # orphaned_audits
  #
  # Description:
  # Displays a list of audits that have no parent design.
  #
  ######################################################################
  #
  def orphaned_audits

    @audit_list = {}
    Audit.find(:all).each do |audit|
      begin
        @audit_list[audit.id] = Design.find(audit.design_id).name
      rescue
        @audit_list[audit.id] = "ORPHAN"
      end
    end

  end


  ######################################################################
  #
  # orphaned_checks
  #
  # Description:
  # Displays a list of checks that have no parent section or subsection.
  #
  ######################################################################
  #
  def orphaned_checks

    @section_list    = {}
    @subsection_list = {}
    Check.find(:all).each do |check|
      begin
        Section.find(check.section_id)
      rescue
        @section_list[check.id] = check.section_id
      end

      begin
        Subsection.find(check.subsection_id)
      rescue
        @subsection_list[check.id] = check.subsection_id
      end
    end

  end


  ######################################################################
  #
  # check_lists
  #
  # Description:
  # Displays a list of checklists with links to the individual
  # checklists.
  #
  ######################################################################
  #
  def checklists
    @checklists = Checklist.find(:all, :order => 'created_on')
  end


  ######################################################################
  #
  # checklist
  #
  # Description:
  # Provides the details for an individual checklist.
  #
  ######################################################################
  #
  def checklist
    @checklist = Checklist.find(params[:id])
    @subsection_count = 0
    @check_count      = 0
    @checklist.sections.each do |section|
      @subsection_count += section.subsections.size

      section.subsections.each do |subsection|
        @check_count += subsection.checks.size
      end
      
    end

    section_count       = @checklist.sections.size
    expected_section_so = 1
    @messages = []

    urls = {}
    #sections = @checklist.sections.sort_by { |s| s.position }
    @checklist.sections.each do |section|
      if section.position != expected_section_so
        @messages.push   "Section #{section.id}: Expected sort order " +
                         "#{expected_section_so}  " +
                         "actual: #{section.position}"
      end
      if section.position > section_count
        @messages.push   "Section #{section.id}: sort order " +
                         "#{section.position}  " +
                         "is greater than the number of sections: #{section_count}"
      end
      expected_section_so += 1

      subsection_count       = section.subsections.size
      expected_subsection_so = 1
      
      logger.info "#############################################"
      logger.info "                   SECTION"
      logger.info "  URL: #{section.url}"
      if section.url != ''
        url = section.url.split('/')
        logger.info " BASE: #{url[0]}"
        if !urls[section.url]
          h = Net::HTTP::new(url.shift)
          urls[section.url] = h.get('/' + url.join('/'))
        end
        section[:resp] = { :message => urls[section.url].message,
                           :code    => urls[section.url].code }
      end
      logger.info "#############################################"

      #subsections = section.subsections.sort_by { |s| s.position }
      section.subsections.each do |subsection|
        if subsection.position != expected_subsection_so
          @messages.push   "Subsection #{subsection.id}: Expected sort order " +
                         "#{expected_subsection_so}  " +
                         "actual: #{subsection.position}"
        end
        if subsection.position > subsection_count
          @messages.push   "Subsection #{subsection.id}: Sort order " +
                           "#{subsection.position}  " +
                           "is greater than the number of sections: #{subsection_count}"
        end
        expected_subsection_so += 1

        check_count       = subsection.checks.size
        expected_check_so = 1
        
        logger.info "#############################################"
        logger.info "                SUBSECTION"
        logger.info "  URL: #{subsection.url}"
        if subsection.url != ''
          url = subsection.url.split('/')
          logger.info " BASE: #{url[0]}"
          if !urls[subsection.url]
            h = Net::HTTP::new(url.shift)
            urls[subsection.url], data = h.get('/' + url.join('/'))
          end
          subsection[:resp] = { :message => urls[subsection.url].message,
                                :code    => urls[subsection.url].code }
        end
        logger.info "#############################################"

        #checks = subsection.checks.sort_by { |c| c.position }
        subsection.checks.each do |check|
          if check.position != expected_check_so
            @messages.push   "Check #{check.id}: Expected sort order " +
                             "#{expected_check_so}  " +
                             "actual: #{check.position}"
          end
          if check.position > check_count
            @messages.push   "Check #{check.id}: Sort order " +
                             "#{check.position}  " +
                             "is greater than the number of sections: #{check_count}"
          end
          expected_check_so += 1
          
          if check.url != ''
            url = check.url.split('/')
            if !urls[check.url]
              h = Net::HTTP::new(url.shift)
              urls[check.url], data = h.get('/' + url.join('/'))
            end
            check[:resp] = { :message => urls[check.url].message,
                             :code    => urls[check.url].code }
          end

        end
        
      end
    end
  end
  
  
  def board_design_entries
    @bde_list = BoardDesignEntry.find(:all)
  end


  def active_users
   @users = User.find(:all, :conditions => 'active=true', :order => 'last_name')
   @title = 'Active Users'
   render(:action => 'users')
  end


  def users
   @users = User.find(:all, :order => 'last_name')
   @title = 'All Users'
  end


  def inactive_users
   @users = User.find(:all, :conditions => 'active=false', :order => 'last_name')
   @title = 'Inactive Users'
   render(:action => 'users')
  end


  def select_reviewers
    
    @review_types = ReviewType.get_review_types
    @review_roles = Role.get_review_roles
    @users        = User.find(:all)
    
  end
  
  
  def cycle_time
    
    @cycle_times  = []
    @review_types = []
    @roles        = []
    params.each do |param|
    
      p = param[0].split('_')
      
      if p[0] == 'role'
        if p.size == 2
          role = Role.find(p[1])
          @roles << role
          role.users.each do |user|
            if !@cycle_times.detect { |ct| ct[:user].id == user.id }
              @cycle_times << { :user => user, :design_reviews => [] }
            end
          end
        end
      elsif p[0] == 'rt'
        @review_types << ReviewType.find(p[1])
      end
      
      @cycle_times = @cycle_times.sort_by { |ct| ct[:user].last_name }
    
    end

    @roles = @roles.uniq
    
    @cycle_times.each do |ct|
      review_results = DesignReviewResult.find_all_by_reviewer_id(ct[:user].id)
      review_results.delete_if { |rr| rr.result == 'No Response' || rr.result == 'NONE' }
      review_results.delete_if { |rr| !@review_types.include?(rr.design_review.review_type) }
      review_results.delete_if { |rr| !@roles.include?(rr.role)}
      ct[:design_reviews] = review_results
    end
    
    @cycle_times.delete_if { |ct| ct[:design_reviews].size == 0 }
    
    if @cycle_times.size == 0
      redirect_to(:action => 'select_reviewers')
      flash['notice'] = "No Records Returned"
    end
  
  end


  def designs
    @designs = Design.find(:all)
  end
  
  
  def delete_part_number
    
    part_number = PartNumber.find(params[:id])
    flash['notice'] = 'PCB Part Number ' + part_number.pcb_display_name + 
                      ' has been removed from the database.'
    
    part_number.destroy
    redirect_to(:action => 'part_numbers')
    
  end
  
  
  def part_numbers
    @part_numbers = PartNumber.find(:all)
    designs       = Design.find(:all)
    bde_list      = BoardDesignEntry.find(:all)
    
    @part_numbers.each do |pn|
      pn_designs = []
      pn_bdes    = []
      
      designs.each { |d| pn_designs << d if d.part_number_id == pn.id }
      pn[:design_count] = pn_designs.size
      if pn_designs.size == 0
        pn[:design_id] = '-'
      elsif pn_designs.size == 1
        pn[:design_id] = pn_designs[0].id
      else
        pn[:design_id] = 'ERR'
      end
      
      bde_list.each { |bde| pn_bdes << bde if bde.part_number_id == pn.id }
      pn[:bde_count] = pn_bdes.size
      if pn_bdes.size == 0
        pn[:bde_id] = '-'
      elsif pn_bdes.size == 1
        pn[:bde_id] = pn_bdes[0].id
      else
        pn[:bde_id] = 'ERR'
      end
      
    end
  end

end
