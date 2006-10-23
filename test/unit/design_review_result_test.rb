require File.dirname(__FILE__) + '/../test_helper'

class DesignReviewResultTest < Test::Unit::TestCase
  fixtures :design_review_results

  def setup
    @design_review_result = DesignReviewResult.find(1)
  end

  ###################################################################
  def test_complete
    
    results = { 'APPROVED' => true,
                'WAIVED'   => true,
                'COMMENT'  => false, 
                'REJECTED' => true }
                
    drr = DesignReviewResult.new
    results.each do |result, expected_return|
      drr.result = result
      assert_equal(expected_return, drr.complete?)
    end
    
  end
end
