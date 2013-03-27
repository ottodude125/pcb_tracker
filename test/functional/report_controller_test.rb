require File.expand_path( "../../test_helper", __FILE__ )
require 'report_controller'

# Re-raise errors caught by the controller.
class ReportController; def rescue_action(e) raise e end; end

class ReportControllerTest < ActionController::TestCase
  def setup
    @controller = ReportController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end


  fixtures(:design_reviews,
           :review_statuses,
           :users)


  def test_reviewer_workload_report
  
    post(:reviewer_workload)
    
  end
end
