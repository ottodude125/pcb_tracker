class CreateFabIssues < ActiveRecord::Migration
  def change
    create_table :fab_issues do |t|

      t.date :received_on    
      t.string :description
      t.string :cause
      t.string :resolution
      t.boolean :resolved
      t.date :resolved_on

      t.boolean :documentation_issue,       :default => false      
      t.date :clean_up_complete_on
      
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
