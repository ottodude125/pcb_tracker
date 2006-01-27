require File.dirname(__FILE__) + '/../test_helper'

class RoleTest < Test::Unit::TestCase

  fixtures(:review_types_roles,
           :roles)

  def setup
    @role = Role.find(roles(:admin).id)
  end

  def test_create

    assert_kind_of Role,  @role

    admin = roles(:admin)
    assert_equal(admin.id,     @role.id)
    assert_equal(admin.name,   @role.name)
    assert_equal(admin.active, @role.active)

  end

  def test_update
    
    @role.name   = "Administrator"
    @role.active = 0

    assert @role.save
    @role.reload

    assert_equal("Administrator", @role.name)
    assert_equal(0,               @role.active)

  end

  def test_destroy
    @role.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Role.find(@role.id) }
  end

end
