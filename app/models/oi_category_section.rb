########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: oi_category_section.rb
#
# This file maintains the state for oi_category_sections.
#
# $Id$
#
########################################################################

class OiCategorySection < ActiveRecord::Base

  belongs_to :oi_category
  
  has_many   :oi_instructions
  
  
  ##############################################################################
  #
  # Instance Methods
  # 
  ##############################################################################

  
  ######################################################################
  #
  # urls
  #
  # Description:
  # This method returns the urls associated with the category section.
  #
  # Parameters:
  # None
  #
  # Return value:
  # An array of hashes containing the associated text and urls
  #
  ######################################################################
  #
  def urls
  
    # Go through the 3 urls in the record and retrieve the urls and associated 
    # text for the caller
    references = []
    1.upto(3) do |i|
    
      url = self.send("url#{i}")
      break if url == ''
      
      url_text = self.send("url#{i}_name")
      url_text = 'Reference' if url_text == ''
      references.push({ :text => url_text, :url => url })
    
    end
  
    references
  
  end
  

  ######################################################################
  #
  # email_formatted_urls
  #
  # Description:
  # This method returns the urls associated with the category section
  # suitable for putting in an email.
  #
  # Parameters:
  # None
  #
  # Return value:
  # The category sections urls formatted for inclusion in an email.
  #
  ######################################################################
  #
  def email_formatted_urls
  
    # Go through the 3 urls in the record and retrieve the urls for the 
    # caller
    urls = []
    1.upto(3) do |i|
      url = self.send("url#{i}")
      break if url == ''
      urls << url
    end
    
    url_string = ''
    if urls.size > 0
      url_string  = 'REFERENCES: '
      url_string += urls.join("\n            ")
      url_string += "\n--------------------------------------------------------------------------------"
    end
    
    return url_string
    
  end

end
