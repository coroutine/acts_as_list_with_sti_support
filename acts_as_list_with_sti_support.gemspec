# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{acts_as_list_with_sti_support}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Coroutine", "John Dugan"]
  s.date = %q{2010-03-10}
  s.description = %q{This acts_as extension provides the capabilities for sorting and reordering a number of objects in a list. The class that has this specified needs to have a position column defined as an integer on the mapped database table.}
  s.email = %q{jdugan@coroutine.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "MIT-LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "init.rb",
     "test/test_helper.rb"
  ]
  s.homepage = %q{http://github.com/coroutine/acts_as_label_with_sti_support}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Gem version of acts_as_list_with_sti_support Rails plugin, a smarter version of acts_as_list.}
  s.test_files = [
    "test/acts_as_list_with_sti_support_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
    else
      s.add_dependency(%q<activesupport>, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 0"])
  end
end

