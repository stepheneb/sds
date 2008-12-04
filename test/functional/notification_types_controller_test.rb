require File.dirname(__FILE__) + '/../test_helper'

class NotificationTypesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:notification_types)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_notification_type
    assert_difference('NotificationType.count') do
      post :create, :notification_type => { }
    end

    assert_redirected_to notification_type_path(assigns(:notification_type))
  end

  def test_should_show_notification_type
    get :show, :id => notification_types(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => notification_types(:one).id
    assert_response :success
  end

  def test_should_update_notification_type
    put :update, :id => notification_types(:one).id, :notification_type => { }
    assert_redirected_to notification_type_path(assigns(:notification_type))
  end

  def test_should_destroy_notification_type
    assert_difference('NotificationType.count', -1) do
      delete :destroy, :id => notification_types(:one).id
    end

    assert_redirected_to notification_types_path
  end
end
