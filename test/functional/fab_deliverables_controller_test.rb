require 'test_helper'

class FabDeliverablesControllerTest < ActionController::TestCase
  setup do
    @fab_deliverable = fab_deliverables(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:fab_deliverables)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create fab_deliverable" do
    assert_difference('FabDeliverable.count') do
      post :create, fab_deliverable: {  }
    end

    assert_redirected_to fab_deliverable_path(assigns(:fab_deliverable))
  end

  test "should show fab_deliverable" do
    get :show, id: @fab_deliverable
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @fab_deliverable
    assert_response :success
  end

  test "should update fab_deliverable" do
    put :update, id: @fab_deliverable, fab_deliverable: {  }
    assert_redirected_to fab_deliverable_path(assigns(:fab_deliverable))
  end

  test "should destroy fab_deliverable" do
    assert_difference('FabDeliverable.count', -1) do
      delete :destroy, id: @fab_deliverable
    end

    assert_redirected_to fab_deliverables_path
  end
end
