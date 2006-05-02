class PasswordMailer < ActionMailer::Base


  def send_password(user)
    
    @subject    = "Your password"
    @body       = {:password => user.passwd}
    @recipients = [user.email]
    @from       = Pcbtr::SENDER
    @sent_on    = Time.now
    @headers    = {}
    @cc         = []

  end
  
  
end
