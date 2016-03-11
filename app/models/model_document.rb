class ModelDocument < ActiveRecord::Base
  # attr_accessible :title, :body

  belongs_to :model_task
  belongs_to :user 

  MAX_FILE_SIZE = 47185920  # 45 MB

  
  # Accessor that recieves the data from the form in the view.
  # 
  # :call-seq:
  #   document= -> EcoDocument
  #
  # Retrieves the document identified by the user from the selection box.
  def document=(document_field)
    self.name         = base_part_of(document_field.original_filename)
    self.content_type = document_field.content_type.chomp
    self.data         = document_field.read
  end

  # Strip of the path and remove all the non alphanumeric, underscores and 
  # periods in the filename.
  # 
  # :call-seq:
  #   base_part_of(file_name) -> String
  #
  # Returns a the file path.
  def base_part_of(file_name)
    name = File.basename(file_name)
    name.gsub(/[^\w._-]/, '')
  end
  
  
  # Perform validations prior to saving.
  # 
  # :call-seq:
  #   save_attachment -> String
  #
  # Validates the file and updates the errors.
  def save_attachment
    if self.data.size == 0

      errors.add(:empty_document,     "The file contains no data - the document was not saved")
    elsif self.data.size >= ModelDocument::MAX_FILE_SIZE

      errors.add(:document_too_large, "The file is too large (LIMIT: #{ModelDocument::MAX_FILE_SIZE})" +
                                      " - the document was not saved")
    else

      self.unpacked = 0
      self.save
    end
  end
  
end
