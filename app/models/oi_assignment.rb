########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: oi_assignment.rb
#
# This file maintains the state for oi_assignments.
#
# $Id$
#
########################################################################

class OiAssignment < ActiveRecord::Base

  has_many(:oi_assignment_comments,
           :order => "created_on DESC")
  
  has_one    :oi_assignment_report
  
  belongs_to :oi_instruction
  belongs_to :user
  
  
  ##############################################################################
  #
  # Constants
  # 
  ##############################################################################

  COMPLEXITY = [ ['High',   1],
                 ['Medium', 2], 
                 ['Low',    3] ]


  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


  ######################################################################
  #
  # complexity_list
  #
  # Description:
  # This method returns the complexity list.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def self.complexity_list
    COMPLEXITY
  end
  
  
  ######################################################################
  #
  # complexity_id
  #
  # Description:
  # This method returns the id associated with the complexity name.
  #
  # Parameters:
  # name - The complexity name
  #
  ######################################################################
  #
  def self.complexity_id(name)
    COMPLEXITY.detect { |c| c[0] == name }[1]
  rescue
    0
  end
  
  
  ######################################################################
  #
  # complexity_name
  #
  # Description:
  # This method returns the name associated with the complexity id.
  #
  # Parameters:
  # id - The complexity identifier
  #
  ######################################################################
  #
  def self.complexity_name(id)
    COMPLEXITY[id-1][0]
  rescue
    "Undefined"
  end
  
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################


  ######################################################################
  #
  # complexity_name
  #
  # Description:
  # This method returns the complexity name for the oi_assigment.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def complexity_name
    COMPLEXITY[self.complexity_id-1][0]
  end
  
  
  ######################################################################
  #
  # task_duration
  #
  # Description:
  # This method returns the duration of the task.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def task_duration

    if self.complete?
      sprintf("%4.1f", (self.completed_on - self.created_on) / 1.day)
    else
      '0'
    end

  end
  
  
  ######################################################################
  #
  # email_update_header
  #
  # Description:
  # This method returns the header in a string for emails.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def email_update_header
    col  = 18
    hdr  = "------------------------------------------------------------------------\n" +
           'Design : '.rjust(col)        + self.oi_instruction.design.name                          + "\n" +
           'Category : '.rjust(col)      + self.oi_instruction.oi_category_section.oi_category.name + "\n" +
           'Step : '.rjust(col)          + self.oi_instruction.oi_category_section.name             + "\n" +
           'Team Lead : '.rjust(col)     + self.oi_instruction.user.name                            + "\n" +
           'Designer : '.rjust(col)      + self.user.name                                           + "\n" +
           'Date Assigned : '.rjust(col) + self.created_on.strftime("%d-%b-%y, %I:%M %p %Z")        + "\n" +
           'Complete : '.rjust(col)
    if self.complete?
      hdr += "Yes\n" +
             'Completed On : '.rjust(col) + self.completed_on.strftime("%d-%b-%y, %I:%M %p %Z") + "\n"
    else
      hdr += "No\n"
    end

    if self.oi_instruction.oi_category_section.urls.size > 0
      label = true
      self.oi_instruction.oi_category_section.urls.each do |url|
      
        if label
          hdr   += 'References : '.rjust(col)
          label  = false
        else
          hdr   += ' : '.rjust(col)
        end
        
        if url[:text] != ''
          hdr += url[:text] + "\n" + ' : '.rjust(col) + url[:url] + "\n"
        else
          hdr += url[:url] + "\n"
        end
      
      end
    end

    hdr +=       "------------------------------------------------------------------------\n"

    
    hdr
    
  end

end
