########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: board_design_entry.rb
#
# This file maintains the state for board design entries.
#
# $Id$
#
########################################################################

class BoardDesignEntry < ActiveRecord::Base

  belongs_to :design
  belongs_to :design_directory
  belongs_to :incoming_directory
  belongs_to :platform
  belongs_to :prefix
  belongs_to :product_type
  belongs_to :project
  belongs_to :revision
  
  has_many   :board_design_entry_users
  has_many   :part_nums
  
  belongs_to :part_number
  belongs_to :user
  
  NOT_SET = '<font color="red"><b>Not Set</b></font>'
  

  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


  def self.summary_data
    
    entries = self.find(:all, :conditions => 'design_id > 0')
    
    sorted_by_quarter = {}
    
    entries.each do |entry|
      quarter = 'Q' + entry.submitted_on.current_quarter.to_s
      year    = entry.submitted_on.strftime("%Y")
      key     = year + quarter
      sorted_by_quarter[key] = [] if !sorted_by_quarter[key]
      sorted_by_quarter[key] << entry
    end
    
    sorted_by_quarter

  end

  
  ######################################################################
  #
  # get_entries_for_processor
  #
  # Description:
  # This method retrieves a list of board design entry records for
  # the processor
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of board design entry records
  #
  ######################################################################
  #
  def self.get_entries_for_processor
  
    BoardDesignEntry.find(:all, :conditions => "state='originated'") +
    BoardDesignEntry.find(:all, :conditions => "state='submitted'")  +
    BoardDesignEntry.find(:all, :conditions => "state='ready_to_post'")
    
  end

  
  ######################################################################
  #
  # get_user_entries
  #
  # Description:
  # This method retrieves a list of board design entry records for
  # the user
  #
  # Parameters:
  # None
  #
  # Return value:
  # A list of board design entry records
  #
  ######################################################################
  #
  def self.get_user_entries(user)

    list = user.board_design_entries
    list.delete_if { |bde| !(bde.state == 'originated' || bde.state == 'submitted') }
    list
    
  end
  
  
  # Find all of the user's enties that are in originated state
  # 
  # :call-seq:
  #   BoardDesignEntry.get_pending_entries(user) -> array
  #
  # Returns a list of the user's entries that have been originated.
  def self.get_pending_entries(user)
    self.find(:all, :conditions => "state='originated' AND user_id=#{user.id}")
  end
  
  
  # Find all enties not submitted by the user that are not complete.
  # 
  # :call-seq:
  #   BoardDesignEntry.get_other_pending_entries(user) -> array
  #
  # Returns a list of incomplete entries that the user did not originate.
  def self.get_other_pending_entries(user)
    self.find(:all, :conditions => "state != 'complete'") - user.board_design_entries
  end
  
  
  ######################################################################
  #
  # submission_count
  #
  # Description:
  # This method retrieves a count of the number of boards that are in 
  # the 'submitted' state
  #
  # Parameters:
  # None
  #
  # Return value:
  # A number indicating the number of boards that have been submitted.
  #
  ######################################################################
  #
  def self.submission_count
    @submissions = BoardDesignEntry.find(:all, :conditions => "state='submitted'").size
    #@submissions = BoardDesignEntry.count(:conditions => "state='submitted'")
    
  end

  
  ######################################################################
  #
  # add_entry
  #
  # Description:
  # This method adds an entry to the board design entry table.
  #
  # Parameters:
  # user        - the user originating the entry
  #
  # Return value:
  # If an entry was created then the entry is returned, otherwise, nil
  # is returned.
  #
  ######################################################################
  #
  def self.add_entry(user)

    bde = BoardDesignEntry.new(:user_id                => user.id,
      :division_id            => user.division_id,
      :location_id            => user.location_id,
      :lead_free_device_names => '',
      :originator_comments    => '',
      :input_gate_comments    => '')

    bde.save
    bde.load_design_team

    bde

  end

  
  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################

  
  ######################################################################
  #
  # before_save
  #
  # Description:
  # This method performs processing prior to saving a board design 
  # entry.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
