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
  end

  fixtures(:designs,
           :ipd_posts,
           :users)

  def test_1_id
    print ("\n*** In Process Dialog Post Controller Test\n")
    print ("*** $Id$\n")
  end



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

    ipd_posts = IpdPost.find_all
    assert_equal(29, ipd_posts.size)


    # The la454c design has no idp posts in the database.  Verify
    # that list provides the expected information.
    post(:list,
         :design_id => designs(:la454c3).id)

    assert_equal(designs(:la454c3).name,
                 assigns(:design).name)
    assert_equal(0,  assigns(:ipd_post_pages).item_count)
    assert_equal(0, assigns(:ipd_posts).size)

    # The mx234a design has 3 idp posts in the database.  Verify
    # that list provides the expected information.
    post(:list,
         :design_id => designs(:mx234a).id)

    assert_equal(designs(:mx234a).name,
                 assigns(:design).name)
    assert_equal(3, assigns(:ipd_post_pages).item_count)
    assert_equal(3, assigns(:ipd_posts).size)

    # The la453b design has 23 ipd posts in the database.  Verify
    # that list provides the expected information.
    post(:list,
         :design_id => designs(:la453b).id)

    assert_equal(designs(:la453b).name,
                 assigns(:design).name)
    assert_equal(23, assigns(:ipd_post_pages).item_count)
    assert_equal(20, assigns(:ipd_posts).size)

    post(:list,
         :design_id => designs(:la453b).id,
         :page      => 2)

    assert_equal(designs(:la453b).name,
                 assigns(:design).name)
    assert_equal(23, assigns(:ipd_post_pages).item_count)
    assert_equal(3,  assigns(:ipd_posts).size)

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
    
    post(:new, 
         :design_id => designs(:la453b).id)
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
    
    post(:show, 
         :id => ipd_posts(:mx234a_thread_one).id)
    assert_equal(designs(:mx234a).id, assigns(:reply_post).design_id)

    root_post = assigns(:root_post)
    assert_equal(designs(:mx234a).id, root_post.design_id)
    assert_equal(3, root_post.all_children.size)

    mx234a_thr_one = ipd_posts(:mx234a_thread_one)
    assert_equal(mx234a_thr_one, root_post)

    children_sorted = root_post.all_children.sort_by { |post|
      post.id
    }

    assert_equal(ipd_posts(:mx234a_thread_one_a), children_sorted[0])
    assert_equal(ipd_posts(:mx234a_thread_one_b), children_sorted[1])
    assert_equal(ipd_posts(:mx234a_thread_one_c), children_sorted[2])
    
  end


  def test_posting

    # The mx243c design has no idp posts in the database.  Verify
    # that list provides the expected information.
    post(:list,
         :design_id => designs(:mx234c).id)
    assert_equal(designs(:mx234c).name,
                 assigns(:design).name)
    assert_equal(0, assigns(:ipd_post_pages).item_count)
    assert_equal(0, assigns(:ipd_posts).size)

    set_user(users(:scott_g).id, 'Designer')
    root_post = {:design_id => designs(:mx234c).id,
                 :subject   => "mx234c thread 1",
                 :body      => "mx234c thread 1 BODY"}
    post(:create,
         :ipd_post => root_post)
    
    post(:list,
         :design_id => designs(:mx234c).id)
    assert_equal(1, assigns(:ipd_post_pages).item_count)
    assert_equal(1, assigns(:ipd_posts).size)


    root_post = {:design_id => designs(:mx234c).id,
                 :subject   => "mx234c thread 2",
                 :body      => "mx234c thread 2 BODY"}
    post(:create,
         :ipd_post => root_post)
         
    root_post = {:design_id => designs(:mx234c).id,
                 :subject   => "mx234c thread 3",
                 :body      => "mx234c thread 3 BODY"}
    post(:create,
         :ipd_post => root_post)

    post(:list,
         :design_id => designs(:mx234c).id)
    assert_equal(3, assigns(:ipd_post_pages).item_count)
    assert_equal(3, assigns(:ipd_posts).size)
    for post in assigns(:ipd_posts)
      assert_equal(0, post.all_children.size)
    end

    thread_3 = assigns(:ipd_posts).detect{ |p| 
                 p.subject == "mx234c thread 3"}

    post(:create_reply,
         :reply_post => {:body => 'mx234c thread 3 REPLY 1'},
         :id         => thread_3.id)

    post(:list,
         :design_id => designs(:mx234c).id)
    assert_equal(3, assigns(:ipd_post_pages).item_count)
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
         :reply_post => {:body => 'mx234c thread 3 REPLY 2'},
         :id         => thread_3.id)

    post(:list,
         :design_id => designs(:mx234c).id)
    assert_equal(3, assigns(:ipd_post_pages).item_count)
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
         :reply_post => {:body => 'mx234c thread 3 REPLY 3'},
         :id         => thread_3.id)

    post(:list,
         :design_id => designs(:mx234c).id)
    assert_equal(3, assigns(:ipd_post_pages).item_count)
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
         :reply_post => {:body => 'mx234c thread 1 REPLY 1'},
         :id         => thread_1.id)

    post(:list,
         :design_id => designs(:mx234c).id)
    assert_equal(3, assigns(:ipd_post_pages).item_count)
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


end
