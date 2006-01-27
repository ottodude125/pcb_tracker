require File.dirname(__FILE__) + '/../test_helper'

class DocumentTypeTest < Test::Unit::TestCase
  fixtures :document_types

  def setup
    @document_type = DocumentType.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of DocumentType,  @document_type
  end
end
