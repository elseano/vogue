require 'test_helper'

# Load in the posts controller to ensure vogue has overridden things.
PostsController
class PantsControllerTest < ActionController::TestCase
  
  test "standard ActionView::MissingTemplate is raised" do
    
    assert_raise ActionView::MissingTemplate do
      get "no_view_method"
    end
    
  end
  
end
