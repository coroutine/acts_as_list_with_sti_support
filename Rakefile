require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'jeweler'


desc 'Default: run tests.'
task :default => [:test]


desc 'Test the plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end


desc 'Generate documentation for the plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'acts_as_list_with_sti_support'
  rdoc.options << '--line-numbers --inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


begin
  Jeweler::Tasks.new do |gemspec|
    gemspec.name              = "acts_as_list_with_sti_support"
    gemspec.summary           = "Gem version of acts_as_list_with_sti_support Rails plugin, a smarter version of acts_as_list."
    gemspec.description       = "This acts_as extension provides the capabilities for sorting and reordering a number of objects in a list. The class that has this specified needs to have a position column defined as an integer on the mapped database table."
    gemspec.email             = "jdugan@coroutine.com"
    gemspec.homepage          = "http://github.com/coroutine/acts_as_label_with_sti_support"
    gemspec.authors           = ["Coroutine", "John Dugan"]
    gemspec.add_dependency "activesupport"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end