require 'test_helper'

class FabQuarterlyStatusesControllerTest < ActionController::TestCase
  setup do
    @fab_quarterly_status = fab_quarterly_statuses(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:fab_quarterly_statuses)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create fab_quarterly_status" do
    assert_difference('FabQuarterlyStatus.count') do
      post :create, fab_quarterly_status: { image_name: @fab_quarterly_status.image_name, quarter: @fab_quarterly_status.quarter, status_note: @fab_quarterly_status.status_note, year: @fab_quarterly_status.year }
    end

    assert_redirected_to fab_quarterly_status_path(assigns(:fab_quarterly_status))
  end

  test "should show fab_quarterly_status" do
    get :show, id: @fab_quarterly_status
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @fab_quarterly_status
    assert_response :success
  end

  test "should update fab_quarterly_status" do
    put :update, id: @fab_quarterly_status, fab_quarterly_status: { image_name: @fab_quarterly_status.image_name, quarter: @fab_quarterly_status.quarter, status_note: @fab_quarterly_status.status_note, year: @fab_quarterly_status.year }
    assert_redirected_to fab_quarterly_status_path(assigns(:fab_quarterly_status))
  end

  test "should destroy fab_quarterly_status" do
    assert_difference('FabQuarterlyStatus.count', -1) do
      delete :destroy, id: @fab_quarterly_status
    end

    assert_redirected_to fab_quarterly_statuses_path
  end
end
