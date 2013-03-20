class SystemMessage < ActiveRecord::Base
  
  validates_presence_of :message_type, :title, :body, :valid_from, :valid_until
  
  belongs_to :user
  
  ##############################################################################
  #
  # Constants
  # 
  ##############################################################################

  MESSAGE_TYPE = [ ['New Features'      , 1],
           ['Maintenance Notice', 2] ] 

  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


  ######################################################################
  #
  # type_list
  #
  # Description:
  # This method returns the type list.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def self.type_list
    MESSAGE_TYPE
  end
  
  
  ######################################################################
  #
  # type_id
  #
  # Description:
  # This method returns the id associated with the type name.
  #
  # Parameters:
  # name - The type name
  #
  ######################################################################
  #
  def self.type_id(name)
    MESSAGE_TYPE.detect { |c| c[0] == name }[1]
  rescue
    0
  end
  
  
  ######################################################################
  #
  # type_name
  #
  # Description:
  # This method returns the name associated with the type id.
  #
  # Parameters:
  # id - The type identifier
  #
  ######################################################################
  #
  def self.type_name(id)
    MESSAGE_TYPE[id-1][0]
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
  # type_name
  #
  # Description:
  # This method returns the type name for the system_message.
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def type_name
    MESSAGE_TYPE[self.type_id-1][0]
  end
  
  ######################################################################
  #
  # valid_messages
  #
  # Description:
  # This method returns the messages that are within the valid date range
  #
  # Parameters:
  # datetime - optional
  #
  ######################################################################
  #
  def self.valid_messages(valid_date=Time.now)
      messages = self.order("updated_at ASC").where("valid_from <= :valid_date AND 
                                                     valid_until >= :valid_date", 
                                                     :valid_date => valid_date)
  end
  
  ######################################################################
  #
  # users_valid_messages
  #
  # Description:
  # This method returns the messages that are within the valid date range
  # that the current logged in user has not seen; i.e. messages which
  # are valid and whose "updated_at date" occurs after the users
  # "message_seen" date"
  #
  # Parameters:
  # datetime - optional
  #
  ######################################################################
  #
  def self.users_valid_messages(valid_date=Time.now, user_message_seen)
    messages = []
    if user_message_seen.message_seen != nil
      messages = self.order("updated_at ASC").where("valid_from <= :valid_date AND
                                                     valid_until >= :valid_date AND
                                                     updated_at >= :user_seen",
                                                     :valid_date => valid_date,
                                                     :user_seen => user_message_seen.message_seen)
    else
      messages = self.valid_messages(valid_date)
    end
    messages
  end

  ######################################################################
  #
  # changelog_messages
  #
  # Description:
  # This method returns the messages whose type is New Feature
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def self.changelog_messages
      messages = self.order("updated_at DESC").where(:message_type => "New Features")
  end
  
  ######################################################################
  #
  # maintenance_messages
  #
  # Description:
  # This method returns the messages whose type is Maintenance Notice
  #
  # Parameters:
  # None
  #
  ######################################################################
  #
  def self.maintenance_messages
      messages = self.order("updated_at ASC").where(:message_type => "Maintenance Notice")
  end


end
