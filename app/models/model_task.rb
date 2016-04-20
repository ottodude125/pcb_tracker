class ModelTask < ActiveRecord::Base
  # attr_accessible :title, :body

  has_many(:model_comments, :order => 'created_at DESC')
  has_many :model_documents

  has_and_belongs_to_many :model_types
  
  belongs_to :user

  # If the user updated task state then generate new comment
  before_save :check_for_state_change

  validates :request_number, uniqueness: true        
  validate :do_validate
  
  def do_validate
    if request_number.blank?
      errors.add(:request_number, 'The Request Number field can not be blank')
    end
    if model_types.size == 0
      errors.add(:model_types, "You must select at least one Model Type.")
    end
  end

  ##############################################################################
  #
  # Class Methods
  # 
  ##############################################################################


  # Retreive a list of all open Model Tasks
  #
  # :call-seq:
  #   find_active() ->  []
  #
  # Returns a list of open Model tasks.
  #
  def self.find_open
    self.find( :all, :conditions => ['closed=?', false], :order => 'created_at')
  end
  
  
  # Retreive a list of all closed Model Tasks
  #
  # :call-seq:
  #   find_closed() ->  []
  #
  # Returns a list of closed Model tasks.
  #
  def self.find_closed(start_date, end_date, order='created_at')
    self.find( :all,
               :conditions => ["closed=? AND created_at BETWEEN ? AND ?",
                               true, start_date, end_date+1.day], 
               :order => "#{order}")
  end

  
  # Provide a summary of the closed Model Tasks within the specified range.
  #
  # :call-seq:
  #   model_task_summary() ->  {}}
  #
  # Returns a hash with the summary totals.
  #
  def self.model_task_summary(start_date, end_date)
    summary = { :cae      => 0,
                :cad      => 0 }
              
    self.find_closed(start_date, end_date).each do |task|
      summary[:cae]    += 1 if task.cae?
      summary[:cad]    += 1 if task.cad? 
    end
    
    summary
  end
  
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################

  # Set the user instance variable
  #
  # :call-seq:
  #   set_user() ->  string
  #
  # Loads the value in the user record into the user instance variable.
  #
  def set_user(user)
    @user = user
  end
  

  # Get the value in the user instance variable
  #
  # :call-seq:
  #   get_user() ->  string
  #
  # Retrieves the value stored in the user instance variable.
  #
  def get_user
    @user
  end
  
  
  # Determine the state of the model task
  #
  # :call-seq:
  #   state() ->  string
  #
  # Returns a string indicating the state of the Model Task.
  #
  def state
    if !self.completed?
      'Incomplete'
    elsif self.completed? && !self.closed?
      'Complete'
    else
      'Closed'
    end
  end  
  
  # Determine if the model task is for a CAE
  #
  # :call-seq:
  #   cae?() ->  boolean
  #
  # Returns a boolean value that is true when a CAE
  # model type is attached to the model task.
  #
  def cae?
    self.model_types.detect { |mt| mt.name == "CAE" } != nil
  end

  # Determine if the model task is for a CAD
  #
  # :call-seq:
  #   cad?() ->  boolean
  #
  # Returns a boolean value that is true when a CAD
  # model type is attached to the model task.
  #
  def cad?
    self.model_types.detect { |mt| mt.name == "CAD" } != nil
  end

  
  # Determine if there are any documents attached
  #
  # :call-seq:
  #   attachments?() ->  boolean
  #
  # Returns a boolean value that is true when the task has at least on 
  # document attached.
  #
  def attachments?
    self.attachments.size > 0
  end
  
  
  # Retrieve a list of documents related to the task 
  #
  # :call-seq:
  #   attachments() -> []
  #
  # Returns a list of Model Task Documents.
  #
  def attachments
    model_documents = self.model_documents.reverse
  end
  
  
  # Insert a comment for the task.
  #
  # :call-seq:
  #   add_comment() -> model_task_comment
  #
  # Creates a Model Task comment if the comment is not blank.
  #
  def add_comment(model_task_comment, user)
    if !model_task_comment.comment.blank?
      model_task_comment.user_id = user.id
      self.model_comments << model_task_comment
    end
    model_task_comment
  end
  
  
  # Attach a document to the Model Task
  #
  # :call-seq:
  #   attach_document() -> model_document
  #
  # Updates the Model Task's document list.
  #
  def attach_document(model_document, 
                      user)
    model_document.user_id       = user.id
    model_document.model_task_id   = self.id
    model_document.save_attachment

    model_document
  end  


  # Determine if any admin updates have been make to the task.
  #
  # :call-seq:
  #   check_for_admin_update() -> boolean
  #
  # A flag that indicates if an admin update was made to the task.
  #
  def check_for_admin_update(updated_task)
    (self.request_number   != updated_task.request_number   ||
     self.description      != updated_task.description      ||
     self.mfg              != updated_task.mfg              ||
     self.mfg_num          != updated_task.mfg_num          ||
     self.cae_model        != updated_task.cae_model        ||
     self.cad_model        != updated_task.cad_model        ||
     self.completed        != updated_task.completed        ||
     self.closed           != updated_task.closed           ||
     self.model_types      != updated_task.model_types.reverse)
  end
  
  
  # Determine if any processor updates have been make to the task.
  #
  # :call-seq:
  #   check_for_processor_update() -> boolean
  #
  # A flag that indicates if a processor update was made to the task.
  #
  def check_for_processor_update(updated_task)
    (self.completed != updated_task.completed ||
     self.cae_model != updated_task.cae_model ||
     self.cad_model != updated_task.cad_model)
  end

    
private

  #
  # before_save call back method
  # 
  # If the task state has changed create new comment
  #
  def check_for_state_change

    stored_task = ModelTask.find(self.id) if self.id

    if stored_task 
      if !stored_task.completed? && self.completed?
        self.completed_at = Time.now
        state_change      = 'Task Completed'
      elsif !stored_task.closed? && self.closed?
        self.closed_at = Time.now
        state_change   = 'Task Closed'
      elsif stored_task.closed? && !self.closed?
        state_change = 'Task Reopened'
      elsif stored_task.completed? && !self.completed?
        state_change = 'Task Incomplete - Needs more work/input'
      end

      if state_change
        self.model_comments << ModelComment.new( :user_id => self.get_user.id, 
                                                  :comment => 'STATUS CHANGE: ' + state_change)
      end
    end
    
  end

  
end
