require 'test_helper'

class ConfigControllerTest < ActionDispatch::IntegrationTest
  test "should get events" do
    get config_events_url
    assert_response :success
  end

end
