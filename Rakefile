require 'bundler'
Bundler::GemHelper.install_tasks
require 'rspec/core/rake_task'
require 'rdoc/task'
require 'rcov/rcovtask'

desc "Default Task (specs)"
task :default => [ :spec ]

RSpec::Core::RakeTask.new

Rcov::RcovTask.new do |t|
  t.rcov_opts = %w{--exclude=gems\/,spec\/}
  t.pattern = "spec/*_spec.rb"
  t.rcov_opts << "--text-report"
  t.verbose = true
end

Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "Redis Bank"
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
}
