class WidenNumberOfCompletedChecks < ActiveRecord::Migration
  def up
    change_column(:audits, :designer_completed_checks, :integer, :limit => 2 )
    change_column(:audits, :auditor_completed_checks,  :integer, :limit => 2 )
  end

  def down
    change_column(:audits, :auditor_complete,          :integer, :limit => 1 )
    #the prior line fixes a typo that confused the system
    change_column(:audits, :designer_completed_checks, :integer, :limit => 1 )
    change_column(:audits, :auditor_completed_checks,  :integer, :limit => 1 )
  end
end
