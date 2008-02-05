require File.dirname(__FILE__) + '/../test_helper'

class LogBundlesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:log_bundles)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_log_bundle
    assert_difference('LogBundle.count') do
      post :create, :log_bundle => { }
    end

    assert_redirected_to log_bundle_path(assigns(:log_bundle))
  end

  def test_should_show_log_bundle
    get :show, :id => log_bundles(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => log_bundles(:one).id
    assert_response :success
  end

  def test_should_update_log_bundle
    put :update, :id => log_bundles(:one).id, :log_bundle => { }
    assert_redirected_to log_bundle_path(assigns(:log_bundle))
  end

  def test_should_destroy_log_bundle
    assert_difference('LogBundle.count', -1) do
      delete :destroy, :id => log_bundles(:one).id
    end

    assert_redirected_to log_bundles_path
  end
end
