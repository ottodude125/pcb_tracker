require File.expand_path( "../../test_helper", __FILE__ ) 

class IncomingDirectorysTest < ActiveSupport::TestCase

  def setup
    @incoming_directory = IncomingDirectory.find(incoming_directories(:board_ah_incoming).id)
  end

  def test_create

    assert_kind_of IncomingDirectory, @incoming_directory

    catalyst = incoming_directories(:board_ah_incoming)
    assert_equal(catalyst.id,     @incoming_directory.id)
    assert_equal(catalyst.name,   @incoming_directory.name) 
    assert_equal(catalyst.active, @incoming_directory.active)

  end

  def test_update

    @incoming_directory.name   = "Central Park"
    @incoming_directory.active = 0

    assert @incoming_directory.save
    @incoming_directory.reload

    assert_equal("Central Park", @incoming_directory.name)
    assert_equal(0,              @incoming_directory.active)

  end

  def test_destroy
    @incoming_directory.destroy
    assert_raise(ActiveRecord::RecordNotFound) { IncomingDirectory.find(@incoming_directory.id) }
  end


  def test_get_active
    
    active_incoming_directories = IncomingDirectory.get_active_incoming_directories
    
    assert(active_incoming_directories.size > 1)
    assert(active_incoming_directories.size < IncomingDirectory.count)
    
    name = ''
    active_incoming_directories.each do |incoming_directory|
      assert(name < incoming_directory.name)
      name = incoming_directory.name
    end
    
  end


end
