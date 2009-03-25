require File.dirname(__FILE__) + '/../test_helper'

class BlobsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:blobs)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_blob
    assert_difference('Blob.count') do
      post :create, :blob => { }
    end

    assert_redirected_to blob_path(assigns(:blob))
  end

  def test_should_show_blob
    get :show, :id => blobs(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => blobs(:one).id
    assert_response :success
  end

  def test_should_update_blob
    put :update, :id => blobs(:one).id, :blob => { }
    assert_redirected_to blob_path(assigns(:blob))
  end

  def test_should_destroy_blob
    assert_difference('Blob.count', -1) do
      delete :destroy, :id => blobs(:one).id
    end

    assert_redirected_to blobs_path
  end
end
