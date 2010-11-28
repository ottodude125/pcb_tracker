class PartNum < ActiveRecord::Base

  belongs_to :board_design_entry
  belongs_to :design

  #validates_inclusion_of :use, :in => [:pcb, :pcba]

  ######################################################################
  #
  # part_num_exists?
  #
  # Description:
  # This method indicates the part number exists in the database
  #
  # Parameters:
  # none
  #
  # Return value:
  # TRUE if the part number exists, FALSE otherwise.
  #
  ######################################################################

  def part_num_exists?
    get_part_number(self)?true:false
  end

  ######################################################################
  #
  # get_designs
  #
  # Description:
  # Provides a list of designs given a unique PCB part number
  #
  # Parameters:
  # unique_part_number - a string of the part number prefix and number
  # type - string indication the type of part number. "pcb" or "pcba"
  #
  # Return value:
  # A list of designs related to the unique Part Number.
  #
  ######################################################################
  #
  def self.get_designs(unique_part_number,type)

    components = unique_part_number.split('-')
    part_numbers = PartNum.find(:all, :conditions =>
          "prefix='#{components[0]}' " +
          "AND number='#{components[1]}' " +
          "AND `use`='#{type}' "  )


    designs = part_numbers.collect { |pn| pn.design }.reverse.uniq
    designs.delete_if { |d| !d }
    designs

  end

  ######################################################################
  #
  # get_uniq_part_numbers
  #
  # Description:
  # Provides a list of unique part number of the specified type
  #
  # Parameters:
  # type - string indication the type of part number. "pcb" or "pcba"
  #
  # Return value:
  # list of unique_part_numbers and the design id - the part number prefix and number
  #
  ######################################################################
  #
  def self.get_unique_part_numbers(type)

    PartNum.find(:all,
      :conditions => "`use` = '#{type}' AND `design_id` IS NOT NULL ",
      :select => "DISTINCT CONCAT(prefix,'-',number) AS number",
      :order => 'number')

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

  def self.get_part_number(pn)
    conditions = "prefix='#{pn.prefix}'    AND " +
      "number='#{pn.number}'    AND " +
      "dash='#{pn.dash}' AND " +
      "revision='#{pn.revision}'"
    PartNum.find(:first, :conditions => conditions )
  end

