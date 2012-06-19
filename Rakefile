require 'bundler'
Bundler::GemHelper.install_tasks
require 'rspec/core/rake_task'
require 'rcov/rcovtask'
require 'yard'

desc "Default Task (specs)"
task :default => [ :spec ]

RSpec::Core::RakeTask.new

Rcov::RcovTask.new do |t|
  t.rcov_opts = %w{--exclude=gems\/,spec\/}
  t.pattern = "spec/*_spec.rb"
  t.rcov_opts << "--text-report"
  t.verbose = true
end

YARD::Rake::YardocTask.new do |t|
  t.options << "--files" << "README.md"
end
