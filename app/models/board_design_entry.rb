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
  
  NOT_SET = '<font color="red"><b>Not Set</b></font>'


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
  # This method returns the design name.
  #
  ######################################################################
  #
  def design_name

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
    
    return design_name
    
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
  # TRUE if the board design entry state is 'complete'.  
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
            
    #To Do: Come up with a better way to specify default users.          
    default_assignments = { 'PCB Design' => 'Light' } 

    Role.find_all_by_active_and_manager(1, 1).each do |role|    
      board_design_entry_user = BoardDesignEntryUser.new(
                                  :board_design_entry_id => self.id,
                                  :role_id               => role.id)
                                  
      if default_assignments[role.name]
        board_design_entry_user.user_id = User.find_by_last_name(default_assignments[role.name]).id
      end
      board_design_entry_user.save if board_design_entry_user.user_id?
    end

    #To Do: Come up with a better way to specify default users.          
    default_assignments = { 'Compliance - EMC'    => 'Bechard',
                            'Compliance - Safety' => 'Pallotta',
                            'Library'             => 'Ohara',
                            'PCB Input Gate'      => 'Kasting',
                            'PCB Mechanical'      => 'Khoras',
                            'SLM BOM'             => 'Seip',
                            'SLM-Vendor'          => 'Gough' }

    Role.find_all_by_active_and_reviewer_and_manager(1, 1, 0).each do |role|     
      board_design_entry_user = BoardDesignEntryUser.new(
                                  :board_design_entry_id => self.id,
                                  :role_id               => role.id)
      if default_assignments[role.name]
        begin
          board_design_entry_user.user_id = 
            User.find_by_last_name(default_assignments[role.name]).id
        rescue
          board_design_entry_user.user_id = 0   
        end
      end
      board_design_entry_user.save if board_design_entry_user.user_id?
    end
    
    self.board_design_entry_users(true)
  
    existing_board = Board.find_by_prefix_id_and_number(self.prefix_id, self.number)

    if existing_board

      existing_board.board_reviewers.each do |board_reviewer|
      
        bde_user = self.board_design_entry_users.detect { |bdeu| 
          bdeu.role_id == board_reviewer.role_id
        }
        
        if bde_user
          bde_user.user_id = board_reviewer.reviewer_id
          bde_user.save
        end 
            
      end
      
    end
  end


end
