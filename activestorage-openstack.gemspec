$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "active_storage/openstack/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = "activestorage-openstack"
  s.version     = ActiveStorage::Openstack::VERSION
  s.author     = ["Chedli Bourguiba"]
  s.email       = ["bourguiba.chedli@gmail.com"]
  s.homepage    = "https://github.com/chaadow/activestorage-openstack"
  s.summary     = "ActiveStorage wrapper for OpenStack Storage"
  s.description = "Wraps the OpenStack Swift/Storage service as an Active Storage service"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

 s.add_dependency "fog-openstack", '~> 0.1.27'
 s.add_dependency "mime-types"
 s.add_dependency "marcel"


  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rails", "~> 5.2.0"
end
