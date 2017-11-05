require 'test_helper'

class LinebotControllerTest < ActionDispatch::IntegrationTest
  test "should get callback" do
    get linebot_callback_url
    assert_response :success
  end

  test "should get push" do
    get linebot_push_url
    assert_response :success
  end

end
