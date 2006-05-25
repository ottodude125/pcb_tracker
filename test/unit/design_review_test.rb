require File.dirname(__FILE__) + '/../test_helper'

class DesignReviewTest < Test::Unit::TestCase

  fixtures(:design_reviews,
           :design_review_comments,
           :review_types,
           :roles)

  def setup
    @mx234a_pre_art_review = DesignReview.find(
                               design_reviews(:mx234a_pre_artwork).id)
    @mx234a_routing_review = DesignReview.find(
                               design_reviews(:mx234a_routing).id)
  end


  def test_review_name
    assert_equal('Pre-Artwork', @mx234a_pre_art_review.review_name)
    assert_equal('Routing',     @mx234a_routing_review.review_name)
  end
  
  
  def test_comments
  
    comment_list = @mx234a_routing_review.comments
    assert_equal([], comment_list)
    
    comment_list = @mx234a_pre_art_review.comments
    assert_equal(4, comment_list.size)
    expected_id = 4
    for comment in comment_list
      assert_equal(expected_id, comment.id)
      expected_id -= 1
    end
    
  end
  
  
  def test_review_results_by_role_name
  
    review_results   = @mx234a_pre_art_review.review_results_by_role_name
    expected_results = @mx234a_pre_art_review.design_review_results
    expected_results = expected_results.sort_by { |er| er.role.name }
    
    assert_equal(expected_results, review_results)
    assert_equal(14,               review_results.size)
  end
end
