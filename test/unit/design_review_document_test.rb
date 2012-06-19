require File.dirname(__FILE__) + '/../test_helper'

class DesignReviewDocumentTest < Test::Unit::TestCase
  fixtures :design_review_documents

  def setup
    @design_review_document = DesignReviewDocument.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of DesignReviewDocument,  @design_review_document
  end
end
