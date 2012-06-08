require 'rspec/core/rake_task'
require 'rdoc/task'
require 'rubygems/package_task'
require 'fileutils'

gemspec = eval(File.read("#{File.dirname(__FILE__)}/redis-bank.gemspec"))
Gem::PackageTask.new(gemspec) do |pkg|
  pkg.gem_spec = gemspec
  pkg.need_zip = true
  pkg.need_tar = true
end

desc "Default Task (specs)"
task :default => [ :spec ]

RSpec::Core::RakeTask.new

task :install => [:package] do
  `gem install pkg/#{gemspec.name}-#{gemspec.version}.gem`
end

Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "Redis Bank"
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
}
