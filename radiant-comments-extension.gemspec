require File.expand_path("../lib/radiant-comments-extension/version", __FILE__)

Gem::Specification.new do |s|
  s.name = %q{radiant-comments-extension}
  s.version = RadiantCommentsExtension::VERSION
  s.platform = Gem::Platform::RUBY

  s.required_rubygems_version = ">= 1.3.6"
  s.authors = ["Jim Gay", "Ryan Heneise", "Sean Cribbs", "John Muhl", "Sven Schwyn", "Gerrit Kaiser", "Stephen Lombardo", "Benny Degezelle", "Frank Louwers", "Michael Hale", "Nathaniel Talbott", "John Croisant", "Jon Leighton", "Witter Cheng", "Keith Bingman"]
  s.date = %q{2010-10-11}
  s.summary = %q{Comments Extension for Radiant CMS}
  s.description = %q{Adds blog-like comment functionality to Radiant.}
  s.email = %q{jim@saturnflyer.com}
  s.extra_rdoc_files = [
    "README.rdoc",
     "TODO"
  ]
  s.files = `git ls-files`.split("\n")
  s.homepage = %q{http://github.com/saturnflyer/radiant-comments-extension}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.test_files = `git ls-files spec test`.split("\n")

  s.add_dependency "fastercsv", "~> 1.5.4"
  s.add_dependency "mollom",    "~> 0.2.3"
  s.add_dependency "sanitize",  "~> 2.0.3"
end

