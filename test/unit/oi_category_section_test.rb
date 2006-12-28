require File.dirname(__FILE__) + '/../test_helper'

class OiCategorySectionTest < Test::Unit::TestCase
  fixtures :oi_category_sections

  ######################################################################
  #
  # test_urls
  #
  ######################################################################
  #
  def test_urls
  
    board_prep_1 = oi_category_sections(:board_prep_1)
    url_info     = board_prep_1.urls.pop
    
    assert_equal(1,                         board_prep_1.urls.size)
    assert_equal('http://www.teradyne.com', url_info[:url])
    assert_equal('Reference',               url_info[:text])
    
    
    placement_6 = oi_category_sections(:placement_6)
    url_info    = placement_6.urls.pop
    
    assert_equal(1,                       placement_6.urls.size)
    assert_equal('http://www.google.com', url_info[:url])
    assert_equal('Examples',              url_info[:text])


    placement_5 = oi_category_sections(:placement_5)
    assert_equal(0, placement_5.urls.size)
     
  end


  ######################################################################
  #
  # test_email_urls
  #
  ######################################################################
  #
  def test_email_urls
  
    board_prep_1 = oi_category_sections(:board_prep_1)
    expected_url_str = "REFERENCES: http://www.teradyne.com" + 
                       "\n--------------------------------------------------------------------------------"
    assert_equal(expected_url_str, board_prep_1.email_formatted_urls)
    
    placement_6 = oi_category_sections(:placement_6)
    expected_url_str = "REFERENCES: http://www.google.com" + 
                       "\n--------------------------------------------------------------------------------"
    assert_equal(expected_url_str, placement_6.email_formatted_urls)
    
    placement_5 = oi_category_sections(:placement_5)
    assert_equal('', placement_5.email_formatted_urls)
     
  end
  
  
end
