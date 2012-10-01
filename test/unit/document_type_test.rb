require File.expand_path( "../../test_helper", __FILE__ ) 

class DocumentTypesTest < ActiveSupport::TestCase

  def setup
    @doc_one         = document_types(:doc_one)
    @eng_inst        = document_types(:eng_inst)
    @other           = document_types(:other)
    @outline_drawing = document_types(:outline_drawing)
    @stackup         = document_types(:stackup)
  end

  ##############################################################################
  def test_get_methods
    active = [ @eng_inst,   @other,    @outline_drawing,   @stackup ]
    
    active_document_types = DocumentType.get_active_document_types
    assert_equal(active, active_document_types)
    
    active_document_types.each_with_index do |dt, i|
      assert_equal(active[i].name, dt.name)
    end
    
    active << @doc_one
    all = active.sort_by { |dt| dt.name }
    
    all_document_types = DocumentType.get_document_types
      
    all_document_types.each_with_index do |dt, i|
      assert_equal(all[i].name, dt.name)
    end
    
    
  end
  
end
