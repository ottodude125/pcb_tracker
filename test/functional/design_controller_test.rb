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
           :design_review_results,
           :design_reviews,
           :fab_houses,
           :review_status,
           :review_types,
           :review_types_roles,
           :revisions,
           :roles,
           :roles_users,
           :users)


  def test_default

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
