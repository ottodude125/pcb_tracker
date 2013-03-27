class UserMailer < ActionMailer::Base
  default :from => Pcbtr::SENDER

 ######################################################################
  #
  # tracker_invite
  #
  # Description:
  # This method generates the mail to a reviewer to let them know they
  # have been added to the tracker
  #
  # Parameters:
  #   user     - the reviewer's user object
  #
  ######################################################################
  #
  def tracker_invite(user)


    to_list    = user.email
    cc_list    = []
    subject    = "Your login information for the PCB Design Tracker"

    @reviewer  = user

    mail( :to      => to_list,
          :subject => subject,
          :cc      => cc_list
        )

  end

  ######################################################################
  #
  # user_password
  #
  # Description:
  # This method generates the mail to send the password to the user.
  #
  # Parameters:
  #   user    - The user record containing the email address and password.
  #
  ######################################################################
  #
  def user_password(user)

    @user  = user
    mail(:to      => user.email,
         :subject => "Your PCB Design Tracker login id and password",
         :cc      => [],
         :bcc     => []   #override default
         )

  end


end
