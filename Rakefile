require 'rspec/core/rake_task'
require 'rdoc/task'

desc "Default Task (specs)"
task :default => [ :spec ]

RSpec::Core::RakeTask.new

Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "Redis Bank"
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
}
