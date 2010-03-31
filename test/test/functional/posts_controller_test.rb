require 'test_helper'

class PostsControllerTest < ActionController::TestCase

  test "renders ok for new" do
    get "new"
    assert_response :ok
  end
  
  test "vogue helper returns correct option" do
    get "new"
    assert @response.body.include?("Wunderbah"), "Wunderbah was not included in the response. vogue helper possibly broken."
  end
  
  test "vogue helper does not render data from another controller" do
    get "new"
    assert !@response.body.include?("Uberkid"), "Uberkid was not expected in the response. vogue helper possibly broken."
  end
  
  test "template overriding ok" do
    get "new"
    assert_response :ok
    assert_template :partial => "posts/_specific"
    assert_template :partial => "_header"
    assert_template :partial => "_sub_header"
  end
end
