require File.dirname(__FILE__) + '/../test_helper'
require 'ping_mailer'

class PingMailerTest < Test::Unit::TestCase
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

  def test_summary
    @expected.subject = 'PingMailer#summary'
    @expected.body    = read_fixture('summary')
    @expected.date    = Time.now

    assert_equal @expected.encoded, PingMailer.create_summary(@expected.date).encoded
  end

  def test_ping
    @expected.subject = 'PingMailer#ping'
    @expected.body    = read_fixture('ping')
    @expected.date    = Time.now

    assert_equal @expected.encoded, PingMailer.create_ping(@expected.date).encoded
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/ping_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
