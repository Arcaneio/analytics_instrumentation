require 'rubygems'
require 'rake'
require 'rake/testtask'
$:.push File.expand_path("../lib", __FILE__)
require "analytics_instrumentation"

# Rake::TestTask.new(:test) do |test|
#   test.libs << 'lib' << 'test'
#   test.pattern = 'test/{functional,unit}/**/*_test.rb'
# end

# namespace :test do
#   Rake::TestTask.new(:lint) do |test|
#     test.libs << 'lib' << 'test'
#     test.pattern = 'test/test_active_model_lint.rb'
#   end

#   task :all => ['test', 'test:lint']
# end

# task :default => 'test:all'

desc 'Builds the gem'
task :build do
  sh "gem build analytics_instrumentation.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  sh "gem install analytics_instrumentation-#{AnalyticsInstrumentation::VERSION}"
end

desc 'Tags version, pushes to remote, and pushes gem'
task :release => :build do
  sh "git tag v#{AnalyticsInstrumentation::VERSION}"
  sh "git push origin master"
  sh "git push origin v#{AnalyticsInstrumentation::VERSION}"
  sh "gem push analytics_instrumentation-#{AnalyticsInstrumentation::VERSION}.gem"
  sh "rm analytics_instrumentation-#{AnalyticsInstrumentation::VERSION}.gem"
end
