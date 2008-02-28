require File.dirname(__FILE__) + '/../test_helper'

class BundleContentsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:bundle_contents)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_bundle_content
    assert_difference('BundleContent.count') do
      post :create, :bundle_content => { }
    end

    assert_redirected_to bundle_content_path(assigns(:bundle_content))
  end

  def test_should_show_bundle_content
    get :show, :id => bundle_contents(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => bundle_contents(:one).id
    assert_response :success
  end

  def test_should_update_bundle_content
    put :update, :id => bundle_contents(:one).id, :bundle_content => { }
    assert_redirected_to bundle_content_path(assigns(:bundle_content))
  end

  def test_should_destroy_bundle_content
    assert_difference('BundleContent.count', -1) do
      delete :destroy, :id => bundle_contents(:one).id
    end

    assert_redirected_to bundle_contents_path
  end
end
