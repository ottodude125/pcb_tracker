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

before_filter(:verify_admin_role)

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
    @boards = Board.find_all(nil,"name ASC")
  end


  ######################################################################
  #
  # designs
  #
  # Description:
  # Displays a list of designs for a particular board with links to the 
  # individual designs
  #
  ######################################################################
  #
  def designs
    @board   = Board.find(@params[:id])
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
    @design = Design.find(@params[:id])
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

    audits = Audit.find_all

    @audit_list = {}
    for audit in audits
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

    checks = Check.find_all

    @section_list    = {}
    @subsection_list = {}
    for check in checks
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
    @checklists = Checklist.find_all(nil, 'created_on ASC')
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
    @checklist = Checklist.find(@params[:id])
    @subsection_count = 0
    @check_count      = 0
    for section in @checklist.sections
      @subsection_count += section.subsections.size

      for subsection in section.subsections
        @check_count += subsection.checks.size
      end
      
    end

    section_count       = @checklist.sections.size
    expected_section_so = 1
    @messages = []

    urls = {}
    #sections = @checklist.sections.sort_by { |s| s.sort_order }
    for section in @checklist.sections
      if section.sort_order != expected_section_so
        @messages.push   "Section #{section.id}: Expected sort order " +
                         "#{expected_section_so}  " +
                         "actual: #{section.sort_order}"
      end
      if section.sort_order > section_count
        @messages.push   "Section #{section.id}: sort order " +
                         "#{section.sort_order}  " +
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

      #subsections = section.subsections.sort_by { |s| s.sort_order }
      for subsection in section.subsections
        if subsection.sort_order != expected_subsection_so
          @messages.push   "Subsection #{subsection.id}: Expected sort order " +
                         "#{expected_subsection_so}  " +
                         "actual: #{subsection.sort_order}"
        end
        if subsection.sort_order > subsection_count
          @messages.push   "Subsection #{subsection.id}: Sort order " +
                           "#{subsection.sort_order}  " +
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

        #checks = subsection.checks.sort_by { |c| c.sort_order }
        for check in subsection.checks
          if check.sort_order != expected_check_so
            @messages.push   "Check #{check.id}: Expected sort order " +
                             "#{expected_check_so}  " +
                             "actual: #{check.sort_order}"
          end
          if check.sort_order > check_count
            @messages.push   "Check #{check.id}: Sort order " +
                             "#{check.sort_order}  " +
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


  def users

    @users = User.find_all(nil, 'last_name ASC')
  
  end

end
