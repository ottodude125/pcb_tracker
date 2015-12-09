class PartNum < ActiveRecord::Base

  belongs_to :board_design_entry
  belongs_to :design

  #validates_inclusion_of :use, :in => [:pcb, :pcba]

  validates :description, :length => { :maximum => 80 }

  scope :pnum_use, ->(type) { where("`use` = ?", "#{type}") }
  scope :pnum_like, ->(unique_part_number) { where("`pnum` LIKE ?", "%#{unique_part_number}%") }

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
    self.get_part_number ? true : false
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
    part_numbers = PartNum.pnum_use(type).pnum_like(unique_part_number)
    designs = part_numbers.collect { |pn| pn.design }.reverse.uniq
    designs.delete_if { |d| !d }
    designs
  end
  #def self.get_designs_OBS(unique_part_number,type)
  #  components = unique_part_number.split('-')
  #  part_numbers = PartNum.find(:all, :conditions =>
  #        "prefix='#{components[0]}' " +
  #        "AND number='#{components[1]}' " +
  #        "AND `use`='#{type}' "  )
  #  designs = part_numbers.collect { |pn| pn.design }.reverse.uniq
  #  designs.delete_if { |d| !d }
  #  designs
  #end


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
    # SELECT DISTINCT LEFT(pnum, 8) FROM pcbtr3_development.part_nums;
    PartNum.find(:all,
      :conditions => "`use` = '#{type}' AND `design_id` IS NOT NULL ",
      :select => "DISTINCT LEFT(pnum, 7) AS number",
      :order => 'number')  
  end
  #def self.get_unique_part_numbers_OBS(type)
  #  PartNum.find(:all,
  #    :conditions => "`use` = '#{type}' AND `design_id` IS NOT NULL ",
  #    :select => "DISTINCT CONCAT(prefix,'-',number) AS number",
  #    :order => 'number')
  #end


  ######################################################################
  #
  # get_part_number
  #
  # Description:
  # This method looks up the part number in the database given the
  # components of the part number (pnum, number, and revision)
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
    conditions = "pnum='#{pn.pnum}'    AND " +
      "revision='#{pn.revision}'"
    PartNum.find(:first, :conditions => conditions )
  end
  #def self.get_part_number_OBS(pn)
  #  conditions = "prefix='#{pn.prefix}'    AND " +
  #    "number='#{pn.number}'    AND " +
  #    "dash='#{pn.dash}' AND " +
  #    "revision='#{pn.revision}'"
  #  PartNum.find(:first, :conditions => conditions )
  #end

  def get_part_number
    conditions = "pnum='#{self.pnum}'    AND " +
      "revision='#{self.revision}'"
    PartNum.find(:first, :conditions => conditions )
  end
  #def get_part_number_OBS
  #  conditions = "prefix='#{self.prefix}'    AND " +
  #    "number='#{self.number}'    AND " +
  #    "dash='#{self.dash}' AND " +
  #    "revision='#{self.revision}'"
  #  PartNum.find(:first, :conditions => conditions )
  #end

  ###################
  # The various get_xxx_part_number functions test for a nil id
  # in case the function is called that way. This only happens in
  # tests. If it didn't check, the functions return entries from the
  # database that have NULL set for board_design_entry_id or for design_id
  # ##################
  
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
    if id
      pcbas = PartNum.find(:all, :conditions => {
        :board_design_entry_id => id,
        :use => "pcba" })
    else
      pcbas = []
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
    if id
      pcb = PartNum.find(:first, :conditions => {
        :board_design_entry_id => id,
        :use => "pcb" })
    else
      pcb = nil
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
    if id
      pcbas = PartNum.find(:all, :conditions => {
        :design_id => id,
        :use => "pcba" })
    else
      pcbas = []
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
    if id
      pcb = PartNum.find(:first, :conditions => {
        :design_id => id, :use => "pcb" } )
    else
      pcb = ""
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
    "#{self.pnum}"
  end
  #def name_string_OBS
  #  "#{self.prefix}-#{self.number}-#{self.dash}"
  #end
  
  def part_number_name
    "#{self.pnum}"
  end
  #def part_number_name_OBS
  #  "#{self.prefix}-#{self.number}-#{self.dash}"
  #end

  ######################################################################
  #
  # part_number_name_with_description
  #
  # Description:
  # Return the name for a part number with description
  #
  # Parameters:
  # None
  #
  # Return values:
  # The assembled name for the part number
  #
  ######################################################################
  def name_string_with_description
    "#{self.pnum} #{self.description}"
  end
  #def name_string_with_description_OBS
  #  "#{self.prefix}-#{self.number}-#{self.dash} #{self.description}"
  #end
  
  def part_number_name_with_description
    "#{self.pnum} #{self.description}"
  end
  #def part_number_name_with_description_OBS
  #  "#{self.prefix}-#{self.number}-#{self.dash} #{self.description}"
  #end

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
  # Did a search and this method does not show up anywhere else in the code
  def valid_pcb_part_number?_OBS
    self.prefix =~ /^\d\d\d$/ &&
      self.number =~ /^\d\d\d$/ &&
      self.dash   =~ /^[A-Z,a-z,0-9][A-Z,a-z,0-9]$/
  end

  ######################################################################
  #
  # valid_part_number?
  #
  # Description:
  # This method indicates that the part number is valid.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the part number is valid, FALSE otherwise.
  #
  ######################################################################
  #
  # Did a search and this method does not show up anywhere else in the code
  def valid_part_number?
    self.pnum =~ /^[a-zA-Z0-9\-]*$/
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
  # If Agile keep first 7 chars
  # If std keep everything preceeding second dash
  #
  ######################################################################
  #
  def uniq_name
    self.pnum.match(/(^[a-zA-Z0-9]{1,3}-[a-zA-Z0-9]{3}|^[a-zA-Z0-9]{7})/)
  end
  #def uniq_name_OBS
  #  self.prefix + '-' + self.number
  #end

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
     if ! pnum.design_id.blank?
       design = Design.find(:first, :conditions => {:id => pnum.design_id})
       if ! design.blank?
          pcbas << pnum if design.is_active?
       end
     end
    }
    pcbas.sort_by { |p| p.name_string }
  end

  ######################################################################
  #
  # get_all_pnums
  #
  # Description:
  # This method returns an array of part numbers from pnum column
  #
  # Parameters:
  # None
  #
  # Return value:
  # array of part_nums
  #
  ######################################################################
  #
  def self.get_all_pnums
    pnums = PartNum.pluck(:pnum)
  end

  ######################################################################
  #
  # get_all_pnums_for_design(design_id)
  #
  # Description:
  # This method returns an array of part numbers from pnum column for a given design_id
  #
  # Parameters:
  # design_id
  #
  # Return value:
  # array of part_nums
  #
  ######################################################################
  #
  def self.get_all_pnums_for_design(design_id)
    brd_pnums = PartNum.where(:design_id => design_id).pluck(:pnum)
  end

  ######################################################################
  #
  # get_all_pnums_for_bde(design_id)
  #
  # Description:
  # This method returns an array of part numbers from pnum column for a
  # given board_design_entry_id
  #
  # Parameters:
  # board_design_entry_id
  #
  # Return value:
  # array of part_nums
  #
  ######################################################################
  #
  def self.get_all_pnums_for_bde(board_design_entry_id)
    brd_pnums = PartNum.where(:board_design_entry_id => board_design_entry_id).pluck(:pnum)
  end


end
