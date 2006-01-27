require File.dirname(__FILE__) + '/../test_helper'
require 'review_reassignment'

class ReviewReassignmentTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end

  def test_reassign_to_peer
    return
    @expected.subject = 'ReviewReassignment#reassign_to_peer'
    @expected.body    = read_fixture('reassign_to_peer')
    @expected.date    = Time.now

    assert_equal @expected.encoded, ReviewReassignment.create_reassign_to_peer(@expected.date).encoded
  end

  def test_reassign_from_peer
    return
    @expected.subject = 'ReviewReassignment#reassign_from_peer'
    @expected.body    = read_fixture('reassign_from_peer')
    @expected.date    = Time.now

    assert_equal @expected.encoded, ReviewReassignment.create_reassign_from_peer(@expected.date).encoded
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/review_reassignment/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
