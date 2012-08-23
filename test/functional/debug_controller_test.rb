require File.expand_path( "../../test_helper", __FILE__ )
require 'debug_controller'

# Re-raise errors caught by the controller.
class DebugController; def rescue_action(e) raise e end; end

class DebugControllerTest < ActionController::TestCase
  def setup
    @controller = DebugController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
