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
  
  belongs_to :part_number
  
  NOT_SET = '<font color="red"><b>Not Set</b></font>'
  

  def new?
    self.part_number ? self.part_number.new? : true  
  end
  
  
  def self.get_user_entries(user)
    conditions = "state='originated' OR state='submitted'"
    BoardDesignEntry.find(:all,
                          :conditions => conditions)
  end
  
  
  def get_entry(part_number)
    BoardDesignEntry.find(:first,
                          :conditions => "part_number='part_number.get_id'")
  end

  
  def self.submission_count
    @submissions = BoardDesignEntry.find(:all, :conditions => "state='submitted'").size
    #@submissions = BoardDesignEntry.count(:conditions => "state='submitted'")
    
  end
  
  
  def self.add_entry(part_number, user)
    if part_number.exists?
      bde = BoardDesignEntry.find(:first,
                                  :conditions => "part_number_id='#{part_number.get_id}'")
    end

    # Verify that the entry does not exist before 
    # creating a new part number
    if !bde
      bde = BoardDesignEntry.new(:originator_id => user.id,
                                 :entry_type    => part_number.new? ? 'new' : 'dot_rev',
                                 :division_id   => user.division_id,
                                 :location_id   => user.location_id)
      if !part_number.exists?
        part_number.create
      else
        part_number.get_id
      end
      
      bde.part_number_id = part_number.id
      bde.create
      bde.load_design_team
      bde

    else
      nil
    end
    
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

    if self.part_number_id == 0
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
      self.part_number.name
    end
    
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
    if self.number && self.revision && self.numeric_revision
      self.prefix.pcb_number(self.number, self.revision_name, self.numeric_revision)
    else
      NOT_SET
    end
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
  def pcba_part_number
    if self.number && self.revision && self.numeric_revision
      self.prefix.pcb_a_part_number(self.number, self.revision_name, '0')
    else
      NOT_SET
    end
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
  def design
  
    self.prefix.pcb_mnemonic + self.number
    
  end
  
  
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
    self.update_attributes(:state        => 'submitted',
                           :submitted_on => Time.now())
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
    self.originator_id? ? User.find(self.originator_id).name : NOT_SET
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
  
  
  def all_reviewers_assigned?
    self.all_roles_assigned?(Role.get_open_reviewer_roles)
  end
  
  
  def all_manager_reviewers_assigned?
    self.all_roles_assigned?(Role.get_open_manager_reviewer_roles)
  end
  
  
  def ready_for_submission?
    self.all_reviewers_assigned? && self.all_manager_reviewers_assigned?
  end


end
