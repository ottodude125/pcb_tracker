ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class Test::Unit::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...


  def set_admin
    user = User.find(users(:cathy_m).id)
    @request.session[:user]        = user
    @request.session[:active_role] = Role.find_by_name('Admin')
    @request.session[:roles]       = user.roles
  end


  def set_non_admin
    user = User.find(users(:rich_m).id)
    @request.session[:user]        = user
    @request.session[:active_role] = Role.find_by_name('Designer')
    @request.session[:roles]       = user.roles
  end

  
  def set_designer
    user = User.find(users(:rich_m).id)
    @request.session[:user]        = user
    @request.session[:active_role] = Role.find_by_name('Designer')
    @request.session[:roles]       = user.roles
  end


  def set_manager
    user = User.find(users(:jim_l).id)
    @request.session[:user]        = user
    @request.session[:active_role] = Role.find_by_name('Manager')
    @request.session[:roles]       = user.roles
  end


  def set_reviewer
    user = User.find(users(:pat_a).id)
    @request.session[:user]        = user
    @request.session[:active_role] = Role.find_by_name('DFM')
    @request.session[:roles]       = user.roles
  end


  def set_user(user_id, role)
    user = User.find(user_id)
    @request.session[:user]        = user
    @request.session[:active_role] = Role.find_by_name(role)
    @request.session[:roles]       = user.roles
  end



end
