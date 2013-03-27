require File.expand_path( "../../test_helper", __FILE__ )

class DesignReviewMailerTest < ActionMailer::TestCase

  setup do
     @design_review = design_reviews(:mx234a_pre_artwork)
     @comment = design_review_comments(:comment_one)
  end

  test "posting" do
    mail = DesignReviewMailer.design_review_posting_notification(
           @design_review, @comment)
    assert_match( /The Pre-Artwork design review has been posted/, mail.subject )
    assert_equal 14, mail.to.size
    assert_equal Pcbtr::SENDER, mail[:from].value
    assert_match( /posted the Pre-Artwork review/, mail.body.encoded )
  end

  test "update" do
    mail = DesignReviewerMailer.design_review_update(
      user,@design_review,comment)
    assert_equal "Update", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal Pcbtr::SENDER, mail[:from].value
    assert_match "Hi", mail.body.encoded
  end


  test "complete" do
    mail = DesignReviewMailer.design_review_complete_notification(@design_review)
    assert_match( /design review is complete/, mail.subject )
    assert_equal 14, mail.to.size
    assert_equal Pcbtr::SENDER, mail[:from].value
    assert_match( /design review is complete/, mail.body.encoded )
  end

  test "reassign_to_peer" do
    mail = DesignReviewMailer.reassign_to_peer
    assert_equal "Reassign to peer", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "reassign_from_peer" do
    mail = DesignReviewMailer.reassign_from_peer
    assert_equal "Reassign from peer", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "skipped" do
    mail = DesignReviewMailer.skipped
    assert_equal "Skipped", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
