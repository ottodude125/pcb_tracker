########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: part_number.rb
#
# This file maintains the state for part numbers.
#
# $Id$
#
########################################################################

class PartNumber < ActiveRecord::Base
  
  has_one :board_design_entry
  has_one :design
  
  
  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################
  
   
  ######################################################################
  #
  # get_part_number
  #
  # Description:
  # This method looks up the part number in the database given the 
  # components of the part number (prefix, number, and dash number)
  #
  # Parameters:
  # None
  #
  # Return value:
  # The part number record that matches the components if it exists in
  # the database.  If the record is not found then nil is returned.
  #
  ######################################################################
  #
  def self.get_part_number(pn)
    conditions = "pcb_prefix='#{pn.pcb_prefix}' AND " +
                 "pcb_number='#{pn.pcb_number}' AND " +
                 "pcb_dash_number='#{pn.pcb_dash_number}' AND " +
                 "pcb_revision='#{pn.pcb_revision}' AND " +
                 "pcba_prefix='#{pn.pcba_prefix}' AND " +
                 "pcba_number='#{pn.pcba_number}' AND " +
                 "pcba_dash_number='#{pn.pcba_dash_number}' AND " +
                 "pcba_revision='#{pn.pcba_revision}'"
                 
    self.find(:first, :conditions => conditions )
  end
  
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################
  
   
  ######################################################################
  #
  # valid?
  #
  # Description:
  # This method indicates that both the PCB and PCBA part numbers are
  # valid.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if both the PCB and PCBA part numbers are valid, FALSE otherwise.
  #
  ######################################################################
  #
  def valid?
    valid = self.valid_pcb_part_number? && self.valid_pcba_part_number?
    if !valid
      self[:error_message] = 'The correct format for a part number is ' +
                             '"ddd-ddd-aa" <br />' +
                             ' Where: "ddd" is a 3 digit number and "aa"' +
                             ' is 2 alpha-numeric characters.'
    end
    valid
  end
  
  
  ######################################################################
  #
  # valid_pcb_part_number?
  #
  # Description:
  # This method indicates that the PCB part number is valid.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the PCB part number is valid, FALSE otherwise.
  #
  ######################################################################
  #
  def valid_pcb_part_number?
    self.valid_pcb_prefix? && self.valid_pcb_number? && self.valid_pcb_dash_number?
  end
  
  
  ######################################################################
  #
  # valid_pcba_part_number?
  #
  # Description:
  # This method indicates that the PCBA part number is valid.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the PCB part number is valid, FALSE otherwise.
  #
  ######################################################################
  #
  def valid_pcba_part_number?
    self.valid_pcba_prefix? && self.valid_pcba_number? && self.valid_pcba_dash_number?
  end
  
  
  ######################################################################
  #
  # valid_prefix?
  #
  # Description:
  # This method indicates the part number prefix is valid
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the prefix is valid, FALSE otherwise.
  #
  ######################################################################
  #
  def valid_prefix?(prefix)
    prefix =~ /\d\d\d/
  end
  
  
  ######################################################################
  #
  # valid_pcb_prefix?
  #
  # Description:
  # This method indicates the PCB part number prefix is valid
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the PCB part number prefix is valid, FALSE otherwise.
  #
  ######################################################################
  #
  def valid_pcb_prefix?
    self.valid_prefix?(self.pcb_prefix)
  end
  
  
  ######################################################################
  #
  # valid_pcb_prefix?
  #
  # Description:
  # This method indicates the PCBA part number prefix is valid
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the PCBA part number prefix is valid, FALSE otherwise.
  #
  ######################################################################
  #
  def valid_pcba_prefix?
    self.valid_prefix?(self.pcba_prefix)
  end
  
  
  ######################################################################
  #
  # valid_number?
  #
  # Description:
  # This method indicates the part number number is valid
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the number is valid, FALSE otherwise.
  #
  ######################################################################
  #
  def valid_number?(number)
    number =~ /\d\d\d/
  end
  
  
  ######################################################################
  #
  # valid_number?
  #
  # Description:
  # This method indicates the PCB part  - number number is valid
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the PCB part number - number is valid, FALSE otherwise.
  #
  ######################################################################
  #
  def valid_pcb_number?
    self.valid_number?(self.pcb_number)
  end
  
  
  ######################################################################
  #
  # valid_number?
  #
  # Description:
  # This method indicates the PCBA part  - number number is valid
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the PCBA part number - number is valid, FALSE otherwise.
  #
  ######################################################################
  #
  def valid_pcba_number?
    self.valid_number?(self.pcba_number)
  end
  
  
  ######################################################################
  #
  # valid_dash_number?
  #
  # Description:
  # This method indicates the part number dash number is valid
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the dash number is valid, FALSE otherwise.
  #
  ######################################################################
  #
  def valid_dash_number?(dash_number)
    dash_number =~ /[A-Z,a-z,0-9][A-Z,a-z,0-9]/
  end
  
  
  ######################################################################
  #
  # valid_dash_number?
  #
  # Description:
  # This method indicates the PCB part number - dash number is valid
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the PCB part number - dash number is valid, FALSE otherwise.
  #
  ######################################################################
  #
  def valid_pcb_dash_number?
    self.valid_dash_number?(self.pcb_dash_number)
  end
  
  
  ######################################################################
  #
  # valid_dash_number?
  #
  # Description:
  # This method indicates the PCBA part number - dash number is valid
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the PCBA part number - dash number is valid, FALSE otherwise.
  #
  ######################################################################
  #
  def valid_pcba_dash_number?
    self.valid_dash_number?(self.pcba_dash_number)
  end
  
  
  ######################################################################
  #
  # error_message
  #
  # Description:
  # This method returns the error message string if the part number
  # is not valid.
  #
  # Parameters:
  # None
  #
  # Return value:
  # An error message string if the part number is not valid.  Otherwise
  # a nil is returned.
  #
  ######################################################################
  #
  def error_message
    self[:error_message]
  end

  
  ######################################################################
  #
  # entry_exists?
  #
  # Description:
  # This method determines if the board design entry for the part number
  # already exists in the database.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the board design entry exists in the database, otherwise
  # FALSE.
  #
  ######################################################################
  #
  def entry_exists?
    pn = PartNumber.get_part_number(self)
    exists = pn && pn.board_design_entry
    self[:error_message] = 'The entry already exists' if exists
    exists
  end
  
  
  ######################################################################
  #
  # exists?
  #
  # Description:
  # This method determines if the part number exists in the database.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the part number exists in the database, otherwise FALSE.
  #
  ######################################################################
  #
  def exists?
    PartNumber.get_part_number(self)
  end
  
  
  ######################################################################
  #
  # get_id
  #
  # Description:
  # This method uses the prefix, number, and dash number to look up
  # the part number in the database.  If the part number exists in the
  # database the id of the instance is updated with the one stored in the 
  # database.
  #
  # Parameters:
  # None
  #
  # Return value:
  # The instances' id field is updated if the part number exists in the
  # database.
  #
  ######################################################################
  #
  def get_id 
    part_number = PartNumber.get_part_number(self)
    part_number.id if part_number
  end
  
  
  ######################################################################
  #
  # pcb_name
  #
  # Description:
  # This method returns the PCB part number using the components of the 
  # part number (prefix, number, dash number, and PDM rev)
  #
  # Parameters:
  # None
  #
  # Return value:
  # The string representation of the PCB part number.
  #
  ######################################################################
  #
  def pcb_name
    "#{self.pcb_prefix}-#{self.pcb_number}-#{self.pcb_dash_number},#{self.pcb_revision}"
  end
  
  
  ######################################################################
  #
  # pcba_name
  #
  # Description:
  # This method returns the PCBA part number using the components of the 
  # part number (prefix, number, dash number, and PDM rev)
  #
  # Parameters:
  # None
  #
  # Return value:
  # The string representation of the PCBA part number.
  #
  ######################################################################
  #
  def pcba_name
    "#{self.pcba_prefix}-#{self.pcba_number}-#{self.pcba_dash_number},#{self.pcba_revision}"
  end
  
  
  def name
    self.pcb_name + ' / ' + self.pcba_name
  end
  
  
  ######################################################################
  #
  # unique?
  #
  # Description:
  # This method determines if the part number is unique based on the
  # prefix and number components of the part number.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the components do not match any records in the database.
  # Otherwise FALSE is returned.
  #
  ######################################################################
  #
#  def unique?
#    conditions = "prefix='#{self.prefix}' AND number='#{self.number}'"
#    PartNumber.find(:all, :conditions => conditions).size == 0
#  end


end
