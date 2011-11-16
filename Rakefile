require 'bundler'
Bundler::GemHelper.install_tasks

require "rake"
require "rake/testtask"


desc "Default: run tests."
task :default => [:test]


desc "Test the gem."
Rake::TestTask.new(:test) do |t|
  t.libs    << ["lib", "test"]
  t.pattern  = "test/**/*_test.rb"
  t.verbose  = true
end