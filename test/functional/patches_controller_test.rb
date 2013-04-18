require 'test_helper'

class PatchesControllerTest < ActionController::TestCase
  test "should get show" do
    get :show
    assert_response :success
  end

  test "should get merge" do
    get :merge
    assert_response :success
  end

end
