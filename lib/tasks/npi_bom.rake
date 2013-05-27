#rake tasks for npi BOM loaser

namespace :npi_bom do

  desc "Get design data for web pages"
  task :get_design_data => :environment do
    Design.bom_upload_data 
  end
  
end
  
