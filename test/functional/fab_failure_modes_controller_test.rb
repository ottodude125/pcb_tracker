require 'test_helper'

class FabFailureModesControllerTest < ActionController::TestCase
  setup do
    @fab_failure_mode = fab_failure_modes(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:fab_failure_modes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create fab_failure_mode" do
    assert_difference('FabFailureMode.count') do
      post :create, fab_failure_mode: {  }
    end

    assert_redirected_to fab_failure_mode_path(assigns(:fab_failure_mode))
  end

  test "should show fab_failure_mode" do
    get :show, id: @fab_failure_mode
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @fab_failure_mode
    assert_response :success
  end

  test "should update fab_failure_mode" do
    put :update, id: @fab_failure_mode, fab_failure_mode: {  }
    assert_redirected_to fab_failure_mode_path(assigns(:fab_failure_mode))
  end

  test "should destroy fab_failure_mode" do
    assert_difference('FabFailureMode.count', -1) do
      delete :destroy, id: @fab_failure_mode
    end

    assert_redirected_to fab_failure_modes_path
  end
end
