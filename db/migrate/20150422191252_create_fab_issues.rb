class CreateFabIssues < ActiveRecord::Migration
  def change
    create_table :fab_issues do |t|
      t.string :description
      t.string :cause
      t.string :resolution
      t.boolean :documentation_issue,       :default => false
      
      t.date :date_received      
      t.boolean :clean_up_reqd,             :default => false
      t.date :clean_up_complete_date
      
      t.boolean :corrected_b4_pre_prod_rel, :default => false
      t.boolean :full_rev_reqd,             :default => false
      t.boolean :bare_brd_change_reqd,      :default => false
      
      t.references :user,                   :null => false
      t.references :design,                 :null => false
      t.references :fab_deliverable,        :null => false
      t.references :fab_failure_mode
      
      t.timestamps
    end
  end
end
