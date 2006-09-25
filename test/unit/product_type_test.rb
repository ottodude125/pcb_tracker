require File.dirname(__FILE__) + '/../test_helper'

class ProductTypeTest < Test::Unit::TestCase
  fixtures :product_types

  def setup
    @product_type = ProductType.find(product_types(:p1_eng).id)
  end

  def test_create

    assert_kind_of ProductType,  @product_type

    p1_eng = product_types(:p1_eng)
    assert_equal(p1_eng.id,     @product_type.id)
    assert_equal(p1_eng.name,   @product_type.name) 
    assert_equal(p1_eng.active, @product_type.active)

  end

  def test_update

    @product_type.name   = "p21_eng"
    @product_type.active = 0

    assert @product_type.save
    @product_type.reload

    assert_equal("p21_eng", @product_type.name)
    assert_equal(0,         @product_type.active)

  end

  def test_destroy
    @product_type.destroy
    assert_raise(ActiveRecord::RecordNotFound) { ProductType.find(@product_type.id) }
  end

end
