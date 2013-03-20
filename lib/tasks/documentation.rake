Rake::Task["doc:app"].clear
Rake::Task["doc/app"].clear
Rake::Task["doc/app/index.html"].clear

namespace :doc do
    Rake::RDocTask.new('app') do |rdoc|
        rdoc.rdoc_dir = 'public/documentation'
        rdoc.title    = 'PCB_Review_Tracker'
        rdoc.main     = 'PCB_Review_Tracker_API' # define README_FOR_APP as index

        rdoc.options << '--encoding' << 'utf-8' << '--all' << '--verbose' << '--hyperlink-all'

        rdoc.rdoc_files.include('app/**/*.rb')
        rdoc.rdoc_files.include('lib/**/*.rb')
        rdoc.rdoc_files.include('doc/README_FOR_APP')

    end
end