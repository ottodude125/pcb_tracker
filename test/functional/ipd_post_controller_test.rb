########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: ipd_post_controller_test.rb
#
# This file contains the functional tests for the ipd post controller
#
# $Id$
#
########################################################################
#

require File.dirname(__FILE__) + '/../test_helper'
require 'ipd_post_controller'

# Re-raise errors caught by the controller.
class IpdPostController; def rescue_action(e) raise e end; end

class IpdPostControllerTest < Test::Unit::TestCase
  def setup
    
    @controller = IpdPostController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
        
    #@siva_e  = users(:siva_e)
    @scott_g = users(:scott_g)
    
    
  end

  fixtures(:designs,
           :design_review_results,
           :design_reviews,
           :ipd_posts,
           :ipd_posts_users,
           :users)

  ######################################################################
  #
  # test_list
  #
  # Description:
  # This method does the functional testing of the list method
  # from the IPD Post class
  #
  ######################################################################
  #
  def test_list

    assert_equal(29, IpdPost.count)
    
    designer_session = scott_designer_session
    # The la454c design has no idp posts in the database.  Verify
    # that list provides the expected information.
    post(:list, { :design_id => designs(:la454c3).id }, designer_session)

    assert_equal(designs(:la454c3).name, assigns(:design).name)
    assert_equal(0,                      assigns(:ipd_posts).size)

    # The mx234a design has 3 idp posts in the database.  Verify
    # that list provides the expected information.
    get(:list, { :design_id => designs(:mx234a).id }, designer_session)

    assert_equal(designs(:mx234a).name,  assigns(:design).name)
    assert_equal(3,                      assigns(:ipd_posts).size)

    # The la453b design has 23 ipd posts in the database.  Verify
    # that list provides the expected information.
    get(:list, { :design_id => designs(:la453b).id }, designer_session)

    assert_equal(designs(:la453b).name, assigns(:design).name)
    assert_equal(23,                    assigns(:ipd_posts).size)

  end


  ######################################################################
  #
  # test_new
  #
  # Description:
  # This method does the functional testing of the new method
  # from the IPD Post class
  #
  ######################################################################
  #
  def test_new
  
    get(:new, { :design_id => designs(:la453b).id }, scott_designer_session)
    assert_equal(designs(:la453b).id, assigns(:ipd_post).design_id)
    
  end


  ######################################################################
  #
  # test_show
  #
  # Description:
  # This method does the functional testing of the show method
  # from the IPD Post class
  #
  ######################################################################
  #
  def test_show
    
    get(:show, { :id => ipd_posts(:mx234a_thread_one).id }, {})
    assert_equal(designs(:mx234a).id, assigns(:reply_post).design_id)

    root_post = assigns(:root_post)
    assert_equal(designs(:mx234a).id, root_post.design_id)
    assert_equal(3,                   root_post.all_children.size)

    mx234a_thr_one = ipd_posts(:mx234a_thread_one)
    assert_equal(mx234a_thr_one, root_post)

    children_sorted = root_post.all_children.sort_by { |post| post.id }

    assert_equal(ipd_posts(:mx234a_thread_one_a), children_sorted[0])
    assert_equal(ipd_posts(:mx234a_thread_one_b), children_sorted[1])
    assert_equal(ipd_posts(:mx234a_thread_one_c), children_sorted[2])
    
  end


  ######################################################################
  #
  # test_posting
  #
  # Description:
  # This method does the functional testing of the posting method
  # from the IPD Post class
  #
  ######################################################################
  #
  def test_posting

    designer_session = scott_designer_session
    
    # The mx243c design has no ipd posts in the database.  Verify
    # that list provides the expected information.
    get(:list,  { :design_id => designs(:mx234c).id }, designer_session)
    assert_equal(designs(:mx234c).name,  assigns(:design).name)
    assert_equal(0,                      assigns(:ipd_posts).size)

    root_post = {:design_id => designs(:mx234c).id,
                 :subject   => "mx234c thread 1",
                 :body      => "mx234c thread 1 BODY"}
    post(:create, { :ipd_post => root_post }, designer_session)
    
    get(:list, { :design_id => designs(:mx234c).id }, designer_session)
    assert_equal(1, assigns(:ipd_posts).size)


    root_post = {:design_id => designs(:mx234c).id,
                 :subject   => "mx234c thread 2",
                 :body      => "mx234c thread 2 BODY"}
    post(:create, { :ipd_post => root_post }, designer_session)
         
    root_post = {:design_id => designs(:mx234c).id,
                 :subject   => "mx234c thread 3",
                 :body      => "mx234c thread 3 BODY"}
    post(:create, { :ipd_post => root_post }, designer_session)

    get(:list, { :design_id => designs(:mx234c).id }, designer_session)
    assert_equal(3, assigns(:ipd_posts).size)
    assigns(:ipd_posts).each { |post| assert_equal(0, post.all_children.size) }

    thread_3 = assigns(:ipd_posts).detect{ |p| 
                 p.subject == "mx234c thread 3"}

    post(:create_reply,
         { :reply_post => {:body => 'mx234c thread 3 REPLY 1'},
           :id         => thread_3.id }, 
         designer_session)

    get(:list, { :design_id => designs(:mx234c).id }, designer_session)
    assert_equal(3, assigns(:ipd_posts).size)

    expected_results = {
      'mx234c thread 1' => {:size   => 0,
                            :bodies => []},
      'mx234c thread 2' => {:size   => 0,
                            :bodies => []},
      'mx234c thread 3' => {:size   => 1,
                            :bodies => ['mx234c thread 3 REPLY 1']}
    }

    for post in assigns(:ipd_posts)
      expected = expected_results[post.subject]
      assert_equal(expected[:size], post.all_children.size)
      i = 0
      for reply_post in post.all_children
        assert_equal(expected[:bodies][i], reply_post.body)
        i += 1
      end
    end

    post(:create_reply,
         { :reply_post => {:body => 'mx234c thread 3 REPLY 2'},
           :id         => thread_3.id },
         designer_session)

    get(:list, { :design_id => designs(:mx234c).id }, designer_session)
    assert_equal(3, assigns(:ipd_posts).size)

    expected_results['mx234c thread 3'][:size] = 2
    expected_results['mx234c thread 3'][:bodies].push('mx234c thread 3 REPLY 2')

    for post in assigns(:ipd_posts)
      expected = expected_results[post.subject]
      assert_equal(expected[:size], post.all_children.size)
      i = 0
      for reply_post in post.all_children
        assert_equal(expected[:bodies][i], reply_post.body)
        i += 1
      end
    end

    post(:create_reply,
         { :reply_post => {:body => 'mx234c thread 3 REPLY 3'},
           :id         => thread_3.id },
         designer_session)

    get(:list, { :design_id => designs(:mx234c).id }, designer_session)
    assert_equal(3, assigns(:ipd_posts).size)

    expected_results['mx234c thread 3'][:size] = 3
    expected_results['mx234c thread 3'][:bodies].push('mx234c thread 3 REPLY 3')

    for post in assigns(:ipd_posts)
      expected = expected_results[post.subject]
      assert_equal(expected[:size], post.all_children.size)
      i = 0
      for reply_post in post.all_children
        assert_equal(expected[:bodies][i], reply_post.body)
        i += 1
      end
    end

    thread_1 = assigns(:ipd_posts).detect{ |p| 
                 p.subject == "mx234c thread 1"}

    post(:create_reply,
         { :reply_post => {:body => 'mx234c thread 1 REPLY 1'},
           :id         => thread_1.id },
         designer_session)

    get(:list, { :design_id => designs(:mx234c).id }, designer_session)
    assert_equal(3, assigns(:ipd_posts).size)

    expected_results['mx234c thread 1'][:size] = 1
    expected_results['mx234c thread 1'][:bodies].push('mx234c thread 1 REPLY 1')

    for post in assigns(:ipd_posts)
      expected = expected_results[post.subject]
      assert_equal(expected[:size], post.all_children.size)
      i = 0
      for reply_post in post.all_children
        assert_equal(expected[:bodies][i], reply_post.body)
        i += 1
      end
    end
    
  end
  
  
  ######################################################################
  #
  # test_email_list
  #
  # Description:
  # This method does the functional testing of the email list manipulation
  # methods from the IPD Post class
  #
  ######################################################################
  #
  def test_email_list
   
    designer_session = scott_designer_session
    
    mx234a_thread_one = ipd_posts(:mx234a_thread_one)
    get(:manage_email_list, { :id => mx234a_thread_one.id }, designer_session)
         
    assert_equal(true,              assigns(:posting_new_thread))
    assert_equal(mx234a_thread_one, assigns(:ipd_post))
    
    expected_associated_users = {
     'PCB Mechanical'               => users(:john_g),
     'PCB Input Gate'               => users(:cathy_m),
     'DFM'                          => users(:heng_k),
     :peer                          => users(:scott_g),
     :pcb_input                     => users(:cathy_m),
     'SLM-Vendor'                   => users(:dan_g),
     'Operations Manager'           => users(:eileen_c),
     :designer                      => users(:bob_g),
     :pcb_input                     => users(:cathy_m),
     'PCB Design'                   => users(:jim_l),
     'HWENG'                        => users(:lee_s),
     'Planning'                     => users(:matt_d),
     'CE-DFT'                       => users(:espo),
     'Valor'                        => users(:lisa_a),
     'Mechanical'                   => users(:tom_f),
     'SLM BOM'                      => users(:art_d),
     'Mechanical-MFG'               => users(:anthony_g),
     'Library'                      => users(:dave_m),
     'TDE'                          => users(:rich_a),
     'Hardware Engineering Manager' => User.new(:first_name => 'Not', :last_name => 'Set'),
     'Program Manager'              => User.new(:first_name => 'Not', :last_name => 'Set')
    }
    associated_users = assigns(:associated_users)
    assert_equal(expected_associated_users.size, associated_users.size)
    expected_associated_users.each { |key, value|
      assert_equal(expected_associated_users[key].name, associated_users[key].name)
    }
    
    manager_list = assigns(:manager_list)
    assert_equal([users(:jim_l)], manager_list)
    
    input_gate_list = assigns(:input_gate_list)
    input_gate_list = input_gate_list.sort_by { |ig| ig.last_name }
    expected_input_gates = [
      users(:jan_k),
      users(:cathy_m)
    ]
    assert_equal(expected_input_gates , input_gate_list)
    
    expected_cc_list = []
    assert_equal(expected_cc_list, assigns(:optional_cc_list))

    available_to_cc = assigns(:available_to_cc)
    
    available_to_cc = available_to_cc.sort_by { |u| u.last_name }
    #expected_available_cc_list = User.find_all('active=1', 'last_name ASC')
    expected_available_cc_list = User.find(:all,
                                           :conditions => 'active=1',
                                           :order      => 'last_name ASC')
    
    # Remove the people who are already on the mail list.
    remove_users = [
      users(:scott_g),
      users(:jan_k),
      users(:lee_s),
      users(:jim_l),
      users(:cathy_m)
    ]
    for remove_user in remove_users
      expected_available_cc_list.delete_if { |user| user == remove_user }
    end

    assert_equal(expected_available_cc_list, available_to_cc)
    
    
    for user_to_add in available_to_cc
    
      expected_available_cc_list.delete_if { |u| u == user_to_add }
      expected_cc_list << user_to_add
      
      get(:add_to_thread_list, { :id => user_to_add.id }, designer_session)
      
      assert_equal(expected_cc_list, assigns(:optional_cc_list))
      assert_equal(expected_available_cc_list,
                   assigns(:available_to_cc))
      
    end
    
    users_to_remove = expected_cc_list.dup
    for user_to_remove in users_to_remove
   
      expected_cc_list.delete_if { |u| u == user_to_remove }
      expected_available_cc_list << user_to_remove
        
      get(:remove_from_thread_list, { :id => user_to_remove.id }, designer_session)
        
      assert_equal(expected_cc_list, assigns(:optional_cc_list))
      assert_equal(expected_available_cc_list,
                   assigns(:available_to_cc))
     
    end
    
    mx234a_thread_one.reload
    assert_equal([], mx234a_thread_one.users)

    users_to_add = [
      users(:alex_b),
      users(:anthony_g),
      users(:b_davie)
    ].sort_by { |u| u.last_name }
    for user_to_add in users_to_add
      post(:add_to_thread_list, { :id => user_to_add.id }, designer_session)
    end

    mx234a_thread_one.reload
    stored_users = mx234a_thread_one.users.sort_by { |u| u.last_name }
    assert_equal(users_to_add, stored_users)
       
  end


end
