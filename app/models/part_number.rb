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
  # initial_part_number
  #
  # Description:
  # This method provides an initialize part number.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A new, initialized part number record.
  #
  ######################################################################
  #
  def self.initial_part_number
    PartNumber.new( :pcb_prefix       => '000',
                    :pcb_number       => '000',
                    :pcb_dash_number  => '00',
                    :pcb_revision     => '0',
                    :pcba_prefix      => '000',
                    :pcba_number      => '000',
                    :pcba_dash_number => '00',
                    :pcba_revision    => '0')

  end
 
  
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
                 "pcb_revision='#{pn.pcb_revision}'"
                 
    if pn.new?
      conditions += ' AND ' +
                    "pcba_prefix='#{pn.pcba_prefix}' AND " +
                    "pcba_number='#{pn.pcba_number}' AND " +
                    "pcba_dash_number='#{pn.pcba_dash_number}' AND " +
                    "pcba_revision='#{pn.pcba_revision}'"
    end                  

    self.find(:first, :conditions => conditions )
  end
  
  
  ######################################################################
  #
  # get_unique_pcb_numbers
  #
  # Description:
  # This method provides a list of sorted, unique PCB part numbers.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of unique PCB part numbers represented as strings.
  #
  ######################################################################
  #
  def self.get_unique_pcb_numbers
    part_number_list = PartNumber.find(:all)
    part_number_list.delete_if do |pn| 
      ((pn.board_design_entry && pn.board_design_entry.complete?) ||
       (!pn.design))
    end
    part_number_list.collect { |pn| pn.pcb_prefix + '-' + pn.pcb_number }.uniq.sort
  end
  
  
  ######################################################################
  #
  # get_designs
  #
  # Description:
  # Provides a list of designs given a unique PCB part number
  #
  # Parameters:
  # unique_part_number - a string representing a unique PCB Part Number.
  #
  # Return value:
  # A list of designs related to the uniqu PCB Part Number.
  #
  ######################################################################
  #
  def self.get_designs(unique_part_number)
    
    components = unique_part_number.split('-')
    part_numbers = PartNumber.find(:all, 
                                   :conditions => "pcb_prefix='#{components[0]}' " +
                                                  "AND pcb_number='#{components[1]}'")
                                   
    designs = part_numbers.collect { |pn| pn.design }.reverse
    designs.delete_if { |d| !d }
    designs
    
  end
  
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################
  

  ######################################################################
  #
  # new?
  #
  # Description:
  # This method compares the object's pcba part number to the pcba
  # part number of an initial part number to set the the pcba number 
  # has been set.
  #
  # Parameters:
  # part_number - Contains the pcb part number for comparison.
  #
  # Return value:
  # TRUE if the PCBA part numbers passed does not contain the 
  # initial PCBA values, FALSE otherwise.
  #
  ######################################################################
  #
  def new?
    !self.pcba_pn_equal?(PartNumber.initial_part_number)
  end
  
  
  ######################################################################
  #
  # pcb_pn_equal?
  #
  # Description:
  # This method compares the object's pcb part number to the pcb
  # part number passed in.
  #
  # Parameters:
  # part_number - Contains the pcb part number for comparison.
  #
  # Return value:
  # TRUE if both the PCB part numbers are equal, FALSE otherwise.
  #
  ######################################################################
  #
  def pcb_pn_equal?(part_number)
    self.pcb_prefix      == part_number.pcb_prefix      &&
    self.pcb_number      == part_number.pcb_number      &&
    self.pcb_dash_number == part_number.pcb_dash_number &&
    self.pcb_revision    == part_number.pcb_revision
  end
  
  
  ######################################################################
  #
  # pcba_pn_equal?
  #
  # Description:
  # This method compares the object's pcba part number to the pcba
  # part number passed in.
  #
  # Parameters:
  # part_number - Contains the pcba part number for comparison.
  #
  # Return value:
  # TRUE if both the PCBA part numbers are equal, FALSE otherwise.
  #
  ######################################################################
  #
  def pcba_pn_equal?(part_number)
    self.pcba_prefix      == part_number.pcba_prefix      &&
    self.pcba_number      == part_number.pcba_number      &&
    self.pcba_dash_number == part_number.pcba_dash_number &&
    self.pcba_revision    == part_number.pcba_revision
  end
  
  
  ######################################################################
  #
  # valid?
  #
  # Description:
  # This method indicates that both the PCB and PCBA part numbers are
  # valid.
  #
  # Parameters:
  # new - a bolean that indicates that the entry is new requiring both
  #       PCB and PCBA components.
  #
  # Return value:
  # TRUE if both the PCB and PCBA part numbers are valid, FALSE otherwise.
  #
  ######################################################################
  #
  def valid?(new)

    self.clear_error_message
    
    # Make sure the part number contains the correct and legal characters.
    valid  = self.valid_pcb_part_number?
    valid &= self.valid_pcba_part_number? if new
    if valid
      if (self.pcb_prefix      == self.pcba_prefix      &&
          self.pcb_number      == self.pcba_number      &&
          self.pcb_dash_number == self.pcba_dash_number &&
          self.pcb_revision    == self.pcba_revision)
        valid = false
        self.set_error_message('The PCB part number (' + self.pcb_display_name +
                               ') and the PCBA part number (' + 
                               self.pcba_display_name + ') must be different')
      end
    else
      self.set_error_message('The correct format for a part number is ' +
                             '"ddd-ddd-aa" <br />' +
                             ' Where: "ddd" is a 3 digit number and "aa"' +
                             ' is 2 alpha-numeric characters.')
    end

    (valid && (new ? !self.exists?(false) : !self.pcb_pn_exists?(false)))
    
  end
  
  
  ######################################################################
  #
  # pcb_unique_number
  #
  # Description:
  # Returns the unique portion of a part number
  #
  # Parameters:
  # None
  #
  # Return value:
  # A string representing the unique portion of a part number.
  #
  ######################################################################
  #
  def pcb_unique_number
    self.pcb_prefix + '-' + self.pcb_number
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
    result = prefix =~ /\d\d\d/
    return (result != nil)
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
    result = number =~ /\d\d\d/
    return (result != nil)
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
    result = dash_number =~ /[A-Z,a-z,0-9][A-Z,a-z,0-9]/
    return (result != nil)
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
  # set_error_message
  #
  # Description:
  # This method sets the part number error message
  #
  # Parameters:
  # msg - the error message string
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def set_error_message(msg)
    if self[:error_message]
      self[:error_message] += "\n" + msg
    else
      self[:error_message] = msg
    end
  end
  
  ######################################################################
  #
  # clear_error_message
  #
  # Description:
  # This method resets the part number error message
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def clear_error_message
    self[:error_message] = nil
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
  # clear_error_message - a flag that indicates to reset the error 
  #                       message when true.
  #
  # Return value:
  # TRUE if the board design entry exists in the database, otherwise
  # FALSE.
  #
  ######################################################################
  #
  def entry_exists?(clear_error_message = true)
    self.clear_error_message if clear_error_message

    pn = PartNumber.get_part_number(self)
    exists = pn != nil && pn.board_design_entry != nil
    self.set_error_message('The entry already exists') if exists
    exists
  end
  
  
  ######################################################################
  #
  # pcba_pn_exists?
  #
  # Description:
  # This method determines if the PCBA component of the part number exists 
  # in either the PCB or PCBA component of an existing entry in the database.
  #
  # Parameters:
  # clear_error_message - a flag that indicates to reset the error 
  #                       message when true.
  #
  # Return value:
  # TRUE if the PCBA component is found in a PCB or PCBA component in the 
  # database, otherwise FALSE.
  #
  ######################################################################
  #
  def pcba_pn_exists?(clear_error_message = true)

    self.clear_error_message if clear_error_message
    
    pcb_pn = PartNumber.find( :first,
                              :conditions => "pcb_prefix='#{self.pcba_prefix}' AND " +
                                             "pcb_number='#{self.pcba_number}' AND " +
                                             "pcb_dash_number='#{self.pcba_dash_number}' AND " +
                                             "pcb_revision='#{self.pcba_revision}'")
    pcba_pn = PartNumber.find( :first,
                               :conditions => "pcba_prefix='#{self.pcba_prefix}' AND " +
                                              "pcba_number='#{self.pcba_number}' AND " +
                                              "pcba_dash_number='#{self.pcba_dash_number}' AND " +
                                              "pcba_revision='#{self.pcba_revision}'")
    if pcb_pn
      self.set_error_message('The supplied PCBA Part Number exists as a PCB ' +
                             'Part Number in the database')
    elsif pcba_pn
      self.set_error_message('The supplied PCBA Part Number exists as a PCBA ' +
                             'Part Number in the database')
    end
    return !(pcb_pn == nil && pcba_pn == nil)
  end
  

  ######################################################################
  #
  # pcb_pn_exists?
  #
  # Description:
  # This method determines if the PCB component of the part number exists 
  # in either the PCB or PCBA component of an existing entry in the database.
  #
  # Parameters:
  # clear_error_message - a flag that indicates to reset the error 
  #                       message when true.
  #
  # Return value:
  # TRUE if the PCB component is found in a PCB or PCBA component in the 
  # database, otherwise FALSE.
  #
  ######################################################################
  #
  def pcb_pn_exists?(clear_error_message = true)
    
    self.clear_error_message if clear_error_message
    
    pcb_pn = PartNumber.find( :first,
                              :conditions => "pcb_prefix='#{self.pcb_prefix}' AND " +
                                             "pcb_number='#{self.pcb_number}' AND " +
                                             "pcb_dash_number='#{self.pcb_dash_number}' AND " +
                                             "pcb_revision='#{self.pcb_revision}'")
    pcba_pn = PartNumber.find( :first,
                               :conditions => "pcba_prefix='#{self.pcb_prefix}' AND " +
                                              "pcba_number='#{self.pcb_number}' AND " +
                                              "pcba_dash_number='#{self.pcb_dash_number}' AND " +
                                              "pcba_revision='#{self.pcb_revision}'")
    if pcb_pn
      self.set_error_message('The supplied PCB Part Number exists as a PCB ' +
                             'Part Number in the database')
    elsif pcba_pn
      self.set_error_message('The supplied PCB Part Number exists as a PCBA ' +
                             'Part Number in the database')
    end
    return !(pcb_pn == nil && pcba_pn == nil)
  end

  
  ######################################################################
  #
  # exists?
  #
  # Description:
  # This method determines if the part number exists in the database.
  #
  # Parameters:
  # clear_error_message - a flag that indicates to reset the error 
  #                       message when true.
  #
  # Return value:
  # TRUE if the part number exists in the database, otherwise FALSE.
  #
  ######################################################################
  #
  def exists?(clear_error_message = true)

    exists = false
    self.clear_error_message if clear_error_message

    if PartNumber.get_part_number(self) != nil
      if self.new?
        self.set_error_message('The supplied PCB and PCBA Part Number is ' +
                               'already in the database')
      else
        self.set_error_message('The supplied PCB Part Number exists as a PCB' +
                               ' Part Number in the database')
      end
      exists = true
    end

    exists = exists || self.pcb_pn_exists?(clear_error_message)
    exists = (exists || self.pcba_pn_exists?(clear_error_message)) if self.new?

    return exists

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
  # This method returns the PCB part number without the revision.
  #
  # Parameters:
  # None
  #
  # Return value:
  # The string representation of the PCB part number, excluding the revision.
  #
  ######################################################################
  #
  def pcb_name
    "#{self.pcb_prefix}-#{self.pcb_number}-#{self.pcb_dash_number}"
  end
  

  ######################################################################
  #
  # pcb_display_name
  #
  # Description:
  # This method returns the PCB part number with the revision.
  #
  # Parameters:
  # None
  #
  # Return value:
  # The string representation of the PCB part number, including the revision.
  #
  ######################################################################
  #
  def pcb_display_name
    name  = self.pcb_name
    name += ' ' + self.pcb_revision if self.pcb_revision.size > 0
    name
  end
  
  
  ######################################################################
  #
  # pcba_name
  #
  # Description:
  # This method returns the PCBA part number without the revision.
  #
  # Parameters:
  # None
  #
  # Return value:
  # The string representation of the PCBA part number, excluding the revision.
  #
  ######################################################################
  #
  def pcba_name
    "#{self.pcba_prefix}-#{self.pcba_number}-#{self.pcba_dash_number}"
  end
  
  
  ######################################################################
  #
  # full_display_name
  #
  # Description:
  # This method returns the PCB part number with the revision.  If the
  # part number is new then the PCBA part number is also returned
  #
  # Parameters:
  # None
  #
  # Return value:
  # The string representation of the PCBA part number, including the revision.
  #
  ######################################################################
  #
  def full_display_name
    name = self.pcb_display_name
    if self.new?
      name += ' / ' + self.pcba_display_name
    end
    name
  end
  
  
  ######################################################################
  #
  # pcba_display_name
  #
  # Description:
  # This method returns the PCBA part number with the revision.
  #
  # Parameters:
  # None
  #
  # Return value:
  # The string representation of the PCBA part number, including the revision.
  #
  ######################################################################
  #
  def pcba_display_name
    name  = self.pcba_name
    name += ' ' + self.pcba_revision if self.pcba_revision.size > 0
    name
  end
  
  
  ######################################################################
  #
  # name
  #
  # Description:
  # This method determines if the part number is unique based on the
  # prefix and number components of the part number.
  #
  # Parameters:
  # None
  #
  # Return value:
  # A string representing the PCB and PCBA components of the part number.
  #
  ######################################################################
  #
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
