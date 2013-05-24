#rake tasks for cron jobs

namespace :cron do

  desc "Check design locations"
  task :check_design_locations => :environment do
    Ping.check_design_centers
  end
  
  desc "Ping reviewers with pending reviews"
  task :ping_reviewers => :environment do
    Ping.send_message
  end
  
  desc "Clean stale sessions"
  task :clean_stale_sessions => :environment do
    SessionCleaner.remove_stale_sessions(200)
  end
  
end
  