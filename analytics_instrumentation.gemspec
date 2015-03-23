$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "analytics_instrumentation/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "analytics_instrumentation"
  s.version     = Analytics::VERSION
  s.authors     = ["Jordan Feldstein", "Michael Feldstein"]
  s.email       = ["jfeldstein@gmail.com", "michael@canopy.co"]
  s.homepage    = "TODO"
  s.summary     = "Single-file analytics instrumentation for Rails."
  s.description = "Add analytics to any app, quickly, robustly, and accurately. \n\nDefine events and their properties in a single, simple .yml file.\n\nPlus: Get valuable campaign attribution, and best-practices learned across dozens of projects, to streamline the collection of clean, usable, reliable product and user data."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.0"

  s.add_development_dependency "sqlite3"
end
