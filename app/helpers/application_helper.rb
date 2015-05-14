########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: application_helper.rb
#
# The methods added to this helper will be available to all 
# templates in the application.
#
# $Id$
#
########################################################################

module ApplicationHelper


  ######################################################################
  #
  # split_into_cols
  #
  # Description:
  # This method uses the list and column number passed in to compute 
  # the slices of the list that will be displayed into each column.
  #
  # Parameters:
  # list    - the list that will be divided into columns
  # columns - the number of columns to split the list into for display
  #
  # Returns:
  # An array of slices that define the range of the list that are
  # to be displayed in each column.
  #
  ######################################################################
  #
  def split_into_cols(list, columns)

    cols = [{:empty => true}]

    if list.size <= columns
      columns.downto(1) { |i|
        if i > list.size
	  cols[i] = {:empty => true}
	else
	  cols[i] = {:empty => false, :start => (i-1), :stop => (i-1)}
	end
      }
    else
      items_remaining = list.size
      items_per_col = items_remaining/columns

      start = 0
      1.upto(columns) { |i|

        items_per_col = items_remaining if i == columns
        
        stop = start + items_per_col - 1

        if i < (columns - 1)
          stop += 1 if list.size.remainder(columns) > 0
        end

        cols[i] = {:empty => false, :start => start, :stop => stop}
        start = stop + 1
        items_remaining -= items_per_col
      }
    end

    return cols
    
  end


  ######################################################################
  #
  # is_manager
  #
  # Description:
  # This method determines if the user is a manager.  The information
  # stored in the session data is used to make the determination.
  #
  # Parameters:
  # None
  #
  # Returns:
  # True if the user is a manager, false otherwise.
  #
  ######################################################################
  #
  def is_manager
    @logged_in_user.roles.include?(Role.find_by_name("Manager"))
  end


  ######################################################################
  #
  # is_admin
  #
  # Description:
  # This method determines if the user is a tracker admin.  The information
  # stored in the session data is used to make the determination.
  #
  # Parameters:
  # None
  #
  # Returns:
  # True if the user is a tracker admin, false otherwise.
  #
  ######################################################################
  #
  def is_admin
    @logged_in_user.roles.include?(Role.find_by_name("Admin"))
  end


  ######################################################################
  #
  # pre_artwork_complete
  #
  # Description:
  # This method determines if a design's pre-artwork design review
  # is complete.
  #
  # Parameters:
  # design - provides access to the pre-artwork design review that the
  #          caller is interested in.
  #
  # Returns:
  # True if the pre-artwork design review is complete, false otherwise.
  #
  ######################################################################
  #
  def pre_artwork_complete(design)

    pre_art_review_type = ReviewType.get_pre_artwork
    pre_art_design_review = design.design_reviews.detect { |dr| 
      dr.review_type_id == pre_art_review_type.id
    }

    done = ReviewStatus.find_by_name('Review Completed')
    done.id == pre_art_design_review.review_status_id
    
  end


  ######################################################################
  #
  # design_center_path
  #
  # Description:
  # Given a design review, creates the url to access the design.
  #
  # Parameters:
  # design_review - provides access to the design to create the url.
  #
  # Returns:
  # The url to get to the design data.
  #
  ######################################################################
  #
  def design_center_path(design_review)
    #('http://boarddev.teradyne.com' + design_review.design.surfboards_path + '/public').gsub("//","/")
    (design_review.design.surfboards_path + '/public/').gsub("//","/")

  end


  ######################################################################
  #
  # poster_name
  #
  # Description:
  # Returns the name that should be displayed in the "Poster" field.  If the
  # review is a Pre-Artwork review then the name of the person who created the 
  # design should be displayed.  Otherwise the name of the designer assigned to
  # the review should be displayed.
  #
  # Parameters:
  # design_review - provides access to the design review.
  #
  # Returns:
  # The name of the poster
  #
  ######################################################################
  #
  def poster_name(design_review)
    if design_review.review_type.name == "Pre-Artwork"
      design_review.design.input_gate.name
    else
      design_review.designer.name
    end
  end
  
  
  ######################################################################
  #
  # auditor_name
  #
  # Description:
  # Returns the name of the auditor assigned to perform the 
  # audit for the section.
  #
  # Parameters:
  # section_id    - the section record identifier
  # teammate_list - an array of user records who are audit teammates
  # lead          - the user record for the audit lead.
  #
  # Returns:
  # A string containing auditor's name.
  # 
  # TODO: This should be obsolete.  VERIFY
  #
  ######################################################################
  #
  def auditor_name(section_id, teammate_list, lead)
    teammate = teammate_list.detect { |tmate| tmate.section_id == section_id }
    if teammate
      teammate.user.name
    else
      lead.name
    end
  end
  
  
  ######################################################################
  #
  # role_links
  #
  # Description:
  # Generate the links to the action that changes the user's role.
  #
  # Parameters:
  # generate_links - A flag that indicates that the links should be
  #                  created for the view when True.
  #
  # Returns:
  # A string containing links to change the user's role.  The links
  # are encapsulated in table data elements.
  #
  ######################################################################
  #
  def role_links(generate_links=false)
    
    roles = [ { :message => :designer_role,       :name => 'Designer' },
              { :message => :fir_role,            :name => 'FIR Reviewer' },
              { :message => :reviewer_role,       :name => 'Reviewer' },
              { :message => :pcb_management_role, :name => 'PCB Management' },
              { :message => :pcb_admin_role,      :name => 'PCB Admin'},
              { :message => :tracker_admin_role,  :name => 'Tracker Admin' } ]
            
    links = []
    return links if !generate_links
    
    roles.each do |role|
      
      # Go through the roles list and determine if the user is registered
      # for the role.  If yes, then create the link to change to that role.
      new_role = @logged_in_user.send(role[:message])
      if (new_role && @logged_in_user && (@logged_in_user.active_role.id != new_role.id))
        links << '<td width="110" align="center">' + 
          link_to(role[:name], { :controller => :user,
                                 :action     => :set_role,
                                 :id         => new_role.id }) + 
          '</td>'
      end
      
      # Nil out the entries that do not have a link.
      #links = roles.collect { |role| role[:link_to] }
      #links.compact!
      
    end
    
    links
    
  end

  
  def audit_radio_button(check,
                         design_check, 
                         audit,
                         tag_value,
                         disabled)
                         
    if audit.is_self_audit?
      attribute = 'designer_result'
      checked = design_check.designer_result == tag_value ? true : nil
    else
      attribute = 'auditor_result'
      checked = design_check.auditor_result == tag_value ? true : nil
    end
    
    radio_button("check_#{check.id}",
                 attribute,
                 tag_value,
                 {:checked  => checked,
                  :disabled => disabled})
  end
  
  
  # Retrieve the stored return target
  #
  # :call-seq:
  #   url_for_stored() -> string
  #
  #  If a return target url was stored provide that url, otherwise send the
  #  tracker back to the home page
  def url_for_stored
    session[:return_to] ? url_for(session[:return_to]) : url_for( :controller => 'tracker' )
  end
  
  # Method adds the html formatting code to the description string
  def parse_post(post)
    ret = ''
    #post = post.post if post.is_a? UserPost
    #post = UserPost.find(post).post if post.is_a? Fixnum
    ret = post
    post.scan(/(<(.*?)>)/).each{|s| ret.sub!(s[0], '['+s[1]+']')} #removes html tags
    post.scan(/(\[(.*?)\]\((.*?)\))/).each do |arr| #urls
      orig = arr[0]
      text = arr[2]
      url = arr[1]
      new_url = /^http/.match(url) ? url : "http://#{url}"
      ret.gsub!(orig, '<a href='+new_url+'>'+text+'</a>')
    end
    post.scan(/(\*\*(.*?)\*\*)/).each do |arr| #bold
      orig = arr[0]
      text = arr[1]
      ret.gsub!(orig, '<b>'+text+'</b>')
    end
    post.scan(/(_(.*?)_)/).each do |arr| #italics
      orig = arr[0]
      text = arr[1]
      ret.gsub!(orig, '<i>'+text+'</i>')
    end
    post.scan(/(\{\{(.*?)\|(.*?)\|(.*?)\}\})/).each do |arr| #color
      orig = arr[0]
      command = arr[1]
      color = arr[2]
      text = arr[3]
      ret.gsub!(orig, "<span style='color:" + color + ";'>" + text + '</span>')
    end
    return ret.html_safe
  end

end
