require File.expand_path( "../../test_helper", __FILE__ ) 

class DesignReviewDocumentsTest < ActiveSupport::TestCase

  def setup
    @design_review_document = DesignReviewDocument.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of DesignReviewDocument,  @design_review_document
  end
end
