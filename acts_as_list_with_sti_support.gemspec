# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "acts_as_list_with_sti_support/version"

Gem::Specification.new do |s|
  s.name        = "acts_as_list_with_sti_support"
  s.version     = Coroutine::ActsAsList::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Coroutine", "John Dugan"]
  s.email       = ["gems@coroutine.com"]
  s.homepage    = "http://github.com/coroutine/acts_as_list_with_sti_support"
  s.summary     = %q{This acts_as extension is just like acts_as_list, only better.}
  s.description = %q{This acts_as extension does everything acts_as_list does, but it also works in single table inheritance designs and accepts less brain-damaged scope syntax.}

  s.add_dependency "rails", ">= 3.0.0"
  
  s.add_development_dependency "rspec", ">= 2.0.0"
  
  s.rubyforge_project = "acts_as_list_with_sti_support"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end