########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: checklist_controller.rb
#
# This contains the logic to create, modify, and delete checklists.
#
# $Id$
#
########################################################################

class ChecklistController < ApplicationController

  before_filter :verify_admin_role


  ######################################################################
  #
  # release
  #
  # Description:
  # This method performs all of the tasks related to releasing a 
  # Peer Audit Checklist.
  #
  # Parameters from @params
  # ['id'] - Used to identify the checklist to be released.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def release
    
    checklist = Checklist.find(@params['id'])
    latest_release = 
      Checklist.find_all("released=1", 'major_rev_number ASC').pop

    checklist.minor_rev_number = 0
    checklist.major_rev_number = latest_release.major_rev_number + 1
    checklist.released         = 1
    checklist.released_on      = ''

    if checklist.update_attributes(checklist.attributes)
      flash['notice'] = 'Checklist successfully released'
    else
      flash['notice'] = 'Checklist release failed - Contact DTG.'
    end

    redirect_to :action => 'list'

  end


  ######################################################################
  #
  # select_view
  #
  # Description:
  # Provide the user with a selection of list types to choose from 
  # prior to viewing a checklist.
  #
  # Parameters from @params
  # ['id'] - Used to identify the checklist.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def select_view
    @checklist = Checklist.find(@params['id'])
  end


  #
  def displayable(review_type,
                  full_review,
                  date_code_check,
                  dot_rev_check)

    if review_type == 'full'
      full_review == 1
    elsif review_type == 'date_code'
      date_code_check == 1
    elsif review_type == 'dot_rev'
      dot_rev_check == 1
    end

  end


  ######################################################################
  #
  # display_list
  #
  # Description:
  # Collect the data for the check list that was selected for display.
  #
  # Parameters from @params
  # ['review']    - identifies the review type
  # ['checklist'] - the checklist to be displayed.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def display_list

    @review_type = @params['review']['review_type']

    @checklist = Checklist.find(@params['checklist']['id'])
    @sections = Section.find_all("checklist_id=#{@checklist.id}", 
                                 'sort_order ASC')

    @display_boxes = []
    for section in @sections
      
      subsections = Subsection.find_all("section_id=#{section.id}",
                                        'sort_order ASC')
      if displayable(@review_type,
                     section.full_review,
                     section.date_code_check,
                     section.dot_rev_check)

        for subsection in subsections
          
          display_box = []
          if displayable(@review_type,
                         subsection.full_review,
                         subsection.date_code_check,
                         subsection.dot_rev_check)
            display_box[0] = section.dup
            display_box[1] = subsection.dup
            
            checks = 
              Check.find_all("section_id=#{section.id} AND subsection_id=#{subsection.id}",
                             'sort_order ASC')
            peer_checks = []
            for check in checks
              if displayable(@review_type,
                             check.full_review,
                             check.date_code_check,
                             check.dot_rev_check)
                peer_checks.push(check.dup)
              end
            end

            formatted_checks = []
            # Arrange the checks for display.
            rows = (peer_checks.size / 2) + peer_checks.size.modulo(2)
            0.upto((rows-1)) { |i|
              row = []
              row[0] = peer_checks[i]
              row[1] = peer_checks[i+rows]
              formatted_checks.push(row)
            }

            display_box[2] = formatted_checks
            @display_boxes.push(display_box)

          end # if subsection should be displayed.
        end   # for subsection in subsections
      end     # if section should be displayed
    end       # for section in sections
  end


  ######################################################################
  #
  # list
  #
  # Description:
  # Collect the data to display the available checklists.
  #
  # Parameters from @params
  #   None
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def list

    @checklist_pages, @checklists = paginate(:checklists,
                                             :per_page   => 15,
                                             :order_by   => 'released_on DESC')
  end


  ######################################################################
  #
  # view
  #
  # Description:
  # Collect the data to display the available checklists.
  #
  # Parameters from @params
  # ['id'] - identifies the checklist.
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def view
    @checklist = Checklist.find(@params["id"])
    sections   = Section.find_all("checklist_id=#{@params['id']}", 'sort_order')

      @displaySections = []
    for section in sections
      completeSection = []
      completeSection[0] = section
      completeSection[1] = Subsection.find_all("section_id=#{section.id}", 'sort_order')
        @displaySections.push(completeSection)
    end

  end


  ######################################################################
  #
  # edit
  #
  # Description:
  # Collect the data to edit the identified peer audit checklist.
  #
  # Parameters from @params
  # ['id'] - identifies the checklist that will be edited
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def edit

    @checklist = Checklist.find(@params["id"])
    sections   = Section.find_all("checklist_id=#{@params['id']}", 
                                  'sort_order')
    @displaySections = []
    for section in sections

      completeSection    = []
      completeSection[0] = section
      completeSection[1] = []

      subsections = Subsection.find_all("section_id=#{section.id}", 
                                        'sort_order')

      for subsect in subsections
        sub = []
        sub[0] = subsect
        checks = Check.find_all("subsection_id=#{subsect.id}", 
                                'sort_order')
        sub[1] = checks.size
	
        completeSection[1].push(sub)
      end
        
      @displaySections.push(completeSection)
    end

  end


  ######################################################################
  #
  # destroy
  #
  # Description:
  # Remove the identified peer audit checklist from the database.
  #
  # Parameters from @params
  #   ['id'] - the ID of the checklist to be destroyed
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def destroy

    sections = Section.find_all("checklist_id=#{params['id']}")
    for section in sections
      Check.destroy_all("section_id = #{section.id}")
    end

    Subsection.destroy_all("checklist_id=#{params['id']}")
    Section.destroy_all("checklist_id=#{params['id']}")
    Checklist.destroy_all("id=#{params['id']}")
        
    redirect_to  :action => 'list'    

  end


  ######################################################################
  #
  # copy
  #
  # Description:
  # Make a copy of the identified checklist.
  #
  # Parameters from @params
  #   ['id'] - the ID of the checklist to be copied
  #
  # Return value:
  # None
  #
  # Additional information:
  #
  ######################################################################
  #
  def copy

    # Copy the checklist.
    existing_checklist = Checklist.find(@params['id']).attributes
    existing_checklist['released']    = 0
    existing_checklist['used']        = 0
    existing_checklist['released_by'] = 0
    existing_checklist['created_by']  = 0

    # Get the highest minor rev number for the revision and bump that
    # number by 1
    latest_checklist =
      Checklist.find_all("major_rev_number=#{existing_checklist['major_rev_number']}", 
                         'minor_rev_number ASC').pop
    existing_checklist['minor_rev_number'] =
      latest_checklist.minor_rev_number + 1
      
    existing_checklist.delete('created_on')
    existing_checklist.delete('released_on')
      
    new_checklist = Checklist.create(existing_checklist)
    
    # Copy all of the sections
    sections = Section.find_all("checklist_id=#{@params['id']}")
    for section in sections
      section.checklist_id = new_checklist['id']
      new_section = Section.create(section.attributes)

      # Copy all of the subsections
      subsections = 
        Subsection.find_all("checklist_id=#{@params['id']} AND section_id=#{section.id}")
        for subsection in subsections
          subsection.checklist_id = new_checklist.id
          subsection.section_id   = new_section.id
          new_subsection = Subsection.create(subsection.attributes)

          # Copy all of the checks.
          checks = 
            Check.find_all("section_id=#{section.id} AND subsection_id=#{subsection.id}")
            for check in checks
              check.section_id    = new_section.id
              check.subsection_id = new_subsection.id
              new_check = Check.create(check.attributes)
            end
        end
    end

    redirect_to  :action => 'list'    

  end
  
  
end
