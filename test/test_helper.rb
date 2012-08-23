ENV["RAILS_ENV"] = "test"
require File.expand_path("../../config/environment",__FILE__)
require 'rails/test_help'
#include CoreExtensions

#class Test::Unit::TestCase
class ActiveSupport::TestCase

  fixtures :all

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
  
  def set_session(user_id, role_name)
    user             = User.find(user_id)
    role             = Role.find_by_name(role_name)
    user.active_role = role
    
    { :user_id     => user_id }
  end
  

  def bob_designer_session
   set_session(users(:bob_g).id, 'Designer')
  end

  def cathy_admin_session
    set_session(users(:cathy_m).id, 'Admin')
  end
   
  def cathy_designer_session
    set_session(users(:cathy_m).id, 'Designer')
  end
  
  def cathy_input_gate_session
    set_session(users(:cathy_m).id, 'PCB Input Gate')
  end
  
  def dan_slm_vendor_session
    set_session(users(:dan_g).id, 'SLM-Vendor')
  end
  
  def jim_manager_session
    set_session(users(:jim_l).id, 'Manager')
  end
  
  def jim_pcb_design_session
    set_session(users(:jim_l).id, 'PCB Design')
  end

  def john_hweng_session
    set_session(users(:john_j).id, 'HWENG')
  end
  
  def lee_hweng_session
    set_session(users(:lee_s).id, 'HWENG')
  end
  
  def matt_planning_session
    set_session(users(:matt_d).id, 'Planning')
  end

  def pat_dfm_session
    set_session(users(:pat_a).id, 'DFM')
  end
  
  def patrice_pcb_admin_session
    set_session(users(:patrice_m).id, 'PCB Admin')
  end

  def rich_designer_session
    set_session(users(:rich_m).id, 'Designer')
  end
  
  def rich_reviewer_session
    set_session(users(:rich_a).id, 'hweng')
  end
  
  def scott_designer_session
    set_session(users(:scott_g).id, 'Designer')
  end
  
  def siva_designer_session
    set_session(users(:siva_e).id, 'Designer')
  end
  
  def ted_dft_session
    set_session(users(:ted_p).id, 'CE-DFT')
  end  
  
  
  def validate_non_admin_redirect
    assert_response :redirect
    assert_redirected_to(:controller => 'tracker')
    assert_equal('Administrators only!  Check your role.', flash['notice'])
  end


end
