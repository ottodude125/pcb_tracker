########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: design_controller_test.rb
#
# This file contains the functional tests for the design controller
#
# $Id$
#
########################################################################
#
require File.dirname(__FILE__) + '/../test_helper'
require 'design_controller'

# Re-raise errors caught by the controller.
class DesignController; def rescue_action(e) raise e end; end

class DesignControllerTest < Test::Unit::TestCase
  def setup
    @controller = DesignController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures(:audits,
           :boards,
           :boards_fab_houses,
           :board_reviewers,
           :designs,
           :design_checks,
           :design_review_comments,
           :design_review_results,
           :design_reviews,
           :fab_houses,
           :review_statuses,
           :review_types,
           :review_types_roles,
           :revisions,
           :roles,
           :roles_users,
           :users)


  def test_pcb_mechanical_comments
    
    mx234a = designs(:mx234a)
    
    get(:pcb_mechanical_comments, :id => mx234a.id)

    assert_equal(mx234a.directory_name, assigns(:design).directory_name)
    assert_equal(0, assigns(:comments).size)
    
    # Add a comment to one of the reviews.
    pcb_mech_comment = DesignReviewComment.new( 
                         :design_review_id => design_reviews(:mx234a_pre_artwork).id,
                         :user_id          => users(:mary_t).id,
                         :comment          => "PCB Mech Comment" )
    pcb_mech_comment.save
    
    mx234a.reload
    
    get(:pcb_mechanical_comments, :id => mx234a.id)

    assert_equal(mx234a.directory_name, assigns(:design).directory_name)
    assert_equal(1, assigns(:comments).size)
    
  end
  
  
  private
  
  
  def dump_designs

    print "\n\ndump_designs\n"
    
    designs = Design.find_all
    print "There are #{designs.size} designs\n"
    
    for design in designs
    
      if design.phase_id == 0 
        phase = 'Not Set'
      elsif design.phase_id < 255
        phase = ReviewType.find(design.phase_id).name
      else
        phase = "COMPLETE"
      end
      print "#{design.name} (#{design.id})  phase: #{phase}  #{design.design_reviews.size} design reviews\n"
      for dr in design.design_reviews
        print "#{dr.id} #{dr.review_type.name} - #{dr.review_status.name}"
        print "\n"
      end
      design_review_list = design.design_reviews.sort_by { |dr| dr.review_type.sort_order }
      print "\n"
    
    end
    
    print "\n\n"

  end


end
