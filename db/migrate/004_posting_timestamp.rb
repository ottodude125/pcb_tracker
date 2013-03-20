class PostingTimestamp < ActiveRecord::Migration


  def self.up

    #
    # posting_timestamps
    #
    create_table :posting_timestamps , { :id => false } do |t|
      t.integer     :design_review_id
      t.timestamp   :posted_at
    end

  end



  def self.down
    drop_table :posting_timestamps
  end


end
