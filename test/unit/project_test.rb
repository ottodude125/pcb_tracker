require File.dirname(__FILE__) + '/../test_helper'

class ProjectTest < Test::Unit::TestCase
  fixtures :projects

  def setup
    @project = Project.find(projects(:bbac).id)
  end

  def test_create

    assert_kind_of Project,  @project

    bbac = projects(:bbac)
    assert_equal(bbac.id,     @project.id)
    assert_equal(bbac.name,   @project.name)
    assert_equal(bbac.active, @project.active)
 
  end

  def test_update
    
    @project.name   = "Zinc"
    @project.active = 0

    assert @project.save
    @project.reload

    assert_equal("Zinc", @project.name)
    assert_equal(0,      @project.active)

  end

  def test_destroy
    @project.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Project.find(@project.id) }
  end
end