def get_part_number(pn)
    conditions = "prefix='#{pn.prefix}'    AND " +
      "number='#{pn.number}'    AND " +
      "dash='#{pn.dash}' AND " +
      "revision='#{pn.revision}'"
    PartNum.find(:first, :conditions => conditions )
  end

  ######################################################################
  #
  # get_bde_pcba_part_numbers(board design entry id)
  #
  # Description:
  # This method looks up the pcba part numbers for a board_design_entry
  # given the board design entry id
  #
  # Parameters:
  # board design entry id
  #
  # Return values:
  #
  # A collection of pcba part number records if they exist
  #
  ######################################################################

  def self.get_bde_pcba_part_numbers(id)
    pcbas = PartNum.find(:all, :conditions => {
        :board_design_entry_id => id,
        :use => "pcba" })
    unless pcbas
      # look up in old database and load into new
      partnum = BoardDesignEntry.find(id).part_number
      pcba = PartNum.new(:board_design_entry_id => id,
        :prefix => partnum.pcba_prefix,
        :number => partnum.pcba_number,
        :dash => partnum.pcba_dash_number,
        :revision => partnum.pcba_revision).save
      pcbas = PartNum.find(:all, :conditions => {
          :design_id => id,
          :use => "pcba" })
    end
    pcbas
  end

  ######################################################################
  #
  # get_bde_pcb_part_number(board design entry id)
  #
  # Description:
  # This method looks up the pcb part number for a board_design_entry
  # given the board design entry id
  #
  # Parameters:
  # board design entry id
  #
  # Return values:
  # The part number record if it exists in
  # the database.  If the record is not found then nil is returned.
  #
  ######################################################################

  def self.get_bde_pcb_part_number(id)
    pcb = PartNum.find(:first, :conditions => {
        :board_design_entry_id => id,
        :use => "pcb" })
    unless pcb
      # look up in old database and load into new
      partnum = BoardDesignEntry.find(id).part_number
      pcb = PartNum.new(
        :board_design_entry_id => id,
        :prefix => partnum.pcb_prefix,
        :number => partnum.pcb_number,
        :dash => partnum.pcb_dash_number,
        :revision => partnum.pcb_revision).save
      pcb = PartNum.find(:first, :conditions => {
          :design_id => id,
          :use => "pcb" })
    end
    pcb
  end

  ######################################################################
  #
  # get_design_pcba_part_numbers(design id)
  #
  # Description:
  # This method looks up the pcba part numbers for a design
  # given the design id
  #
  # Parameters:
  # design id
  #
  # Return values:
  #
  # A collection of pcba part number records if they exist
  #
  ######################################################################

  def self.get_design_pcba_part_numbers(id)
    pcbas = PartNum.find(:all, :conditions => {
        :design_id => id,
        :use => "pcba" })
    unless pcbas.size > 0
      # look up in old database and load into new
      partnumber = Design.find(id).part_number
      pcba = PartNum.new(
        :design_id => id,
        :prefix    => partnumber.pcba_prefix,
        :number    => partnumber.pcba_number,
        :dash      => partnumber.pcba_dash_number,
        :revision  => partnumber.pcba_revision,
        :use       => "pcba").save
      pcbas = PartNum.find(:all, :conditions => {
          :design_id => id,
          :use => "pcba" })
    end
    pcbas
  end

  ######################################################################
  #
  # get_design_pcb_part_number(design id)
  #
  # Description:
  # This method looks up the pcb part number for a design
  # given the design id
  #
  # Parameters:
  # design id
  #
  # Return values:
  # The part number record if it exists in
  # the database.  If the record is not found then nil is returned.
  #
  ######################################################################

  def self.get_design_pcb_part_number(id)
    pcb = PartNum.find(:first, :conditions => {
        :design_id => id, :use => "pcb" } )
    unless pcb
      # look up in old database and load into new
      partnum = Design.find(id).part_number
      pcb = PartNum.new(
        :design_id => id,
        :prefix    => partnum.pcb_prefix,
        :number    => partnum.pcb_number,
        :dash      => partnum.pcb_dash_number,
        :revision  => partnum.pcb_revision,
        :use       => "pcb").save
      pcb = PartNum.find(:first, :conditions => {
          :design_id => id,
          :use => "pcb" })
    end
    pcb
  end

  ######################################################################
  #
  # part_number_name
  #
  # Description:
  # Return the name for a part number
  #
  # Parameters:
  # None
  #
  # Return values:
  # The assembled name for the part number
  #
  ######################################################################
  def name_string
    "#{self.prefix}-#{self.number}-#{self.dash}"
  end
  
  def part_number_name
    "#{self.prefix}-#{self.number}-#{self.dash}"
  end

  ######################################################################
  #
  # part_number_revision
  #
  # Description:
  # Return the revision for a part number
  #
  # Parameters:
  # None
  #
  # Return values:
  # The assembled name for the part number
  #
  ######################################################################
  def rev_string
    "#{self.revision}"
  end

  def part_number_revision
    "#{self.revision}"
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
    self.prefix =~ /^\d\d\d$/ &&
      self.number =~ /^\d\d\d$/ &&
      self.dash   =~ /^[A-Z,a-z,0-9][A-Z,a-z,0-9]$/
  end

  ######################################################################
  #
  # uniq_name
  #
  # Description:
  # This method returns the prefix and number of a pcb,
  # ignoring dash number and revision
  #
  # Parameters:
  # None
  #
  # Return value:
  # prefix-number
  #
  ######################################################################
  #
  def uniq_name
    self.prefix + '-' + self.number
  end

  ######################################################################
  #
  # get_active_pcbas
  #
  # Description:
  # This method returns a collection of active PCBA part number objects
  #
  # Parameters:
  # None
  #
  # Return value:
  # collection of part_nums
  #
  ######################################################################
  #
  def self.get_active_pcbas
    pcbas   = []
    PartNum.find(:all, :conditions => { :use => 'pcba' } ).each { |pnum|
     pcbas << pnum if pnum.design_id != nil &&
          Design.find(:first, :conditions => {:id => pnum.design_id}).is_active?
    }
    pcbas.sort_by { |p| p.name_string }
  end
end