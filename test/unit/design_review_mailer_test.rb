require File.dirname(__FILE__) + '/../test_helper'
require 'design_review_mailer'

class DesignReviewMailerTest < Test::Unit::TestCase
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

  def test_update
    return
    @expected.subject = 'DesignReviewMailer#update'
    @expected.body    = read_fixture('update')
    @expected.date    = Time.now

    assert_equal @expected.encoded, DesignReviewMailer.create_update(@expected.date).encoded
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/design_review_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
