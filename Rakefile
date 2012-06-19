require 'bundler'
Bundler::GemHelper.install_tasks
require 'rspec/core/rake_task'
require 'yard'

desc "Default Task (specs)"
task :default => [ :spec ]

RSpec::Core::RakeTask.new

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.rcov_opts = %w{--exclude=gems\/,spec\/}
    t.pattern = "spec/*_spec.rb"
    t.rcov_opts << "--text-report"
    t.verbose = true
  end
rescue LoadError => e
  puts "Can't load rcov, is it installed?" unless RUBY_VERSION > "1.9"
end

YARD::Rake::YardocTask.new do |t|
  t.options << "--files" << "README.md"
end
