require 'test_helper'

class FabIssuesControllerTest < ActionController::TestCase
  setup do
    @fab_issue = fab_issues(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:fab_issues)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create fab_issue" do
    assert_difference('FabIssue.count') do
      post :create, fab_issue: {  }
    end

    assert_redirected_to fab_issue_path(assigns(:fab_issue))
  end

  test "should show fab_issue" do
    get :show, id: @fab_issue
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @fab_issue
    assert_response :success
  end

  test "should update fab_issue" do
    put :update, id: @fab_issue, fab_issue: {  }
    assert_redirected_to fab_issue_path(assigns(:fab_issue))
  end

  test "should destroy fab_issue" do
    assert_difference('FabIssue.count', -1) do
      delete :destroy, id: @fab_issue
    end

    assert_redirected_to fab_issues_path
  end
end
