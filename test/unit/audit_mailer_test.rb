require File.dirname(__FILE__) + '/../test_helper'
require 'audit_mailer'

class AuditMailerTest < Test::Unit::TestCase
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

  def test_alert_designer
    @expected.subject = 'AuditMailer#alert_designer'
    @expected.body    = read_fixture('alert_designer')
    @expected.date    = Time.now

    assert_equal @expected.encoded, AuditMailer.create_alert_designer(@expected.date).encoded
  end

  def test_alert_peer
    @expected.subject = 'AuditMailer#alert_peer'
    @expected.body    = read_fixture('alert_peer')
    @expected.date    = Time.now

    assert_equal @expected.encoded, AuditMailer.create_alert_peer(@expected.date).encoded
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/audit_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
