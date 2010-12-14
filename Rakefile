require "rake"
require "rake/testtask"
require "rake/rdoctask"
require "jeweler"


desc "Default: run tests."
task :default => [:test]


desc "Test the gem."
Rake::TestTask.new(:test) do |t|
  t.libs    << ["lib", "test"]
  t.pattern  = "test/**/*_test.rb"
  t.verbose  = true
end


desc 'Generate documentation for the gem.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title    = "acts_as_list_with_sti_support"
  rdoc.options << "--line-numbers --inline-source"
  rdoc.rdoc_files.include("README")
  rdoc.rdoc_files.include("lib/**/*.rb")
end


begin
  Jeweler::Tasks.new do |gemspec|
    gemspec.authors           = ["Coroutine", "John Dugan"]
    gemspec.description       = "This acts_as extension does everything acts_as_list does, but it also works in single table inheritance designs and accepts less brain-damaged scope syntax."
    gemspec.email             = "gem@coroutine.com"
    gemspec.homepage          = "http://github.com/coroutine/acts_as_list_with_sti_support"
    gemspec.name              = "acts_as_list_with_sti_support"
    gemspec.summary           = "Gem version of acts_as_list_with_sti_support Rails plugin, a smarter version of acts_as_list."
    
    gemspec.add_dependency("activerecord", ">=2.3.4")
    gemspec.add_development_dependency("activesupport", ">=2.3.4")
    gemspec.files.include("lib/**/*.rb")
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end