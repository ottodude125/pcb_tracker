require File.expand_path( "../../test_helper", __FILE__ )

class LoginHelpTest < ActionDispatch::IntegrationTest

  #user clicks "login help" on index page
  #  fills in last name
  #submits
  #  gets back their user information
  #click on Send password
  #  gets e-mail with username and password

  fixtures :users

  #user = users(:jim_l)

  user = User.find_by_login("jim_l")

  test "1_connect" do
    #connect to application
    get "/"
    assert_response :success
    assert_template "index"
  end

  test "2_show_users" do
    get "/user/show_users"
    assert_response :success
    assert_template "show_users"
  end

  test "3_get_information" do
    post "/user/login_information",
         :user  => { :last_name => user.last_name}
    assert_response :success
    assert_template "login_information"
    # check return values? or is that in functional?
  end

  test "4_send_password" do
    post_via_redirect "/user/send_password/#{user.id}"
    assert_response :success
    assert_template :login_information
    mail = ActionMailer::Base.deliveries.last
    assert_equal  [user.email], mail.to   
    assert_equal  "Your PCB Design Tracker login id and password", mail.subject
  end
end
