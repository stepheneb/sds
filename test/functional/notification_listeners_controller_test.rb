require File.dirname(__FILE__) + '/../test_helper'

class NotificationListenersControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:notification_listeners)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_notification_listener
    assert_difference('NotificationListener.count') do
      post :create, :notification_listener => { }
    end

    assert_redirected_to notification_listener_path(assigns(:notification_listener))
  end

  def test_should_show_notification_listener
    get :show, :id => notification_listeners(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => notification_listeners(:one).id
    assert_response :success
  end

  def test_should_update_notification_listener
    put :update, :id => notification_listeners(:one).id, :notification_listener => { }
    assert_redirected_to notification_listener_path(assigns(:notification_listener))
  end

  def test_should_destroy_notification_listener
    assert_difference('NotificationListener.count', -1) do
      delete :destroy, :id => notification_listeners(:one).id
    end

    assert_redirected_to notification_listeners_path
  end
end
