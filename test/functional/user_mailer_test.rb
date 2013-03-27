require File.expand_path( "../../test_helper", __FILE__ )

class UserMailerTest < ActionMailer::TestCase

## I can't get the body tests to work with better regex. This needs work.

  test "tracker_invite" do
    user = users(:jim_l)
    mail = UserMailer.tracker_invite(user)
    assert_equal "Your login information for the PCB Design Tracker", mail.subject
    assert_equal [user.email], mail.to
    assert_equal Pcbtr::SENDER, mail[:from].value
    assert_match( /Greetings,/ , mail.body.encoded )
  end
  ##############################################################################


  test "user_password" do
    user = users(:jim_l)
    mail = UserMailer.user_password(user)
    assert_equal "Your PCB Design Tracker login id and password", mail.subject
    assert_equal [ user.email ], mail.to
    assert_equal Pcbtr::SENDER, mail[:from].value
    assert_match( /jim_l/, mail.body.encoded )
  end

end
