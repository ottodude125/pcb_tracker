require 'digest/sha1'

# this model expects a certain database layout and its based on the name/login pattern. 
class User < ActiveRecord::Base

  belongs_to :design_center

  has_and_belongs_to_many :boards
  has_and_belongs_to_many :roles


  # Please change the salt to something else, 
  # Every application should use a different one 
  @@salt = 'GO_PIRATES!!!'
  cattr_accessor :salt

  # Authenticate a user. 
  #
  # Example:
  #   @user = User.authenticate('bob', 'bobpass')
  #
  def self.authenticate(login, pass)
    #logger.info "********** AUTHENTICATE ************"
    #logger.info "    Login:            #{login}"
    #logger.info "    Password:         #{pass}"
    #logger.info "    Password(salted): #{sha1(pass)}"
    find_first(["login = ? AND password = ?", login, sha1(pass)])
  end  
  

  def name 
    read_attribute('first_name') + ' ' + read_attribute('last_name')
  end


  protected

  # Apply SHA1 encryption to the supplied password. 
  # We will additionally surround the password with a salt 
  # for additional security. 
  def self.sha1(pass)
    Digest::SHA1.hexdigest("#{salt}--#{pass}--")
  end
    
  before_create :crypt_password
  
  # Before saving the record to database we will crypt the password 
  # using SHA1. 
  # We never store the actual password in the DB.
  def crypt_password
    write_attribute "password", self.class.sha1(password)
  end
  
  before_update :crypt_unless_empty
  
  # If the record is updated we will check if the password is empty.
  # If its empty we assume that the user didn't want to change his
  # password and just reset it to the old value.
  def crypt_unless_empty
    if password.empty?      
      user = self.class.find(self.id)
      self.password = user.password
    else
      write_attribute "password", self.class.sha1(password)
    end        
  end  
  
  validates_uniqueness_of :login, :on => :create

  validates_confirmation_of :password
  validates_length_of :login, :within => 3..40
  validates_length_of :password, :within => 5..40
  validates_presence_of :login, :password, :password_confirmation
end
