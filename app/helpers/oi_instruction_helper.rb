########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: oi_instruction_helper.rb
#
# This contains the helper methods for outsource instruction views.
#
# $Id$
#
########################################################################
#
module OiInstructionHelper

 
  ######################################################################
  #
  # fmt_team_members
  #
  # Description:
  # Displays a list of team members available for assignments.
  # 
  # team_members - The team members available for work assignments 
  # selections   - Used to determine whether or not the check box 
  #                should be checked.
  # label        - The text string at the top of the table.
  #
  ######################################################################
  #
  def fmt_team_members(team_members, selections, label)
  
    table  = "\n<table width='100%' border='0'>\n"
    table += "<tr><th colspan='6'>" + label + "</th></tr>\n"
    
    count = 0
    team_members.each do |tm|
      table += "<tr>" if count == 0
      table += "\n<td width='25'>"
      if (selections && selections[tm.id.to_s] == '1')
        table += check_box("team_member_#{tm.id}", "selected", { 'checked' => 'checked' })
      else
        table += check_box("team_member", tm.id.to_s)
      end
      table += "</td>"
      table += '<td width="200">' + tm.name + '</td>'
      
      count += 1
      if count == 3
        table += "</tr>\n"
        count = 0
      end
    end
    table += '</tr>' if count != 0
    
    table += '</table>'
  end
  
  
  ######################################################################
  #
  # section_assigned?
  #
  # Description:
  # Indicates that an assignment was made from one of the instructions.
  # 
  # Return Value:
  # When at least one of the sections is assigned TRUE, otherwise FALSE.
  #
  ######################################################################
  #
  def section_assigned?(oi_instructions, section_id)
    oi_instructions.detect { |i| i.oi_category_section_id == section_id }
  end
  
  
  def assignment_by_category(oi_instructions, category_id)

    assignments = oi_instructions.collect { |i| i if i.oi_category_section.oi_category_id == category_id }
    assignments.delete_if { |a| a == nil }

    count = 0
    assignments.each { |inst| count += inst.oi_assignments.size }
    count

  end
  
  
  def assignment_data(oi_instructions)
  
    assignments = {}
    OiCategory.find(:all).each { |c| assignments[c.id] = { :assigned => 0, :cancelled => 0, :completed => 0 } }
    
    oi_instructions.each do |i|
      completed_list = i.oi_assignments.dup
      completed_list.delete_if { |cl| !cl.complete? }
      
      reports = 0
      i.oi_assignments.each { |a| reports += 1 if a.oi_assignment_report }

      assignments[i.oi_category_section.oi_category_id][:assigned]  += i.oi_assignments.size
      assignments[i.oi_category_section.oi_category_id][:completed] += completed_list.size
      if !assignments[i.oi_category_section.oi_category_id][:reports]
        assignments[i.oi_category_section.oi_category_id][:reports] = 0
      end
      assignments[i.oi_category_section.oi_category_id][:reports]   += reports
    end

    return assignments
    
  end
  
  
  def complete_count(assignment_list)
    count = 0
    assignment_list.each { |a| count += 1 if a.complete? }
    
    count
  end
  
  
  def start_td(line)
    if line.modulo(2).nonzero?
      '<td class="dk_gray">'
    else
      '<td class="lt_gray">'
    end
  end
  

end