#  def get_entry(part_number)
#    BoardDesignEntry.find(:first,
#                          :conditions => "part_number='part_number.get_id'")
#  end

  
  ######################################################################
  #
  # before_save
  #
  # Description:
  # This method determines if the board design entry is new.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the entry is new, otherwise, FALSE.
  #
  ######################################################################
  #
  def new?
    #(self.part_number_id > 0 && self.part_number) ? self.part_number.new? : true
    self.pcb_number.blank? ? true : false
  end


  ######################################################################
  #
  # before_save
  #
  # Description:
  # This method performs processing prior to saving a board design 
  # entry.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def before_save
    self.design_directory_id = 0 if self.design_directory_id == ''
  end
  
  
  ######################################################################
  #
  # modifiable?
  #
  # Description:
  # This method a boolean value that indicates whether or not the entry
  # id modifiable.  If TRUE then the entry is modifiable.
  #
  ######################################################################
  #
  def modifiable?
    !(self.complete? || self.ready_to_post?)
  end


  ######################################################################
  #
  # design_name
  #
  # Description:
  # This method returns the design name if the part number 
  # has not been specified, otherwise the part number is
  # returned
  #
  ######################################################################
  #
  def design_name

    if 1 == 2  # self.part_number_id == 0
      design_name  = self.prefix.pcb_mnemonic + self.number
      design_name += self.revision.name  if self.revision && self.revision_id > 0
  
      case self.entry_type
      when 'dot_rev'
        design_name += self.numeric_revision.to_s if self.numeric_revision > 0
      when 'date_code'
        design_name += self.numeric_revision.to_s if self.numeric_revision && self.numeric_revision > 0
        design_name += '_eco'
        design_name += self.eco_number
      end
    
      "#{design_name} (" + 
      self.prefix.pcb_number(self.number,
                             self.revision.name,
                             self.numeric_revision) + ')'
    else
      self.pcb_number
    end
    
  end
  
  
  ######################################################################
  #
  # new_entry_type_name
  #
  # Description:
  # Defines the name of the "New" entry type.
  #
  # Return:
  # A string that contains the name of a "New" entry type.
  #
  ######################################################################
  #
  def new_entry_type_name
    'New'
  end
  
  
  ######################################################################
  #
  # dot_rev_entry_type_name
  #
  # Description:
  # Defines the name of the "Dot Rev" entry type.
  #
  # Return:
  # A string that contains the name of a "Dot Rev" entry type.
  #
  ######################################################################
  #
  def dot_rev_entry_type_name
    'Bare Board Change'
  end


  ######################################################################
  #
  # entry_type_name
  #
  # Description:
  # Provides the name of the entry type.
  #
  # Return:
  # A string that contains the name of the entry type.
  #
  ######################################################################
  #
  def entry_type_name
    if self.new_design?
      self.new_entry_type_name
    elsif self.dot_rev_design?
      self.dot_rev_entry_type_name
    else
      'Entry Type Not Set'
    end
  end


  ######################################################################
  #
  # entry_type_set?
  #
  # Description:
  # Indicates if the entry type of the board design entry is set.
  #
  # Return:
  # TRUE  if the entry type is set.
  # FALSE if not
  #
  ######################################################################
  #
  def entry_type_set?
    self.new_design? || self.dot_rev_design?
  end

  
  ######################################################################
  #
  # new_design?
  #
  # Description:
  # Indicates if the entry type of the board design entry is "New".
  #
  # Return:
  # TRUE  if the entry type is "New".
  # FALSE if not
  #
  ######################################################################
  #
  def new_design?
    self.entry_type == 'new'
  end

  
  ######################################################################
  #
  # dot_rev_design?
  #
  # Description:
  # Indicates if the entry type of the board design entry is "Dot Rev".
  #
  # Return:
  # TRUE  if the entry type is "Dot Rev".
  # FALSE if not
  #
  ######################################################################
  #
  def dot_rev_design?
    self.entry_type == 'dot_rev'
  end
  
  
  ######################################################################
  #
  # set_entry_type_new
  #
  # Description:
  # Sets the entry type for the board design entry to "New" and updates
  # the record in the detabase if the board design entry is stored 
  # in the database.
  #
  # Return:
  # None
  #
  ######################################################################
  #
  def set_entry_type_new
    self.entry_type = 'new'
    self.save if self.id
  end
  
  
  ######################################################################
  #
  # set_entry_type_dot_rev
  #
  # Description:
  # Sets the entry type for the board design entry to "Dot Rev" and
  # updates the record in the detabase if the board design entry is 
  # stored in the database.
  #
  # Return:
  # None
  #
  ######################################################################
  #
  def set_entry_type_dot_rev
    self.entry_type = 'dot_rev'
    self.save if self.id
  end
  
  
  ######################################################################
  #
  # location
  #
  # Description:
  # This method returns the submitter's location name.
  #
  ######################################################################
  #
  def location
    self.location_id > 0 ? Location.find(self.location_id).name : NOT_SET  
  end
  
  
  ######################################################################
  #
  # division
  #
  # Description:
  # This method returns the submitter's division name.
  #
  ######################################################################
  #
  def division
    self.division_id > 0 ? Division.find(self.division_id).name : NOT_SET  
  end
  
  
  ######################################################################
  #
  # platform_name
  #
  # Description:
  # This method returns the platform name.
  #
  ######################################################################
  #
  def platform_name
    self.platform ? self.platform.name : NOT_SET
  end
  
  
  ######################################################################
  #
  # project_name
  #
  # Description:
  # This method returns the project name.
  #
  ######################################################################
  #
  def project_name
    self.project ? self.project.name : NOT_SET
  end
  
  ######################################################################
  #
  # product_type_name
  #
  # Description:
  # This method returns the project type.
  #
  ######################################################################
  #
  def product_type_name
    self.product_type ? self.product_type.name : NOT_SET
  end
  
  ######################################################################
  #
  # description_name
  #
  # Description:
  # This method returns the project description.
  #
  ######################################################################
  #
  def description_name
    !self.description.blank? ? self.description : NOT_SET
  end

  ######################################################################
  #
  # bde_description
  #
  # Description:
  # This method returns the descrption in the bde table
  #
  ######################################################################
  #  
  def bde_description
    read_attribute(:description)
  end

  ######################################################################
  #
  # description
  #
  # Description:
  # This method returns the partnum description. It overides the description
  # column in the BDE table and instead gets the description from PartNum
  #
  ######################################################################
  #  
  def description
    PartNum.find_by_board_design_entry_id_and_use(self.id, "pcb").description || "(Description not set)"
    #rescue "(Part number not found)"  
  end
  
  ######################################################################
  #
  # design_directory_name
  #
  # Description:
  # This method returns the design directory name.
  #
  ######################################################################
  #
  def design_directory_name
    self.design_directory_id? ? self.design_directory.name : NOT_SET
  end


  ######################################################################
  #
  # incoming_directory_name
  #
  # Description:
  # This method returns the incoming directory name.
  #
  ######################################################################
  #
  def incoming_directory_name
    self.incoming_directory_id? ? self.incoming_directory.name : NOT_SET
  end
  
  
  ######################################################################
  #
  # pcb_number
  #
  # Description:
  # This method returns the pcb number.
  #
  ######################################################################
  #
  def pcb_number
    pnum=PartNum.get_bde_pcb_part_number(self.id)
    if pnum
	pnum.name_string
    else
        ""
    end
  end

  def pcb_number_OBS
    if self.number && self.revision && self.numeric_revision
      self.prefix.pcb_number(self.number, self.revision_name, self.numeric_revision)
    else
      NOT_SET
    end
  end

  def pcb_rev
    if PartNum.get_bde_pcb_part_number(self.id)
      PartNum.get_bde_pcb_part_number(self.id).rev_string
    else
      "??"
    end
  end

  def pcb_display
    PartNum.get_bde_pcb_part_number(self.id).name_string +
      ' ' +
      PartNum.get_bde_pcb_part_number(self.id).rev_string
  end
  
  ######################################################################
  #
  # pcba_part_number
  #
  # Description:
  # This method returns the pcba part number.
  #
  ######################################################################
  #
  def pcbas_string
    first = 1
    pcbas = ""
    PartNum.get_bde_pcba_part_numbers(self.id).each { |pcba|
      string = pcba.name_string + " " + pcba.description#read_attribute(:description)
      if first == 1
        pcbas << string  
        first = 0
      else
        pcbas << "<br>" + string
      end
    }
    pcbas
  end

  def pcba_part_number_OBS
    if self.number && self.revision && self.numeric_revision
      self.prefix.pcb_a_part_number(self.number, self.revision_name, '0')
    else
      NOT_SET
    end
  end

  def full_name
    self.pcb_display + ' / ' + self.pcbas_string
  end
  
  ######################################################################
  #
  # revision_name
  #
  # Description:
  # This method returns the revision name.
  #
  ######################################################################
  #
  def revision_name
  
    if revision
      revision = self.revision.name
     # revision += self.numeric_revision > 0 ? self.numeric_revision.to_s : ''
    else
      NOT_SET
    end
    
  end
  
  
  ######################################################################
  #
  # design
  #
  # Description:
  # This method returns the design name without the revision.
  #
  ######################################################################
  #
  ##def design
  ##  self.prefix.pcb_mnemonic + self.number
  ##end
  
  
  ######################################################################
  #
  # valid_number?
  #
  # Description:
  # This method determines if the board design entry number is valid.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the board design entry number is valid. Otherwise FALSE.
  #
  ######################################################################
  #
  def valid_number?
    /\d{3}/ =~ self.number ? true : false
  end
  
  
  ######################################################################
  #
  # originated
  #
  # Description:
  # This method sets the state of the design entry to 'originated'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def originated
    self.update_attribute('state', 'originated')
  end

  ######################################################################
  #
  # originated?
  #
  # Description:
  # This method determines if the board design entry is in the originated
  # state.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the board design entry state is 'originated'.  
  #
  ######################################################################
  #
  def originated?
    self.state == 'originated'
  end
  
  
  ######################################################################
  #
  # submitted
  #
  # Description:
  # This method sets the state of the design entry to 'submitted'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def submitted
    self.update_attributes(:state => 'submitted', :submitted_on => Time.now())
  end

  ######################################################################
  #
  # submitted?
  #
  # Description:
  # This method determines if the board design entry is in the submitted
  # state.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the board design entry state is 'submitted'.  
  #
  ######################################################################
  #
  def submitted?
    self.state == 'submitted'
  end
  
  
  ######################################################################
  #
  # complete?
  #
  # Description:
  # This method determines if the board design entry is in the complete
  # state.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the board design entry state is 'complete'.  
  #
  ######################################################################
  #
  def complete?
    self.state == 'complete'
  end

  ######################################################################
  #
  # complete
  #
  # Description:
  # This method sets the state of the design entry to 'complete'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None  
  #
  ######################################################################
  #
  def complete
    self.update_attribute('state', 'complete')
  end

  ######################################################################
  #
  # ready_to_post?
  #
  # Description:
  # This method determines if the board design entry is in the 
  # ready_to_post state.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if the board design entry state is 'ready_to_post'.  
  #
  ######################################################################
  #
  def ready_to_post?
    self.state == 'ready_to_post'
  end

  ######################################################################
  #
  # ready_to_post
  #
  # Description:
  # This method sets the state of the design entry to 'ready_to_post'.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None  
  #
  ######################################################################
  #
  def ready_to_post
    self.update_attribute('state', 'ready_to_post')
  end


  ######################################################################
  #
  # originator
  #
  # Description:
  # This method provides the name of the person who originated the entry.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None  
  #
  ######################################################################
  #
  def originator
    self.user ? self.user.name : NOT_SET
  end


  ######################################################################
  #
  # load_design_team
  #
  # Description:
  # This method determines if the board is already in the system.  If it is
  # then any information that can be gathered from the existing design is 
  # pulled in to initialize this board design entry.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def load_design_team
            
    default_reviewers = []
    defaulted_roles = Role.get_defaulted_manager_reviewer_roles + 
                      Role.get_defaulted_reviewer_roles
    defaulted_roles.each do |role|
      default_reviewers << BoardDesignEntryUser.new( :role_id => role.id, 
                                                     :user_id => role.default_reviewer_id )
    end
    self.board_design_entry_users << default_reviewers
    
    self.board_design_entry_users(true)
  
  end
  
  
  ######################################################################
  #
  # managers
  #
  # Description:
  # This method provides a list of board design entry users who are 
  # managers.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def managers
  
    managers = self.board_design_entry_users.dup
    managers.delete_if { |bde_user| !bde_user.role.manager? }
    return managers.sort_by { |m| m.role.display_name }
  
  end


  ######################################################################
  #
  # reviewers
  #
  # Description:
  # This method provides a list of board design entry users who are 
  # reviewers.
  #
  # Parameters:
  # None
  #
  # Return value:
  # None
  #
  ######################################################################
  #
  def reviewers
  
    reviewers = self.board_design_entry_users.dup
    reviewers.delete_if { |bde_user| !bde_user.role.reviewer? || bde_user.role.manager? }
    return reviewers.sort_by { |m| m.role.display_name }
  
  end

  ######################################################################
  # reviewer_roles
  #
  # Description
  # This method returns an array of hashes for each reviewer role.
  #
  #######################################################################

  def reviewer_roles

    members = []
    Role.get_open_reviewer_roles.each do |role|
      entry_user = self.board_design_entry_users.detect{ |eu| eu.role_id == role.id }
      members << {  :role         => role,
        :member_list  => role.active_users,
        :member_id    => entry_user ? entry_user.user_id : 0,
        :required     => !entry_user || (entry_user && entry_user.required?) }
    end
    members
  end
  ######################################################################
  # manager_roles
  #
  # Description
  # This method returns an array of hashes for each manager role.
  #
  #######################################################################

  def manager_roles

    members = []
    Role.get_open_manager_reviewer_roles.each do |role|
      entry_user = self.board_design_entry_users.detect{ |eu| eu.role_id == role.id }
      members << {  :role         => role,
        :member_list  => role.active_users,
        :member_id    => entry_user ? entry_user.user_id : 0,
        :required     => !entry_user || (entry_user && entry_user.required?) }
    end
    members
  end


  ######################################################################
  #
  # all_roles_assigned?
  #
  # Description:
  # This method determines if all of the roles have been assigned
  #
  # Parameters:
  # roles = a list of roles
  #
  # Return value:
  # TRUE if all of the roles have a user assigned, otherwise FALSE.
  #
  ######################################################################
  #
  def all_roles_assigned?(roles)
    
    all_roles_assigned = false
    self.board_design_entry_users.reload
    
    roles.each do | role|
      all_roles_assigned = self.board_design_entry_users.detect { |user| 
      user.role_id == role.id 
      }
      break if !all_roles_assigned
    end

    all_roles_assigned != nil
    
  end
  
  
  ######################################################################
  #
  # all_reviewers_assigned?
  #
  # Description:
  # This method determines if all of the reviewer roles have been 
  # assigned
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if all of the reviewer roles have a user assigned, 
  # otherwise FALSE.
  #
  ######################################################################
  #
  def all_reviewers_assigned?
    self.all_roles_assigned?(Role.get_open_reviewer_roles)
  end
  
  
  ######################################################################
  #
  # all_manager_reviewers_assigned?
  #
  # Description:
  # This method determines if all of the manager roles have been 
  # assigned
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if all of the manager roles have a user assigned, 
  # otherwise FALSE.
  #
  ######################################################################
  #
  def all_manager_reviewers_assigned?
    self.all_roles_assigned?(Role.get_open_manager_reviewer_roles)
  end
  
  ######################################################################
  #
  # design_data_filled_in?
  #
  # Description:
  # This method determines if the required information on the board design
  # entry form has been provided
  #
  # Paramters:
  # None
  #
  # Return value:
  # TRUE is all the fields are set
  # otherwise FALSE
  #
  ######################################################################
  #
  def design_data_filled_in?
    !self.description.blank? && 
    !self.platform.blank? && 
    !self.product_type.blank? && 
    !self.project.blank? &&
    !self.design_directory.blank? &&
    !self.incoming_directory.blank? &&
    !self.requested_start_date.blank? &&
    !self.requested_completion_date.blank?
  end
  
  ######################################################################
  #
  # ready_for_submission?
  #
  # Description:
  # This method determines if the entry has all of the information 
  # required for a board design entry submission.
  #
  # Parameters:
  # None
  #
  # Return value:
  # TRUE if all the entry has all of the information required for submission, 
  # otherwise FALSE.
  #
  ######################################################################
  #
  def ready_for_submission?
    self.all_reviewers_assigned? && 
    self.all_manager_reviewers_assigned? &&
    self.design_data_filled_in?
  end

  
end
